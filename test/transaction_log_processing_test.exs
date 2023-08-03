defmodule Trading.TransactionLogProcessingTest do
  use ExUnit.Case

  @subject Trading.TransactionLogProcessing

  describe "generate_output_line/4" do
    test "with valid data generates strings" do
      {:ok, "1", "2021-01-01", "10000.00", "1.00000000"} =
        @subject.generate_output_line(1, Date.from_iso8601!("2021-01-01"), 1_000_000, 100_000_000)

      {:ok, "1", "2021-01-01", "0.01", "0.00000001"} =
        @subject.generate_output_line(1, Date.from_iso8601!("2021-01-01"), 1, 1)
    end
  end

  describe "parse_input_line/4" do
    test "parses data to standarized format" do
      assert {:ok, Date.from_iso8601!("2021-01-01"), :buy, 1_000_000, 1_000_000_000} ==
               @subject.parse_input_line("2021-01-01", "buy", "10000.00", "10.00000000")
    end

    test "parses numbers with decimals only" do
      assert {:ok, Date.from_iso8601!("2021-01-01"), :buy, 1, 1} ==
               @subject.parse_input_line("2021-01-01", "buy", "0.01", "0.00000001")
    end

    test "returns error if date is invalid" do
      assert {:error, :invalid_date} ==
               @subject.parse_input_line("2021-13-01", "buy", "0.01", "0.00000001")

      assert {:error, :invalid_date} ==
               @subject.parse_input_line("not_date", "buy", "0.01", "0.00000001")
    end

    test "returns error if operation_type is invalid" do
      assert {:error, :invalid_transaction_type} ==
               @subject.parse_input_line("2021-11-01", "not_type", "0.01", "0.00000001")
    end

    test "returns error if price is invalid" do
      # It is required for price to have 2 decimal places
      assert {:error, :invalid_price} ==
               @subject.parse_input_line("2021-11-01", "buy", "0.1", "0.00000001")

      assert {:error, :invalid_price} ==
               @subject.parse_input_line("2021-11-01", "buy", "not_float", "0.00000001")

      assert {:error, :invalid_price} ==
               @subject.parse_input_line("2021-11-01", "buy", "10", "0.00000001")

      # Cannot be 0
      assert {:error, :invalid_price} ==
               @subject.parse_input_line("2021-11-01", "buy", "0.00", "0.00000001")
    end

    test "returns error if quantity is invalid" do
      # It is required for quantity to have 8 decimal places
      assert {:error, :invalid_quantity} ==
               @subject.parse_input_line("2021-11-01", "buy", "0.01", "0.1")

      assert {:error, :invalid_quantity} ==
               @subject.parse_input_line("2021-11-01", "buy", "0.01", "not_float")

      assert {:error, :invalid_quantity} ==
               @subject.parse_input_line("2021-11-01", "buy", "0.01", "0.00001")

      # Cannot be 0
      assert {:error, :invalid_quantity} ==
               @subject.parse_input_line("2021-11-01", "buy", "0.01", "0.00000000")
    end
  end
end
