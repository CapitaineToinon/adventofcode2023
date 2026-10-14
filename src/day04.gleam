import gleam/dict
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{None, Some}
import gleam/result.{try}
import gleam/set.{type Set}
import gleam/string

type Card {
  Card(id: Int, wins: Int)
}

fn remove_double_spaces(input: String) -> String {
  case string.contains(input, "  ") {
    True -> string.replace(input, "  ", " ") |> remove_double_spaces
    False -> input
  }
}

fn remove_header(input: String) -> String {
  case string.split_once(input, ": ") {
    Ok(#(_, tail)) -> tail
    _ -> input
  }
}

fn parse_numbers(input: String) -> Result(Set(Int), String) {
  use list <- try(
    input
    |> string.trim
    |> string.split(" ")
    |> list.map(int.parse)
    |> result.all
    |> result.replace_error("invalid list of numbers"),
  )

  set.from_list(list) |> Ok
}

fn parse_card(input: String, id: Int) -> Result(Card, String) {
  use #(left, right) <- try(
    input
    |> remove_double_spaces
    |> remove_header
    |> string.trim
    |> string.split_once(" | ")
    |> result.replace_error("invalid card"),
  )

  use left <- try(parse_numbers(left))
  use right <- try(parse_numbers(right))

  left
  |> set.filter(set.contains(right, _))
  |> set.size
  |> Card(id, _)
  |> Ok
}

fn parse_cards(input: String) -> Result(List(Card), String) {
  use cards <- try(
    input
    |> string.trim
    |> string.split("\n")
    |> list.index_map(parse_card)
    |> result.all,
  )

  cards
  |> list.reverse
  |> Ok
}

fn score(card: Card) -> Int {
  int.range(0, card.wins, [], list.prepend)
  |> list.fold(None, fn(acc, _) {
    case acc {
      None -> Some(1)
      Some(value) -> Some(value * 2)
    }
  })
  |> option.unwrap(0)
}

fn part_one(cards: List(Card)) -> Int {
  cards
  |> list.map(score)
  |> int.sum
}

fn update_counts(counts: dict.Dict(Int, Int), cards: List(Card)) -> Int {
  case cards {
    [] ->
      counts
      |> dict.values
      |> int.sum
    [card, ..tail] -> {
      let current = counts |> dict.get(card.id) |> result.unwrap(1)
      let counts = counts |> dict.insert(card.id, current)

      tail
      |> list.take(card.wins)
      |> list.fold(counts, fn(acc, card) {
        acc
        |> dict.get(card.id)
        |> result.unwrap(1)
        |> int.add(current)
        |> dict.insert(acc, card.id, _)
      })
      |> update_counts(tail)
    }
  }
}

fn part_two(cards: List(Card)) -> Int {
  dict.new()
  |> update_counts(cards)
}

pub fn main(input: String) -> Result(Nil, String) {
  use cards <- try(
    input
    |> parse_cards,
  )

  cards
  |> part_one
  |> int.to_string
  |> io.println

  cards
  |> list.reverse
  |> part_two
  |> int.to_string
  |> io.println

  Ok(Nil)
}
