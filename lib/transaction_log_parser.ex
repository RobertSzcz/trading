defmodule Trading.TransactionLogParser do
  def parse_line(date, transaction_type, price, quantity) do
    with {:ok, date} <- parse_date(date),
         {:ok, transaction_type} <- parse_transaction_type(transaction_type),
         {:ok, price} <- parse_price(price),
         {:ok, quantity} <- parse_quantity(quantity) do
      {:ok, date, transaction_type, price, quantity}
    end
  end

  defp parse_date(date), do: Date.from_iso8601(date)

  defp parse_transaction_type("buy"), do: {:ok, :buy}
  defp parse_transaction_type("sell"), do: {:ok, :sell}
  defp parse_transaction_type(_), do: {:error, :invalid_transaction_type}

  defp parse_price(price_string) do
    with [integer_part_string, <<decimal_part_string::binary-size(2)>>] <-
           String.split(price_string, "."),
         {integer_part, ""} <- Integer.parse(integer_part_string),
         {decimal_part, ""} <- Integer.parse(decimal_part_string) do
      {:ok, integer_part * 100 + decimal_part}
    else
      _ -> {:error, :invalid_price}
    end
  end

  defp parse_quantity(quantity_string) do
    with [integer_part_string, <<decimal_part_string::binary-size(8)>>] <-
           String.split(quantity_string, "."),
         {integer_part, ""} <- Integer.parse(integer_part_string),
         {decimal_part, ""} <- Integer.parse(decimal_part_string) do
      {:ok, integer_part * 100_000_000 + decimal_part}
    else
      _ -> {:error, :invalid_quantity}
    end
  end
end
