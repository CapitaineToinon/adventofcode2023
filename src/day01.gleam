import gleam/bool
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result.{replace_error, try}
import gleam/string

type Digit {
  Digit(value: Int, name: String)
}

const digits: List(Digit) = [
  Digit(0, "zero"),
  Digit(1, "one"),
  Digit(2, "two"),
  Digit(3, "three"),
  Digit(4, "four"),
  Digit(5, "five"),
  Digit(6, "six"),
  Digit(7, "seven"),
  Digit(8, "eight"),
  Digit(9, "nine"),
]

fn find_left_digit(
  content: String,
  digits: List(Digit),
  match_literal: Bool,
) -> Result(Int, String) {
  use #(_, rest) <- try(
    content
    |> string.pop_grapheme
    |> replace_error("string is empty"),
  )

  case content |> get_left_digit(digits, match_literal) {
    Some(number) -> Ok(number)
    None -> rest |> find_left_digit(digits, match_literal)
  }
}

fn get_left_digit(
  content: String,
  digits: List(Digit),
  match_literal: Bool,
) -> Option(Int) {
  case digits {
    [number, ..other_numbers] -> {
      case
        content
        |> string.starts_with(number.value |> int.to_string)
        |> bool.or(
          match_literal
          |> bool.and(
            content
            |> string.starts_with(number.name),
          ),
        )
      {
        True -> Some(number.value)
        False -> content |> get_left_digit(other_numbers, match_literal)
      }
    }
    _ -> None
  }
}

fn find_right_digit(
  content: String,
  digits: List(Digit),
  match_literal: Bool,
) -> Result(Int, String) {
  let reversed_digits =
    digits
    |> list.map(fn(digit) { Digit(digit.value, digit.name |> string.reverse) })

  content
  |> string.reverse
  |> find_left_digit(reversed_digits, match_literal)
}

fn solve_line(content: String, match_literal: Bool) -> Result(Int, String) {
  use left <- try(find_left_digit(content, digits, match_literal))
  use right <- try(find_right_digit(content, digits, match_literal))

  Ok(left * 10 + right)
}

fn solve(content: List(String), match_literal: Bool) -> Result(Int, String) {
  content
  |> list.map(solve_line(_, match_literal))
  |> result.all
  |> result.map(int.sum)
}

pub fn main(input: String) -> Result(Nil, String) {
  let lines =
    input
    |> string.split("\n")

  use part_one <- try(
    lines
    |> solve(False),
  )

  use part_two <- try(
    lines
    |> solve(True),
  )

  part_one
  |> int.to_string
  |> io.println

  part_two
  |> int.to_string
  |> io.println

  Ok(Nil)
}
