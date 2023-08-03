defmodule Trading.TransactionsIntegrationTest do
  use ExUnit.Case

  @subject Trading.Transactions

  # Since its recruitment task I am adding test cases that were in task description
  describe "behavioural tests from business usecases" do
    test "simple buy and sell" do
      transaction1 = [Date.from_iso8601!("2021-01-01"), :buy, 1_000_000, 100_000_000]
      transaction2 = [Date.from_iso8601!("2021-01-01"), :sell, 2_000_000, 50_000_000]

      {:ok, state} = @subject.new_state()
      {:ok, state} = run_transaction(state, :fifo, transaction1)
      {:ok, state} = run_transaction(state, :fifo, transaction2)

      expected_state = [
        {1, Date.from_iso8601!("2021-01-01"), 1_000_000, 50_000_000}
      ]

      assert state == expected_state
    end

    test "buy and sell in different days" do
      transaction1 = [Date.from_iso8601!("2021-01-01"), :buy, 1_000_000, 100_000_000]
      transaction2 = [Date.from_iso8601!("2021-01-02"), :buy, 2_000_000, 100_000_000]
      transaction3 = [Date.from_iso8601!("2021-02-01"), :sell, 2_000_000, 150_000_000]

      {:ok, state} = @subject.new_state()
      {:ok, state} = run_transaction(state, :fifo, transaction1)
      {:ok, state} = run_transaction(state, :fifo, transaction2)
      {:ok, state} = run_transaction(state, :fifo, transaction3)

      expected_state = [
        {2, Date.from_iso8601!("2021-01-02"), 2_000_000, 50_000_000}
      ]

      assert state == expected_state
    end
  end

  test "should not allow to sell lots that were not bought" do
    transaction1 = [Date.from_iso8601!("2021-01-01"), :buy, 1_000_000, 50_000_000]
    transaction2 = [Date.from_iso8601!("2021-01-01"), :sell, 1_000_000, 100_000_000]

    {:ok, state} = @subject.new_state()
    {:ok, state} = run_transaction(state, :fifo, transaction1)

    assert {:error, :no_available_lots_to_sell} = run_transaction(state, :fifo, transaction2)
  end

  test "should not allow sell as first transaction" do
    transaction = [Date.from_iso8601!("2021-01-01"), :sell, 1_000_000, 50_000_000]

    {:ok, state} = @subject.new_state()

    assert {:error, :no_available_lots_to_sell} = run_transaction(state, :fifo, transaction)
  end

  test "should support partial lot sale from different days" do
    transaction1 = [Date.from_iso8601!("2021-01-01"), :buy, 1_000_000, 50_000_000]
    transaction2 = [Date.from_iso8601!("2021-01-01"), :buy, 2_000_000, 50_000_000]
    transaction3 = [Date.from_iso8601!("2021-01-02"), :buy, 3_000_000, 50_000_000]
    transaction4 = [Date.from_iso8601!("2021-01-03"), :buy, 4_000_000, 50_000_000]
    transaction5 = [Date.from_iso8601!("2021-01-03"), :buy, 5_000_000, 50_000_000]
    transaction6 = [Date.from_iso8601!("2021-01-04"), :sell, 5_000_000, 125_000_000]

    {:ok, state} = @subject.new_state()
    {:ok, state} = run_transaction(state, :fifo, transaction1)
    {:ok, state} = run_transaction(state, :fifo, transaction2)
    {:ok, state} = run_transaction(state, :fifo, transaction3)
    {:ok, state} = run_transaction(state, :fifo, transaction4)
    {:ok, state} = run_transaction(state, :fifo, transaction5)
    {:ok, state} = run_transaction(state, :fifo, transaction6)

    expected_state = [
      {2, Date.from_iso8601!("2021-01-02"), 3_000_000, 25_000_000},
      {3, Date.from_iso8601!("2021-01-03"), 4_000_000, 50_000_000},
      {3, Date.from_iso8601!("2021-01-03"), 5_000_000, 50_000_000}
    ]

    assert state == expected_state
  end

  defp run_transaction(state, policy, [date, operation, price, quantity]) do
    @subject.process_transaction(state, policy, date, operation, price, quantity)
  end
end
