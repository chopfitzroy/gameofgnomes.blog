# AGENTS.md

Static site built with [Soupault](https://soupault.app).

- Source pages live in `site/`, templates in `templates/`, config in `soupault.toml`.
- Output is generated into `build/` (do not edit directly).
- Soupault source and docs are vendored in `.refs/`:
  - `.refs/soupault/` — Soupault source code
  - `.refs/soupault-website/` — Soupault website/docs source

Soupault embeds **Lua 2.5** (via lua-ml), not modern Lua. When writing hooks/plugins: define functions as global `function name()` statements (no `local function`, no `foo = function()`), walk arrays with `size()` + a `while` loop (no `#` operator or `ipairs`), there is no boolean type (`nil` is the only falsy value), and there is no `os`/`string` method syntax (use soupault's `String`/`Regex`/`Sys` modules instead).
