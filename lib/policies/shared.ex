defmodule Trading.Policies.Shared do
  def summarize_lots(lots) do
    lots
    |> Enum.group_by(&elem(&1, 0))
    |> Enum.map(&aggregate_lots_daily/1)
  end

  def sell([], quantity_left) when quantity_left > 0, do: {[], quantity_left}
  def sell(lots, quantity_left) when quantity_left == 0, do: {lots, 0}

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

  defp aggregate_lots_daily({id, [{_id, date, _price, _quantity} | _] = lots}) do
    total_quantity = lots |> Enum.map(&elem(&1, 3)) |> Enum.sum()
    total_price = Enum.reduce(lots, 0, fn {_id, _d, p, q}, acc -> acc + p * q end)
    avg_price = total_price / total_quantity

    # This should be decided with business if we want to round up or round down
    avg_price = trunc(avg_price)
    build_lot(id, date, avg_price, total_quantity)
  end

  defp build_lot(id, date, price, quantity), do: {id, date, price, quantity}
end
