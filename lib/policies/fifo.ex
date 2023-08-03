defmodule Trading.Policies.FIFO do
  @moduledoc """
  For buy transactions:
  ~D[2022-01-01], 1_000_000, 500_000_000
  ~D[2022-01-02], 2_000_000, 500_000_000
  ~D[2022-01-02], 3_000_000, 500_000_000
  example state:
    [
      {1, ~D[2022-01-01], 1_000_000, 500_000_000}
      {2, ~D[2022-01-02], 2_000_000, 500_000_000}
      {2, ~D[2022-01-02], 3_000_000, 500_000_000}
    ]
  This way lots are sorted in sell order

  I was considering using map structered:
  %{
    1 => {~D[2022-01-01], [{1_000_000, 500_000_000}]}
    2 => {~D[2022-01-02], [{3_000_000, 500_000_000}, {2_000_000, 500_000_000}]}
  }
  But that would add more complexitity for questionable performance gain.
  """
  def new_state() do
    {:ok, []}
  end

  def summarize_state(state) do
    Trading.Policies.Shared.summarize_lots(state)
  end

  def process_transaction(state, date, :buy, price, quantity),
    do: handle_buy(state, date, price, quantity)

  def process_transaction(state, _date, :sell, _price, quantity), do: handle_sell(state, quantity)

  defp handle_buy([], date, price, quantity), do: {:ok, [{1, date, price, quantity}]}

  defp handle_buy(state, date, price, quantity) do
    # Both reading and adding have O(n) local time complexity here
    {last_id, last_date, _last_price, _last_quantity} = Enum.at(state, -1)

    # :lt cannot happens since transaction are ordered
    case Date.compare(date, last_date) do
      :gt -> {:ok, state ++ [{last_id + 1, date, price, quantity}]}
      :eq -> {:ok, state ++ [{last_id, date, price, quantity}]}
    end
  end

  # since we track only remaining lots we can ignore date and price
  defp handle_sell(state, quantity) do
    case Trading.Policies.Shared.sell(state, quantity) do
      {remaining_lots, 0} ->
        {:ok, remaining_lots}

      {_, _} ->
        {:error, :no_available_lots_to_sell}
    end
  end
end
