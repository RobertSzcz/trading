defmodule Trading.Policies.Shared do
  def summarize_lots(lots) do
    lots
    |> Enum.group_by(&elem(&1, 0))
    |> Enum.map(fn {id, [{_id, date, _price, _quantity} | _] = lots} ->
      total_quantity = lots |> Enum.map(&elem(&1, 3)) |> Enum.sum()
      total_price = Enum.reduce(lots, 0, fn {_id, _d, p, q}, acc -> acc + p * q end)
      avg_price = total_price / total_quantity

      # Didn't have time to think if there are any implications of doing that here
      avg_price = trunc(avg_price)
      [id, date, avg_price, total_quantity]
    end)
  end

  def sell([], quantity_left) when quantity_left > 0, do: {[], quantity_left}
  def sell(remaining_lots, quantity_left) when quantity_left == 0, do: {remaining_lots, 0}

  def sell([{lot_id, lot_date, lot_price, lot_quantity} | tail], quantity_left) do
    remaining_quantity = lot_quantity - quantity_left

    cond do
      remaining_quantity > 0 ->
        {[build_lot(lot_id, lot_date, lot_price, remaining_quantity) | tail], 0}

      remaining_quantity == 0 ->
        {tail, 0}

      remaining_quantity < 0 ->
        sell(tail, quantity_left - lot_quantity)
    end
  end

  defp build_lot(id, date, price, quantity), do: {id, date, price, quantity}
end
