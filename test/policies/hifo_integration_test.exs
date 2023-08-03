defmodule Trading.Policies.HIFOIntegrationTest do
  use ExUnit.Case

  @subject Trading.Policies.HIFO

  # Since its recruitment task I am adding test cases that were in task description
  describe "behavioural tests from business usecases" do
    test "buy and sell in different days" do
      transaction1 = [Date.from_iso8601!("2021-01-01"), :buy, 1_000_000, 100_000_000]
      transaction2 = [Date.from_iso8601!("2021-01-02"), :buy, 2_000_000, 100_000_000]
      transaction3 = [Date.from_iso8601!("2021-02-01"), :sell, 2_000_000, 150_000_000]

      {:ok, state} = @subject.new_state()
      {:ok, state} = run_transaction(state, transaction1)
      {:ok, state} = run_transaction(state, transaction2)
      {:ok, state} = run_transaction(state, transaction3)

      expected_state = %Trading.Policies.HIFO{
        current_id: 2,
        current_date: Date.from_iso8601!("2021-01-02"),
        lots: [{1, Date.from_iso8601!("2021-01-01"), 1_000_000, 50_000_000}]
      }

      assert state == expected_state
    end
  end

  test "should not allow to sell lots that were not bought" do
    transaction1 = [Date.from_iso8601!("2021-01-01"), :buy, 1_000_000, 50_000_000]
    transaction2 = [Date.from_iso8601!("2021-01-01"), :sell, 1_000_000, 100_000_000]

    {:ok, state} = @subject.new_state()
    {:ok, state} = run_transaction(state, transaction1)

    assert {:error, :no_available_lots_to_sell} = run_transaction(state, transaction2)
  end

  test "should not allow sell as first transaction" do
    transaction = [Date.from_iso8601!("2021-01-01"), :sell, 1_000_000, 50_000_000]

    {:ok, state} = @subject.new_state()

    assert {:error, :no_available_lots_to_sell} = run_transaction(state, transaction)
  end

  # I would leave that for production code
  # test "should not allow unordered buy transaction" do
  #   transaction1 = [Date.from_iso8601!("2021-01-02"), :buy, 1_000_000, 50_000_000]
  #   transaction2 = [Date.from_iso8601!("2021-01-01"), :buy, 1_000_000, 50_000_000]

  #   {:ok, state} = @subject.new_state()
  #   {:ok, state} = run_transaction(state, transaction1)

  #   assert {:error, :transaction_out_of_order} = run_transaction(state, transaction2)
  # end

  # test "should not allow unordered sell transaction" do
  #   transaction1 = [Date.from_iso8601!("2021-01-02"), :buy, 1_000_000, 50_000_000]
  #   transaction2 = [Date.from_iso8601!("2021-01-01"), :sell, 1_000_000, 50_000_000]

  #   {:ok, state} = @subject.new_state()
  #   {:ok, state} = run_transaction(state, transaction1)

  #   assert {:error, :transaction_out_of_order} = run_transaction(state, transaction2)
  # end

  test "should keep fifo ordering when lots have same price" do
    transaction1 = [Date.from_iso8601!("2021-01-01"), :buy, 1_000_000, 50_000_000]
    transaction2 = [Date.from_iso8601!("2021-01-02"), :buy, 1_000_000, 50_000_000]
    transaction3 = [Date.from_iso8601!("2021-01-03"), :sell, 1_000_000, 75_000_000]

    {:ok, state} = @subject.new_state()
    {:ok, state} = run_transaction(state, transaction1)
    {:ok, state} = run_transaction(state, transaction2)
    {:ok, state} = run_transaction(state, transaction3)

    expected_state = %Trading.Policies.HIFO{
      current_id: 2,
      current_date: Date.from_iso8601!("2021-01-02"),
      lots: [{2, Date.from_iso8601!("2021-01-02"), 1_000_000, 25_000_000}]
    }

    assert state == expected_state
  end

  defp run_transaction(state, [date, operation, price, quantity]) do
    @subject.process_transaction(state, date, operation, price, quantity)
  end
end
