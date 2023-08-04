defmodule Trading.Policies.HIFO do
  defstruct [:current_id, :current_date, :lots]

  @moduledoc """
  For buy transactions:
  ~D[2022-01-01], 1_000_000, 500_000_000
  ~D[2022-01-02], 2_000_000, 500_000_000
  ~D[2022-01-02], 3_000_000, 500_000_000
  example state:
    %Trading.Policies.HIFO{
      current_date: ~D[2022-01-02],
      current_id: 2,
      lots: [
        {2, ~D[2022-01-02], 3_000_000, 500_000_000},
        {1, ~D[2022-01-01], 2_000_000, 500_000_000},
        {1, ~D[2022-01-01], 1_000_000, 500_000_000}
      ]
    }
  This way lots are sorted in sell order
  """
  def new_state() do
    {:ok, %__MODULE__{current_id: nil, current_date: nil, lots: []}}
  end

  def summarize_state(%__MODULE__{lots: lots}) do
    Trading.Policies.Shared.summarize_lots(lots)
  end

  def process_transaction(state, date, :buy, price, quantity),
    do: handle_buy(state, date, price, quantity)

  def process_transaction(state, _date, :sell, _price, quantity), do: handle_sell(state, quantity)

  defp handle_buy(%__MODULE__{current_id: nil}, date, price, quantity) do
    {:ok,
     %__MODULE__{
       current_date: date,
       current_id: 1,
       lots: [{1, date, price, quantity}]
     }}
  end

  defp handle_buy(
         %__MODULE__{current_date: last_date, current_id: last_id} = state,
         date,
         price,
         quantity
       ) do
    # :lt cannot happens since transaction are ordered
    case Date.compare(date, last_date) do
      :gt ->
        state =
          state
          |> Map.put(:current_id, last_id + 1)
          |> Map.put(:current_date, date)
          |> Map.update!(:lots, &insert_sorted(&1, {last_id + 1, date, price, quantity}))

        {:ok, state}

      :eq ->
        state = Map.update!(state, :lots, &insert_sorted(&1, {last_id, date, price, quantity}))
        {:ok, state}
    end
  end

  defp insert_sorted(lots, {_, _, lot_to_insert_price, _} = lot_to_insert) do
    # If lots have same price we will sell oldest first. If we want newest we can do =<
    index = Enum.find_index(lots, fn {_, _, price, _} -> price < lot_to_insert_price end) || -1
    List.insert_at(lots, index, lot_to_insert)
  end

  # since we track only remaining lots we can ignore date and price
  defp handle_sell(%__MODULE__{lots: lots} = state, quantity) do
    case Trading.Policies.Shared.sell(lots, quantity) do
      {remaining_lots, 0} ->
        state = Map.put(state, :lots, remaining_lots)
        {:ok, state}

      {_, _} ->
        {:error, :no_available_lots_to_sell}
    end
  end
end
