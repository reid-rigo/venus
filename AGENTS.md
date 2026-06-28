# Venus — a small language that compiles to LuaJIT

## Build & Test
- Build: `mise build`
- Test: `./bin/vs test/run_all.vs`
- Run: `./bin/vs file.vs` or `luajit src/main.lua`

## Structure
- `src/main.lua` — CLI
- `src/lexer.lua` — tokenizer
- `src/parser.lua` — recursive-descent parser
- `src/codegen.lua` — Lua emitter
