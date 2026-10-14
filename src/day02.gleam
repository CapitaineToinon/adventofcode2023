import gleam/bool
import gleam/dict.{type Dict}
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{None, Some}
import gleam/result.{replace_error, try}
import gleam/string

type Color {
  Blue
  Red
  Green
}

type Cubes {
  Cubes(count: Int, color: Color)
}

type Game {
  Game(id: Int, reveals: List(Cubes))
}

type Bag =
  Dict(Color, Int)

fn get_color(color: String) -> Result(Color, String) {
  case color {
    "blue" -> Ok(Blue)
    "red" -> Ok(Red)
    "green" -> Ok(Green)
    _ -> Error("invalid color " <> color)
  }
}

fn get_id(header: String) -> Result(Int, String) {
  use #(_, str) <- try(
    header
    |> string.split_once(" ")
    |> replace_error("invalid header: " <> header),
  )

  str
  |> int.parse
  |> replace_error("invalid game id: " <> str)
}

fn parse_cubes(input: String) -> Result(Cubes, String) {
  use #(n, c) <- try(
    input
    |> string.trim
    |> string.split_once(" ")
    |> replace_error("invalid cubes: " <> input),
  )

  use number <- try(
    n
    |> int.parse
    |> replace_error("invalid int: " <> n),
  )

  use color <- try(
    c
    |> get_color,
  )

  Cubes(number, color) |> Ok
}

fn parse_reveal(input: String) -> Result(List(Cubes), String) {
  input
  |> string.trim
  |> string.split(", ")
  |> list.map(parse_cubes)
  |> result.all
}

fn parse_reveals(input: String) -> Result(List(Cubes), String) {
  input
  |> string.trim
  |> string.split("; ")
  |> list.map(parse_reveal)
  |> result.all
  |> result.map(list.flatten)
}

fn parse_game(line: String) -> Result(Game, String) {
  use #(header, reveals) <- result.try(case line |> string.split(":") {
    [game, pulls] -> Ok(#(game, pulls))
    _ -> Error("invalid game")
  })

  use id <- try(
    header
    |> get_id,
  )

  use reveals <- try(
    reveals
    |> parse_reveals,
  )

  Game(id, reveals) |> Ok
}

fn is_possible(game: Game, bag: Bag) -> Bool {
  game.reveals
  |> list.map(fn(cubes) {
    case bag |> dict.get(cubes.color) {
      Ok(total) -> cubes.count <= total
      Error(_) -> False
    }
  })
  |> list.any(bool.negate)
  |> bool.negate
}

fn get_minimum_bag(game: Game) -> Bag {
  game.reveals
  |> list.fold(dict.new(), fn(acc, cubes) {
    acc
    |> dict.upsert(cubes.color, fn(value) {
      case value {
        Some(current) -> int.max(current, cubes.count)
        None -> cubes.count
      }
    })
  })
}

fn get_bag_power(bag: Bag) -> Int {
  bag
  |> dict.fold(1, fn(acc, _, value) { acc * value })
}

pub fn main(input: String) -> Result(Nil, String) {
  use games <- try(
    input
    |> string.split("\n")
    |> list.map(parse_game)
    |> result.all,
  )

  let bag: Bag =
    dict.from_list([
      #(Red, 12),
      #(Green, 13),
      #(Blue, 14),
    ])

  games
  |> list.filter(is_possible(_, bag))
  |> list.fold(0, fn(acc, game) { acc + game.id })
  |> int.to_string
  |> io.println

  games
  |> list.map(get_minimum_bag)
  |> list.map(get_bag_power)
  |> int.sum
  |> int.to_string
  |> io.println

  Ok(Nil)
}
