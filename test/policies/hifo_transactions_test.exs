defmodule Trading.Policies.HIFOTransactionsTest do
  use ExUnit.Case

  @subject Trading.Policies.HIFO

  # Since its recruitment task I am adding test cases that were in task description
  describe "behavioural tests from business usecases" do
    test "buy and sell in different days" do
      transaction1 = [~D[2021-01-01], :buy, 1_000_000, 100_000_000]
      transaction2 = [~D[2021-01-02], :buy, 2_000_000, 100_000_000]
      transaction3 = [~D[2021-02-01], :sell, 2_000_000, 150_000_000]

      {:ok, state} = @subject.new_state()
      {:ok, state} = run_transaction(state, transaction1)
      {:ok, state} = run_transaction(state, transaction2)
      {:ok, state} = run_transaction(state, transaction3)

      expected_state = %Trading.Policies.HIFO{
        current_id: 2,
        current_date: ~D[2021-01-02],
        lots: [{1, ~D[2021-01-01], 1_000_000, 50_000_000}]
      }

      assert state == expected_state
    end
  end

  test "should not allow to sell lots that were not bought" do
    transaction1 = [~D[2021-01-01], :buy, 1_000_000, 50_000_000]
    transaction2 = [~D[2021-01-01], :sell, 1_000_000, 100_000_000]

    {:ok, state} = @subject.new_state()
    {:ok, state} = run_transaction(state, transaction1)

    assert {:error, :no_available_lots_to_sell} = run_transaction(state, transaction2)
  end

  test "should not allow sell as first transaction" do
    transaction = [~D[2021-01-01], :sell, 1_000_000, 50_000_000]

    {:ok, state} = @subject.new_state()

    assert {:error, :no_available_lots_to_sell} = run_transaction(state, transaction)
  end

  # I would leave that for production code
  # test "should not allow unordered buy transaction" do
  #   transaction1 = [~D[2021-01-02], :buy, 1_000_000, 50_000_000]
  #   transaction2 = [~D[2021-01-01], :buy, 1_000_000, 50_000_000]

  #   {:ok, state} = @subject.new_state()
  #   {:ok, state} = run_transaction(state, transaction1)

  #   assert {:error, :transaction_out_of_order} = run_transaction(state, transaction2)
  # end

  # test "should not allow unordered sell transaction" do
  #   transaction1 = [~D[2021-01-02], :buy, 1_000_000, 50_000_000]
  #   transaction2 = [~D[2021-01-01], :sell, 1_000_000, 50_000_000]

  #   {:ok, state} = @subject.new_state()
  #   {:ok, state} = run_transaction(state, transaction1)

  #   assert {:error, :transaction_out_of_order} = run_transaction(state, transaction2)
  # end

  test "should keep fifo ordering when lots have same price" do
    transaction1 = [~D[2021-01-01], :buy, 1_000_000, 50_000_000]
    transaction2 = [~D[2021-01-02], :buy, 1_000_000, 50_000_000]
    transaction3 = [~D[2021-01-03], :sell, 1_000_000, 75_000_000]

    {:ok, state} = @subject.new_state()
    {:ok, state} = run_transaction(state, transaction1)
    {:ok, state} = run_transaction(state, transaction2)
    {:ok, state} = run_transaction(state, transaction3)

    expected_state = %Trading.Policies.HIFO{
      current_id: 2,
      current_date: ~D[2021-01-02],
      lots: [{2, ~D[2021-01-02], 1_000_000, 25_000_000}]
    }

    assert state == expected_state
  end

  test "sell in different days" do
    transaction1 = [~D[2021-01-01], :buy, 1_000_000, 50_000_000]
    transaction2 = [~D[2021-01-01], :buy, 2_000_000, 50_000_000]
    transaction3 = [~D[2021-01-01], :buy, 3_000_000, 50_000_000]
    transaction4 = [~D[2021-01-01], :sell, 5_000_000, 50_000_000]
    transaction5 = [~D[2021-01-02], :buy, 4_000_000, 50_000_000]
    transaction6 = [~D[2021-01-02], :buy, 5_000_000, 50_000_000]
    transaction7 = [~D[2021-01-02], :sell, 5_000_000, 50_000_000]

    {:ok, state} = @subject.new_state()
    {:ok, state} = run_transaction(state, transaction1)
    {:ok, state} = run_transaction(state, transaction2)
    {:ok, state} = run_transaction(state, transaction3)
    {:ok, state} = run_transaction(state, transaction4)
    {:ok, state} = run_transaction(state, transaction5)
    {:ok, state} = run_transaction(state, transaction6)
    {:ok, state} = run_transaction(state, transaction7)


    expected_state = %Trading.Policies.HIFO{
      current_id: 2,
      current_date: ~D[2021-01-02],
      lots: [
        {2, ~D[2021-01-02], 4_000_000, 50_000_000},
        {1, ~D[2021-01-01], 2_000_000, 50_000_000},
        {1, ~D[2021-01-01], 1_000_000, 50_000_000}

      ]
    }

    assert state == expected_state
  end

  defp run_transaction(state, [date, operation, price, quantity]) do
    @subject.process_transaction(state, date, operation, price, quantity)
  end
end
