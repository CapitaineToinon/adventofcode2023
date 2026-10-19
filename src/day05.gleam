import gleam/int
import gleam/list
import gleam/result
import gleam/string

fn parse_input(input) -> Result(Nil, String) {
  let sections =
    input
    |> string.trim
    |> string.split("\n\n")

  use #(head, tail) <- result.try(
    sections
    |> pop
    |> result.replace_error("invalid input"),
  )

  use seeds <- result.try(head |> parse_seeds)

  echo seeds
  todo
}

fn pop(list: List(a)) -> Result(#(a, List(a)), Nil) {
  case list {
    [a, ..rest] -> Ok(#(a, rest))
    _ -> Error(Nil)
  }
}

fn parse_seeds(input: String) -> Result(List(Int), String) {
  input
  |> string.trim
  |> string.remove_prefix("seeds: ")
  |> string.split(" ")
  |> list.map(int.parse)
  |> result.all
  |> result.replace_error("failed to parse seed")
}

pub fn main(input: String) -> Result(Nil, String) {
  input
  |> parse_input

  Ok(Nil)
}
