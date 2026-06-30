<p align="center">
  <img src="vscode-venus/icon.png" alt="Venus" width="128" height="128">
</p>

# Venus

A small, functional-first language built on Chez Scheme.

## Build & Run

```sh
mise run build       # compile main.c -> bin/vs
./bin/vs file.vs     # compile and run
./bin/vs -c file.vs  # compile only (show Scheme output)
./bin/vs -e 'code'   # run inline Venus code
./bin/vs --help      # flags
./bin/vs             # start REPL
```

Tests: `mise run test`

## Language

### String interpolation

```venus
let name = "world"
print("hello ${name}")             // hello world
print("2 + 2 = ${2 + 2}")          // 2 + 2 = 4
```

Use `${expr}` inside double-quoted (`"`) or triple-quoted (`"""`) strings to embed any expression. Single-quoted strings (`'`) are literal — no interpolation.

### Pipeline operator (`|>`)

```venus
2 |> Math.pow(3) |> print           // print(Math.pow(2, 3))
"hello" |> string.upper |> print    // print(string.upper("hello"))
```

The left-hand value is inserted as the first argument of the right-hand call.

Use `_` to explicitly place the value in a specific position:

```venus
2 |> Math.pow(3, _)                 // Math.pow(3, 2)
2 |> Math.pow(_, 3)                 // Math.pow(2, 3)
```

### `let` declarations

```venus
let x = 42
let a, b = 1, 2
let y = 2 |> Math.pow(3)
```

### Functions

```venus
fn add(a, b) {
  a + b
}

fn greet(name) {
  "hello ${name}"
}

print(add(2, 3))                    // 5
```

The last expression in a function body is returned implicitly.

### Function overloading

Functions can be overloaded by value — define multiple `fn` with the same name and literal parameters:

```venus
fn fib(0) { 0 }
fn fib(1) { 1 }
fn fib(n) { fib(n-1) + fib(n-2) }

print(fib(10))                      // 55
```

Literal params (`NUMBER`, `STRING`) are matched against the first argument. Identifier params match any value and bind the argument to the name. The first matching overload wins. Non-literal overloads act as a fallback.

Overloads are collected at compile time into a single dispatch function — no runtime cost beyond a short if-else chain.

### Inline functions (lambdas)

```venus
let double = fn(x) { x * 2 }
map([1 2 3], fn(x) { x * 2 })
5 |> fn(x) { x * 2 }
```

Same syntax as named functions — just omit the name.

### If / else if / else

```venus
fn describe(x) {
  if x == 0 {
    "zero"
  } else if x == 1 {
    "one"
  } else {
    "other"
  }
}
```

`if` is a statement (not an expression). Each branch is a `{ }` block; the last expression in each branch is returned. The `else` branch is optional.

### Comparison & Logical Operators

`==` `!=` `<` `>` `<=` `>=` `and` `or`

Comparisons and logicals compose naturally with arithmetic:

```venus
x > 0 and x < 10
x == 0 or x == 1
1 + 2 == 3
```

### Match (`match`)

```venus
let x = 1
let desc = match x {
  1 -> "one"
  2 -> "two"
  _ -> "other"          // wildcard fallback
  y -> y                // or bind to a variable
}
```

Patterns: literal numbers/strings, `_` wildcard, or a variable binding. Unlike `if`, `match` is an expression — it returns a value.

### Modules

Venus modules use `import` for importing and `export` for exporting:

```venus
import "math"                    // side-effect only (no return value)
let m = import "math"            // assign the returned module
print(m.pi)                      // 3.14159
```

Export a value to make a file a module:

```venus
// math_util.vs
fn add(a, b) { a + b }
fn sub(a, b) { a - b }

export { add -> add, sub -> sub }
```

```venus
// main.vs
let util = import "math_util"
print(util.add(2, 3))            // 5
```

Built-in modules (`math`, `map`, `vector`) can be imported without a file path.

`export` must be the last statement in the file. Use `import` anywhere an expression is expected.

### Multiline Strings (`"""`)

```venus
let s = """hello
world"""
print(s)                            // hello\nworld
```

Triple-quoted strings can span multiple lines and support interpolation: `"""${expr}"""`.

## Data Structures

| | Mutable | Literal | Prints as | Backed by |
|---|---|---|---|---|
| `List` | No | `[a b c]` | `[a b c]` | Functional dequeue (ideque) |
| `Table` | Yes | `{k -> v}` / `#{k -> v}` | `#{"k" -> v}` | Chez hash table (O(1)) |
| `Map` | No | `Map.make(k, v, ...)` | SRFI 146 format | HAMT (persistent, O(log n)) |
| `Vector` | Yes | `#[a b c]` | `#[a b c]` | Dynamic array (doubling growth) |

Use `.` for field access on tables and modules: `t.x`, `math.pi`. Use `?.` for safe navigation that returns `nil` instead of erroring when the left side is `nil`.

## Standard Library

Built-in modules available as globals:

### `List`

| Function | Description |
|---|---|
| `List.add(t, v)` | Append `v` to list, returns list |
| `List.get(t, i)` | Element at 1-based index `i` |
| `List.len(t)` | Number of elements |
| `List.map(t, f)` | New list of `f(v)` for each element |
| `List.filter(t, f)` | New list where `f(v)` is truthy |
| `List.reduce(t, f, init)` | Fold left: `f(acc, v)` |
| `List.each(t, f)` | Call `f(v, i)` for each element, returns nothing |
| `List.join(t, sep?)` | Join elements into string, default sep `""` |
| `List.remove(t, i)` | Remove element at index `i`, returns list |
| `List.range(s, e)` | New list of integers from `s` to `e` inclusive |
| `List.flatten(t)` | Flatten nested lists one level |
| `List.reverse(t)` | New list in reverse order |
| `List.find(t, f)` | First element where `f(v)` is truthy, or `nil` |
| `List.any(t, f)` | Whether any element satisfies `f(v)` |
| `List.all(t, f)` | Whether all elements satisfy `f(v)` |

### `Table`

| Function | Description |
|---|---|
| `Table.get(m, k)` | Value at key `k` |
| `Table.set(m, k, v)` | Set `m[k] = v`, returns `m` |
| `Table.keys(m)` | List of keys |
| `Table.values(m)` | List of values |
| `Table.len(m)` | Number of entries |
| `Table.has(m, k)` | Whether key exists |
| `Table.remove(m, k)` | Remove key, returns `m` |
| `Table.each(m, f)` | Call `f(v, k)` for each entry, returns nothing |
| `Table.map(m, f)` | New list of `f(v)` for each entry |
| `Table.merge(a, b)` | New table merging `b` into `a` (b wins conflicts) |
| `Table.invert(m)` | New table swapping keys and values |
| `Table.pick(m, ks)` | New table with only the given keys |
| `Table.omit(m, ks)` | New table without the given keys |
| `Table.map_keys(m, f)` | New table with keys transformed by `f(k)` |
| `Table.filter(m, f)` | New table where `f(v, k)` is truthy |
| `Table.to_list(m)` | List of values |

### `Map`

Immutable HAMT (SRFI 146). All operations return a new map. Prints as SRFI 146's default representation.

| Function | Description |
|---|---|
| `Map.make(...)` | Create map from key-value pairs |
| `Map.get(m, k)` | Value at key `k`, or `nil` |
| `Map.set(m, k, v)` | New map with `k` set to `v` |
| `Map.has(m, k)` | Whether key exists |
| `Map.len(m)` | Number of entries |
| `Map.keys(m)` | List of keys |
| `Map.values(m)` | List of values |
| `Map.remove(m, k)` | New map without key `k` |
| `Map.each(m, f)` | Call `f(v, k)` for each entry |
| `Map.map(m, f)` | New list of `f(v)` for each entry |
| `Map.filter(m, f)` | New map where `f(v, k)` is truthy |
| `Map.merge(a, b)` | New map merging `b` into `a` (b wins) |
| `Map.to_list(m)` | List of `[k, v]` pairs |

### `Vector`

Mutable dynamic array with doubling growth. All operations mutate in place and return the vector. Prints as `#[1 2 3]`.

| Function | Description |
|---|---|
| `Vector.make(n?, init?)` | Create vector, optional size and default value |
| `Vector.len(v)` | Number of elements |
| `Vector.get(v, i)` | Element at 1-based index |
| `Vector.set(v, i, val)` | Set element, returns `v` |
| `Vector.push(v, val)` | Append element, returns `v` |
| `Vector.pop(v)` | Remove and return last element |
| `Vector.each(v, f)` | Call `f(val)` for each element |
| `Vector.map(v, f)` | New list of `f(val)` for each element |
| `Vector.filter(v, f)` | New list where `f(val)` is truthy |
| `Vector.to_list(v)` | Convert to list |
| `Vector.copy(v)` | Shallow copy |

### `String`

| Function | Description |
|---|---|
| `String.len(s)` | Character count |
| `String.reverse(s)` | Reversed string |
| `String.repeat_str(s, n)` | `s` repeated `n` times |
| `String.pad(s, w)` | Right-pad with spaces to width `w` |
| `String.pad_left(s, w)` | Left-pad with spaces to width `w` |
| `String.replace(s, from, to)` | Replace all occurrences |
| `String.chars(s)` | List of single-character strings |
| `String.is_empty(s)` | Whether length is 0 |
| `String.split(s, sep)` | Split by separator into a list |
| `String.trim(s)` | Remove leading/trailing whitespace |
| `String.starts_with(s, prefix)` | Whether string starts with prefix |
| `String.ends_with(s, suffix)` | Whether string ends with suffix |
| `String.contains(s, sub)` | Whether string contains substring |
| `String.concat(...)` | Join varargs into a string |
| `String.upper(s)` | Uppercase copy |

### `Math`

| Function | Description |
|---|---|
| `Math.abs(x)` | Absolute value |
| `Math.floor(x)` | Round down |
| `Math.ceil(x)` | Round up |
| `Math.round(x)` | Round to nearest integer |
| `Math.sqrt(x)` | Square root |
| `Math.pow(x, y)` | `x` raised to `y` |
| `Math.max(...)` | Largest of values |
| `Math.min(...)` | Smallest of values |
| `Math.pi` | Constant 3.14159... |

`nil` and `false` are falsy in conditionals; everything else is truthy.
