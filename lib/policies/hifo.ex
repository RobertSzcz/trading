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

  defp handle_buy(
         %__MODULE__{current_id: nil},
         date,
         price,
         quantity
       ) do
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
        current_id = last_id + 1
        state = Map.put(state, :current_id, current_id)
        state = Map.put(state, :current_date, date)
        state = Map.update!(state, :lots, &insert_sorted(&1, {current_id, date, price, quantity}))
        {:ok, state}

      :eq ->
        state = Map.update!(state, :lots, &insert_sorted(&1, {last_id, date, price, quantity}))
        {:ok, state}
    end
  end

  defp insert_sorted(lots, lot_to_insert) do
    do_insert_sorted([], lots, lot_to_insert)
  end

  # in case of same lots from different days have same price we take the first
  defp do_insert_sorted(more_expensive_lots, [], lot_to_insert),
    do: more_expensive_lots ++ [lot_to_insert]

  defp do_insert_sorted(
         more_expensive_lots,
         [{_id, _date, price, _quantity} = h | tail],
         {_, _, lot_to_insert_price, _} = lot_to_insert
       ) do
    cond do
      price > lot_to_insert_price ->
        do_insert_sorted(more_expensive_lots ++ [h], tail, lot_to_insert)

      # If lots have same price we will sell oldest first
      price == lot_to_insert_price ->
        do_insert_sorted(more_expensive_lots ++ [h], tail, lot_to_insert)

      price < lot_to_insert_price ->
        more_expensive_lots ++ [lot_to_insert] ++ [h] ++ tail
    end
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
