defmodule Makeup.Lexers.TomlLexer do
  import NimbleParsec
  import Makeup.Lexer.Combinators
  import Makeup.Lexer.Groups

  @behaviour Makeup.Lexer

  any_char = utf8_char([]) |> token(:error)

  whitespace = ascii_string([?\r, ?\s, ?\n, ?\f], min: 1) |> token(:whitespace)

  newlines =
    choice([string("\r\n"), string("\n")])
    |> optional(ascii_string([?\s, ?\n, ?\f, ?\r], min: 1))
    |> token(:whitespace)

  digits = ascii_string([?0..?9], min: 1)

  integer = choice([string("-"), string("+")]) |> optional() |> concat(digits)
  number_integer = token(integer, :number_integer)

  unicode_char_in_string =
    string("\\u")
    |> ascii_string([?0..?9, ?a..?f, ?A..?F], 4)
    |> token(:string_escape)

  escaped_char =
    string("\\")
    |> utf8_string([], 1)
    |> token(:string_escape)

  combinators_inside_string = [
    unicode_char_in_string,
    escaped_char
  ]

  double_quoted_string_interpol =
    string_like("\"", "\"", combinators_inside_string, :string_double)

  single_quoted_string_interpol = string_like("'", "'", combinators_inside_string, :string_char)

  multi_line_string = string_like(~S("""), ~S("""), combinators_inside_string, :string)
  multi_line_string_literal = string_like("'''", "'''", combinators_inside_string, :string_char)

  line = repeat(lookahead_not(ascii_char([?\n])) |> utf8_string([], 1))

  key = ascii_string([?a..?z, ?A..?Z, ?0..?9, ?_, ?-], min: 1)

  # replace ascii_string with tagged variable name
  table = string("[") |> concat(key) |> concat(string("]")) |> token(:name_namespace)

  inline_comment =
    string("#")
    |> concat(line)
    |> token(:comment)

  bools =
    word_from_list(
      ["true", "false"],
      :keyword_constant
    )

  date_combinator =
    integer(4)
    |> string("-")
    |> integer(2)
    |> string("-")
    |> integer(2)

  time_combinator =
    integer(2)
    |> string(":")
    |> integer(2)
    |> string(":")
    |> integer(2)
    |> optional(string("Z"))

  date = date_combinator |> token(:name_variable)
  time = time_combinator |> token(:name_variable)

  offset_combinator =
    choice([string("+"), string("-")]) |> integer(2) |> string(":") |> integer(2)

  datetime =
    date_combinator
    |> choice([string("T"), ascii_string([?\s], 1)])
    |> concat(time_combinator)
    |> token(:number_variable)

  datetime_offset =
    date_combinator
    |> choice([string("T"), ascii_string([?\s], 1)])
    |> concat(time_combinator)
    |> concat(offset_combinator)
    |> token(:number_variable)

  root_element_combinator =
    choice([
      newlines,
      whitespace,
      # Comments
      inline_comment,
      multi_line_string,
      multi_line_string_literal,
      double_quoted_string_interpol,
      single_quoted_string_interpol,
      table,
      datetime_offset,
      datetime,
      date,
      time,
      # Floats must come before integers
      number_integer,
      bools,

      # punctuation
      # If we can't parse any of the above, we highlight the next character as an error
      # and proceed from there.
      # A lexer should always consume any string given as input.
      any_char
    ])

  # By default, don't inline the lexers.
  # Inlining them increases performance by ~20%
  # at the cost of doubling the compilation times...
  @inline false

  @doc false
  def __as_toml_language__({ttype, meta, value}) do
    {ttype, Map.put(meta, :language, :toml), value}
  end

  @impl Makeup.Lexer
  defparsec(
    :root_element,
    root_element_combinator |> map({__MODULE__, :__as_toml_language__, []}),
    inline: @inline
  )

  @impl Makeup.Lexer
  defparsec(
    :root,
    repeat(parsec(:root_element)),
    inline: @inline
  )

  # Finally, the public API for the lexer
  @impl Makeup.Lexer
  def lex(text, _opts \\ []) do
    {:ok, tokens, "", _, _, _} = root(text)
    tokens
  end
end
