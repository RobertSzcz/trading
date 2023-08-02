defmodule Trading.TransactionPolicies.Fifo do
  @moduledoc """
  state example:
  %{
    1: %{
      date: %Date{},
      lots: [
        lower index means the lot were first
        {price, quantity},
        {price, quantity},
      ]
    }
  }
  """
  @behaviour Trading.TransactionPolicies.Policy

  @impl true
  def new_state() do
    {:ok, %{}}
  end

  def summarize_state(state) do
    state
    |> Enum.sort_by(&elem(&1, 0))
    |> Enum.reject(fn {_id, %{lots: lots}} -> lots == [] end)
    |> Enum.map(fn {id, %{date: date, lots: lots}} ->
      total_quantity = lots |> Enum.map(&elem(&1, 1)) |> Enum.sum()
      total_price = Enum.reduce(lots, 0, fn {p, q}, acc -> acc + p * q end)
      avg_price = total_price / total_quantity

      # TODO: check what are the implications of doing that
      avg_price = trunc(avg_price)
      [id, date, avg_price, total_quantity]
    end)
  end

  @impl true
  def process_transaction(state, date, transaction_type, price, quantity) do
    if transaction_type == :buy do
      handle_buy(state, date, price, quantity)
    else
      handle_sell(state, quantity)
    end
  end

  defp handle_buy(state, date, price, quantity) do
    # refactor
    if state == %{} do
      {:ok, Map.put(state, 1, %{date: date, lots: [{price, quantity}]})}
    else
      id = state |> Map.keys() |> Enum.max()
      last_date = state |> Map.get(id) |> Map.get(:date)

      case Date.compare(date, last_date) do
        :gt -> {:ok, Map.put(state, id + 1, %{date: date, lots: [{price, quantity}]})}
        :eq -> {:ok, update_in(state, [id, :lots], &[{price, quantity} | &1])}
        :lt -> {:error, :transaction_out_of_order}
      end
    end
  end

  # since we track only remaining lots we can ignore date and price
  # min_index is optimization not to scan already scanned days in recursive call
  defp handle_sell(state, quantity, min_index \\ 0) do
    # refactor
    if state == %{} do
      {:error, :no_available_lots_to_sell}
    else
      max_id = state |> Map.keys() |> Enum.max()

      id_to_scan = max(min_index, 1)

      if max_id < id_to_scan do
        {:error, :no_available_lots_to_sell}
      else
        available_lots = get_in(state, [id_to_scan, :lots])

        case do_sell(available_lots, quantity) do
          {remaining_lots, 0} ->
            {:ok, put_in(state, [id_to_scan, :lots], remaining_lots)}

          {remaining_lots, quantity_left} ->
            state = put_in(state, [id_to_scan, :lots], remaining_lots)
            handle_sell(state, quantity_left, id_to_scan + 1)
        end
      end
    end
  end

  # REFACTOR
  defp do_sell([], quantity_left) when quantity_left > 0, do: {[], quantity_left}
  defp do_sell(remaining_lots, quantity_left) when quantity_left == 0, do: {remaining_lots, 0}

  defp do_sell([{lot_price, lot_quantity} | tail], quantity_left) do
    cond do
      lot_quantity - quantity_left > 0 ->
        {[{lot_price, lot_quantity - quantity_left} | tail], 0}

      lot_quantity - quantity_left == 0 ->
        {tail, 0}

      lot_quantity - quantity_left < 0 ->
        do_sell(tail, quantity_left - lot_quantity)
    end
  end
end
