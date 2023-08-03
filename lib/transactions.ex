defmodule Trading.Transactions do
  @moduledoc """
    There are 3 public functions here:
    - new_state - that generates an empty state according to policy
    - process_transaction - that processes a single buy / sell transaction
    - summarize_state - that processes the internal state into slimmer version

    I implemented it this way in order to:
    - allow better flow control from CLI module (We can easly stream transaction without loading everything to memory)
    - allow different state implementations for existing policies or for new ones
  """
  def new_state(policy),
    do: module(policy).new_state()

  def process_transaction(state, policy, date, transaction_type, price, quantity),
    do: module(policy).process_transaction(state, date, transaction_type, price, quantity)

  def summarize_state(state, policy), do: module(policy).summarize_state(state)

  defp module(:fifo), do: Trading.Policies.FIFO
  defp module(:hifo), do: Trading.Policies.HIFO
end
