defmodule Trading.CLI do
  @new_line_separators ["\r\n", "\r", "\n"]

  def main(args) do
    [policy] = parse_args(args)

    handle_transactions(%{}, policy)
  end

  defp handle_transactions(state, policy, line_number \\ 0) do
    line = IO.read(:stdio, :line)

    case line do
      :eof ->
        IO.inspect(state)

      line ->
        {:ok, date, transaction_type, price, quantity} =
          line
          |> String.replace(@new_line_separators, "")
          |> String.split(",")
          |> process_line(line_number)

        IO.inspect({:ok, date, transaction_type, price, quantity})
        state = process_transaction(state, policy, date, transaction_type, price, quantity)
        handle_transactions(state, policy, line_number + 1)
    end
  end

  defp process_transaction(state, policy, date, transaction_type, price, quantity) do
    state
  end

  defp process_line([date, transaction_type, price, quantity], line_number) do
    case Trading.TransactionLogParser.parse_line(date, transaction_type, price, quantity) do
      {:ok, date, transaction_type, price, quantity} ->
        {:ok, date, transaction_type, price, quantity}

      {:error, type} ->
        log("Error: #{type} at line #{line_number}")
        System.halt(1)
    end
  end

  defp process_line(_, line_number) do
    log("Error: line #{line_number} has invalid format")
    System.halt(1)
  end

  # No need to use Option Parser for that simple case
  defp parse_args(["fifo"]), do: [:fifo]
  defp parse_args(["hifo"]), do: [:hifo]

  defp parse_args([policy]) do
    log("Error: Unsupported policy #{policy}. Requires 'hifo' or 'fifo' policy as argument.")
    System.halt(2)
  end

  defp parse_args([]) do
    log("Error: Requires 'hifo' or 'fifo' policy as argument.")
    System.halt(2)
  end

  defp parse_args(_) do
    log(
      "Error: Script requires exactly one argument. Requires 'hifo' or 'fifo' policy as argument."
    )

    System.halt(2)
  end

  # Using IO.puts instead of Logger - not to add extra dependancy
  defp log(string) do
    IO.puts(string)
  end
end
