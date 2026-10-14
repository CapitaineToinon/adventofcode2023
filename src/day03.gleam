import gleam/bool
import gleam/dict
import gleam/int
import gleam/io
import gleam/list
import gleam/set
import gleam/string

type Type {
  Number(Int)
  Symbol(String)
}

type Node =
  #(Int, Type)

type Grid =
  dict.Dict(#(Int, Int), Node)

fn group_graphemes(line: List(String), out: List(String)) -> List(String) {
  case line {
    [] -> out |> list.reverse
    [next, ..rest] -> {
      case next, out {
        next, [] -> [next]
        next, [head, ..tail] ->
          case int.parse(next), int.parse(head) {
            Ok(_), Ok(_) -> [head <> next, ..tail]
            _, _ -> [next, head, ..tail]
          }
      }
      |> group_graphemes(rest, _)
    }
  }
}

fn create_grid(input: String) -> Grid {
  input
  |> string.trim
  |> string.split("\n")
  |> list.map(string.to_graphemes)
  |> list.map(group_graphemes(_, []))
  |> list.index_fold(dict.new(), fn(grid, line, y) {
    let #(grid, _) =
      line
      |> list.fold(#(grid, 0), fn(acc, i) {
        let #(grid, x) = acc

        use <- bool.guard(i == ".", #(grid, x + 1))
        let id = grid |> dict.size

        let node = case int.parse(i) {
          Ok(value) -> Number(value)
          Error(_) -> Symbol(i)
        }

        let grid =
          int.range(0, string.length(i), [], list.prepend)
          |> list.fold(grid, fn(grid, offset) {
            grid
            |> dict.insert(#(y, x + offset), #(id, node))
          })

        #(grid, x + string.length(i))
      })

    grid
  })
}

fn get_starting_positions(
  grid: Grid,
  predicate: fn(Type) -> Bool,
) -> List(#(Int, Int)) {
  grid
  |> dict.filter(fn(_, node) { predicate(node.1) })
  |> dict.to_list
  |> list.map(fn(entry) {
    let #(key, _) = entry
    key
  })
}

fn get_numbers_neighbors(grid: Grid, start: #(Int, Int)) -> set.Set(Node) {
  int.range(-1, 2, [], list.prepend)
  |> list.flat_map(fn(y) {
    int.range(-1, 2, [], list.prepend) |> list.map(fn(x) { #(y, x) })
  })
  |> list.filter_map(fn(offset) {
    let #(y, x) = start
    let #(oy, ox) = offset

    case grid |> dict.get(#(y + oy, x + ox)) {
      Ok(#(id, Number(value))) -> Ok(#(id, Number(value)))
      _ -> Error("no")
    }
  })
  |> set.from_list
}

fn part_one(grid: Grid) -> Int {
  grid
  |> get_starting_positions(fn(node) {
    case node {
      Symbol(_) -> True
      _ -> False
    }
  })
  |> list.fold(set.new(), fn(acc, start) {
    let neigbors = get_numbers_neighbors(grid, start)
    acc |> set.union(neigbors)
  })
  |> set.fold(0, fn(acc, item) {
    case item {
      #(_, Number(value)) -> acc + value
      _ -> acc
    }
  })
}

fn part_two(grid: Grid) -> Int {
  grid
  |> get_starting_positions(fn(node) {
    case node {
      Symbol("*") -> True
      _ -> False
    }
  })
  |> list.fold(0, fn(acc, start) {
    let neigbors = get_numbers_neighbors(grid, start)
    use <- bool.guard(set.size(neigbors) != 2, acc)

    neigbors
    |> set.fold(1, fn(acc, node) {
      case node {
        #(_, Number(value)) -> acc * value
        _ -> 0
      }
    })
    |> int.add(acc)
  })
}

pub fn main(input: String) -> Result(Nil, String) {
  let grid =
    input
    |> create_grid

  grid
  |> part_one
  |> int.to_string
  |> io.println

  grid
  |> part_two
  |> int.to_string
  |> io.println

  Ok(Nil)
}
