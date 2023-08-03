defmodule Trading.Transactions do
  def new_state() do
    {:ok, []}
  end

  @spec summarize_state(any) :: list
  def summarize_state(state) do
    state
    |> Enum.group_by(&elem(&1, 0))
    |> Enum.map(fn {id, [{date, _price, _quantity} | _] = lots} ->
      total_quantity = lots |> Enum.map(&elem(&1, 2)) |> Enum.sum()
      total_price = Enum.reduce(lots, 0, fn {_d, p, q}, acc -> acc + p * q end)
      avg_price = total_price / total_quantity

      # TODO: check if there are any implications of doing that
      avg_price = trunc(avg_price)
      [id, date, avg_price, total_quantity]
    end)
  end

  def process_transaction(state, :fifo, date, transaction_type, price, quantity) do
    if transaction_type == :buy do
      handle_buy(state, date, price, quantity) |> IO.inspect()
    else
      handle_sell(state, :fifo, quantity) |> IO.inspect()
    end
  end

  defp handle_buy([], date, price, quantity), do: {:ok, [build_lot(1, date, price, quantity)]}

  defp handle_buy(state, date, price, quantity) do
    # Both reading and adding have O(n) time complexity here
    {last_id, last_date, _last_price, _last_quantity} = Enum.at(state, -1)

    case Date.compare(date, last_date) do
      :gt -> {:ok, state ++ [build_lot(last_id + 1, date, price, quantity)]}
      :eq -> {:ok, state ++ [build_lot(last_id, date, price, quantity)]}
      :lt -> {:error, :transaction_out_of_order}
    end
  end

  # since we track only remaining lots we can ignore date and price
  defp handle_sell(state, :fifo, quantity) do
    case do_sell(state, quantity) do
      {remaining_lots, 0} ->
        {:ok, remaining_lots}

      {_, _} ->
        {:error, :no_available_lots_to_sell}
    end
  end

  defp do_sell([], quantity_left) when quantity_left > 0, do: {[], quantity_left}
  defp do_sell(remaining_lots, quantity_left) when quantity_left == 0, do: {remaining_lots, 0}

  defp do_sell([{lot_id, lot_date, lot_price, lot_quantity} | tail], quantity_left) do
    remaining_quantity = lot_quantity - quantity_left

    cond do
      remaining_quantity > 0 ->
        {[build_lot(lot_id, lot_date, lot_price, remaining_quantity) | tail], 0}

      remaining_quantity == 0 ->
        {tail, 0}

      remaining_quantity < 0 ->
        do_sell(tail, quantity_left - lot_quantity)
    end
  end

  defp build_lot(id, date, price, quantity), do: {id, date, price, quantity}
end
