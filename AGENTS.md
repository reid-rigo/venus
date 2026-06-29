# Venus — a small language that compiles to Chez Scheme

## Build & Test
- Build: `mise build`
- Test: `./bin/vs test/run_all.vs`
- Run: `./bin/vs file.vs`

## Structure
- `src/chez_main.c` — C harness for Chez Scheme
- `src/chez_main.ss` — CLI entry point
- `src/chez_runtime.ss` — runtime (List, Table, String, Math, imports)
- `src/lexer.ss` — tokenizer
- `src/parser.ss` — recursive-descent parser
- `src/codegen.ss` — Scheme emitter
