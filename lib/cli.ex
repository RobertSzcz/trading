defmodule Trading.CLI do
  @moduledoc """
  This is main CLI module.
  I am skipping integration tests of that due to limited time for task.
  In order to test that we could use mock for IO.read(:stdio, :line) function
  """
  @new_line_separators ["\r\n", "\r", "\n"]

  alias Trading.Transactions

  def main(args) do
    [transaction_policy] = parse_args(args)
    {:ok, state} = Transactions.new_state(transaction_policy)

    handle_transactions(state, transaction_policy)
  end

  defp handle_transactions(state, transaction_policy, line_number \\ 0) do
    line = IO.read(:stdio, :line)

    case line do
      :eof ->
        state
        |> Transactions.summarize_state(transaction_policy)
        |> Enum.each(fn {id, date, avg_price, total_quantity} ->
          {:ok, id, date, avg_price, total_quantity} =
            Trading.TransactionLogProcessing.generate_output_line(
              id,
              date,
              avg_price,
              total_quantity
            )

          line_string = Enum.join([id, date, avg_price, total_quantity], ",")

          log(line_string)
        end)

        System.halt(0)

      line ->
        {:ok, date, transaction_type, price, quantity} =
          line
          |> String.replace(@new_line_separators, "")
          |> String.split(",")
          |> process_line(line_number)

        state =
          process_transaction(
            state,
            transaction_policy,
            date,
            transaction_type,
            price,
            quantity,
            line_number
          )

        handle_transactions(state, transaction_policy, line_number + 1)
    end
  end

  defp process_transaction(
         state,
         transaction_policy,
         date,
         transaction_type,
         price,
         quantity,
         line_number
       ) do
    case Transactions.process_transaction(
           state,
           transaction_policy,
           date,
           transaction_type,
           price,
           quantity
         ) do
      {:ok, state} ->
        state

      {:error, type} ->
        log("Error: #{type} at line #{line_number}")
        System.halt(1)
    end
  end

  defp process_line([date, transaction_type, price, quantity], line_number) do
    case Trading.TransactionLogProcessing.parse_input_line(
           date,
           transaction_type,
           price,
           quantity
         ) do
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
