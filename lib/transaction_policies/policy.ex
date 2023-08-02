defmodule Trading.TransactionPolicies.Policy do
  @type operation :: :buy | :sell
  @type state :: any()

  @callback new_state() :: {:ok, any()}
  @callback process_transaction(
              state,
              Date.t(),
              operation,
              Integer.t(),
              Integer.t()
            ) :: {:ok, state} | {:error, Atom.t()}
end
