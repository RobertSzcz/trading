defmodule Trading.Policies.SharedTest do
  use ExUnit.Case

  @subject Trading.Policies.Shared

  describe "summarize_lots/1" do
    test "aggregates ramaining lots by day" do
      lots = [
        {1, ~D[2021-01-01], 1_000_000, 50_000_000},
        {1, ~D[2021-01-01], 1_000_000, 50_000_000},
        {2, ~D[2021-01-02], 1_000_000, 50_000_000},
        {2, ~D[2021-01-02], 1_000_000, 50_000_000}
      ]

      assert [
               {1, ~D[2021-01-01], 1_000_000, 100_000_000},
               {2, ~D[2021-01-02], 1_000_000, 100_000_000}
             ] == @subject.summarize_lots(lots)
    end

    test "calculates the daily avarage price for ramaining lots" do
      lots = [
        {1, ~D[2021-01-01], 1_000_000, 50_000_000},
        {1, ~D[2021-01-01], 2_000_000, 60_000_000},
        {1, ~D[2021-01-01], 3_000_000, 70_000_000}
      ]

      # (1_000_000 * 50_000_000 + 2_000_000 * 60_000_000 + 3_000_000 * 70_000_000) / (50_000_000 + 60_000_000 + 70_000_000)
      # 2111111.111111111

      assert [{1, ~D[2021-01-01], 2_111_111, 180_000_000}] == @subject.summarize_lots(lots)
    end
  end

  describe "sell/2" do
    test "sells the first lots in list in given quantity" do
      lots = [
        {1, ~D[2021-01-01], 1_000_000, 50_000_000},
        {2, ~D[2021-01-02], 1_000_000, 50_000_000}
      ]

      assert {[{2, ~D[2021-01-02], 1_000_000, 50_000_000}], 0} = @subject.sell(lots, 50_000_000)
    end

    test "allows to partial sell from lot" do
      lots = [
        {1, ~D[2021-01-01], 1_000_000, 50_000_000},
        {2, ~D[2021-01-02], 1_000_000, 50_000_000}
      ]

      assert {[{2, ~D[2021-01-02], 1_000_000, 25_000_000}], 0} = @subject.sell(lots, 75_000_000)
    end

    test "returns count of how many lots are missing to fullfil order" do
      lots = [
        {1, ~D[2021-01-01], 1_000_000, 50_000_000},
        {2, ~D[2021-01-02], 1_000_000, 50_000_000}
      ]

      assert {[], 25_000_000} = @subject.sell(lots, 125_000_000)
      assert {[], 25_000_000} = @subject.sell([], 25_000_000)
    end
  end
end
