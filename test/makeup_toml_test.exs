defmodule MakeupTomlTest do
  use ExUnit.Case, async: true
  doctest Makeup.Lexers.TomlLexer
  import Makeup.Lexers.TomlLexer.Testing, only: [lex: 1]

  test "integers" do
    assert lex("1") == [{:number_integer, %{}, "1"}]
    assert lex("+1") == [{:number_integer, %{}, "+1"}]
    assert lex("-1") == [{:number_integer, %{}, "-1"}]
  end

  test "comment" do
    assert lex("#comment") == [{:comment, %{}, "#comment"}]
  end

  test "string" do
    assert lex("\"string\"") == [{:string_double, %{}, "\"string\""}]

    assert lex("\"string\\t\\\\\"") == [
             {:string_double, %{}, "\"string"},
             {:string_escape, %{}, "\\t"},
             {:string_escape, %{}, "\\\\"},
             {:string_double, %{}, "\""}
           ]

    assert lex("'string'") == [{:string_char, %{}, "'string'"}]
    assert lex("\"\"\"\ntext\n\"\"\"") == [{:string, %{}, "\"\"\"\ntext\n\"\"\""}]
    assert lex("'''\ntext\n'''") == [{:string_char, %{}, "'''\ntext\n'''"}]
  end
end
