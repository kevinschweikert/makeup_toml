defmodule Makeup.Lexers.TomlLexer.Application do
  @moduledoc false
  use Application

  alias Makeup.Registry
  alias Makeup.Lexers.YamlLexer

  def start(_type, _args) do
    Registry.register_lexer(YamlLexer,
      options: [],
      names: ["yaml", "yml"],
      extensions: ["yaml", "yml"]
    )

    Supervisor.start_link([], strategy: :one_for_one)
  end
end
