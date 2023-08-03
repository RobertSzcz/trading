defmodule Trading.Transactions do
  def new_state(policy),
    do: module(policy).new_state()

  def process_transaction(state, policy, date, transaction_type, price, quantity),
    do: module(policy).process_transaction(state, date, transaction_type, price, quantity)

  def summarize_state(state, policy), do: module(policy).summarize_state(state)

  def module(:fifo), do: Trading.Policies.FIFO
  def module(:hifo), do: Trading.Policies.HIFO
end
