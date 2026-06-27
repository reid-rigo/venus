# Venus

A small language that compiles to LuaJIT.

## Build & Run

```sh
mise build           # compile src/main.c -> bin/vs
./bin/vs file.vs     # compile and run
./bin/vs -c file.vs  # compile only (show Lua output)
./bin/vs -e 'code'   # run inline Venus code
./bin/vs --help      # flags
luajit src/main.lua  # dev equivalent (no build needed)
```

## Language

### Pipeline operator (`|>`)

```venus
2 |> math.pow(3) |> print           -- print(math.pow(2, 3))
"hello" |> string.upper |> print     -- print(string.upper("hello"))
```

The left-hand value is inserted as the first argument of the right-hand call.

Use `_` to explicitly place the value in a specific position:

```venus
2 |> math.pow(3, _)                 -- math.pow(3, 2)
2 |> math.pow(_, 3)                 -- math.pow(2, 3) -- same as default
```

### `let` declarations

```venus
let x = 42
let a, b = 1, 2
let y = 2 |> math.pow(3)
```

### Functions

```venus
fun add(a, b) {
  a + b
}

fun greet(name) {
  "hello " .. name
}

print(add(2, 3))                    -- 5
```

The last expression in a function body is returned implicitly.

### Lists (`[]`)

```venus
let t = []                    -- empty list
let t = [1 2 3]              -- space-separated values
let t = [1 [2 3]]            -- nested
```

### Maps (`{}`)

```venus
let m = {}                    -- empty map
let m = { "x" 1 "y" 2 }      -- string keys with values
let m = { x 10 }             -- identifier key (same as "x")
```

Map keys are always literal strings — identifier keys are not variable lookups.

### Literals & Operators

Numbers, strings (`"` or `'`), `+`, `-`, `*`, `/`, `( )`, member access (`.`), function calls, list literals (`[ ]`), map literals (`{ }`), comments (`--`).

## Project Structure

```
src/
  main.c     -- C harness (loads LuaJIT, runs main.lua)
  main.lua   -- CLI: flags, compile, run, REPL
  lexer.lua  -- tokenizer
  parser.lua -- recursive-descent parser
  codegen.lua -- Lua emitter
test/
  test.lua   -- test runner
  util.lua   -- shared compile helper for tests
  test_*.lua -- tests per feature
```
