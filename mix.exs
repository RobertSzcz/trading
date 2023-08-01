defmodule Trading.MixProject do
  use Mix.Project

  def project do
    [
      app: :trading,
      version: "0.0.1",
      escript: escript()
    ]
  end

  def escript do
    [main_module: Trading.CLI]
  end
end
