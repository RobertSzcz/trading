defmodule Trading.CLI do
  def main(args) do
    [policy] = parse_args(args)
    IO.inspect(policy)
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
