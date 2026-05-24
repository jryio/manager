# Introduction

Helix can use external formatting programs available in the system `$PATH`.

- Add these settings to `languages.toml` inside your config directory
- `auto-format = true` and other language settings are inherited from [languages.toml](https://github.com/helix-editor/helix/blob/master/languages.toml), there is no need to repeat them
- Specifying an external formatter will replace any formatting supplied by the language server
- Windows users [_may_ need to specify the full path to the executable](https://github.com/helix-editor/helix/discussions/3198#discussioncomment-3325065)

# Astro

You will also need to install https://www.npmjs.com/package/prettier-plugin-astro in your project

## Prettier

```toml
name = "astro"
formatter = { command = "prettier", args = ["--plugin", "prettier-plugin-astro", "--parser", "astro"] }
auto-format = true
```

# Bash

## AWK

GNU AWK can pretty-print scripts, which can be used as a formatter.

```toml
[[language]]
name = "awk"
formatter = { command = "awk", timeout = 5, args = [ "--file=/dev/stdin", "--pretty-print=/dev/stdout" ] }
auto-format = true
```

On macOS, GNU AWK installed via Homebrew is named `gawk` to not conflict with the system `awk`. Adjust the configuration accordingly.

## shfmt

> [!NOTE]
> Since [Bash Language Server 5.3.0](https://github.com/bash-lsp/bash-language-server/blob/main/server/CHANGELOG.md#530) shfmt formatting is built into the language server, so you don't need this config if you have the shfmt binary installed

https://github.com/mvdan/sh#shfmt or https://github.com/patrickvane/shfmt

- `shfmt` formats shell programs
- To see available formatting options: `shfmt -h`

The following have been tested:

4 spaces:

```toml
[[language]]
name = "bash"
indent = { tab-width = 4, unit = "    " }
formatter = { command = 'shfmt', args = ["-i", "4"] }
auto-format = true
```

tabs:

```toml
[[language]]
name = "bash"
indent = { tab-width = 4, unit = "\t" }
formatter = { command = "shfmt" }
auto-format = true
```

# C and C++

## clang-format

```toml
[[language]]
name = "c"
file-types = ["c", "h"]
formatter = { command = 'clang-format' }
auto-format = true

[[language]]
name = "cpp"
file-types = ["cpp", "cc", "cxx", "hpp", "hcc", "hxx"]
formatter = { command = 'clang-format' }
auto-format = true
```

# C#

## csharpier

https://csharpier.com/

```toml
[[language]]
auto-format = true
name = "c-sharp"
formatter = { command = "csharpier" }
```

# Fish

## fish_indent

`fish_indent` is built into fish!

The following has been tested:

```toml
[[language]]
name = "fish"
formatter = { command = "fish_indent" }
auto-format = true
```

# Fortran

## fprettify

https://github.com/pseewald/fprettify

A formatter for modern Fortran code.

```toml
[[language]]
name = "fortran"
formatter = { command = "fprettify" , args = ["--stdout"] }
auto-format = true
```

# GDScript

## gdformat

https://github.com/Scony/godot-gdscript-toolkit

A formatter for GDScript.

```toml
[[language]]
name = "gdscript"
formatter = { command = "gdformat", args = ["-"] }
auto-format = true
```

# Go

## Gofumpt

Gofumpt support is built-in into gopls, which is Go's language server.

```toml
[language-server.gopls.config]
gofumpt = true

[[language]]
name = "go"
auto-format = true
```

# GraphQL

## Prettier

```toml
[[language]]
name = "graphql"
formatter = { command = 'prettier', args = ["--parser", "graphql"] }
auto-format = true
```

## Prettierd

```toml
[[language]]
name = "graphql"
formatter = { command = 'prettierd', args = [".graphql"] }
auto-format = true
```

## Biome

```toml
[[language]]
name = "graphql"
formatter = { command = 'biome', args = ["format", "--stdin-file-path buffer.graphql"] }
auto-format = true
```

# Haskell

## stylish-haskell

https://github.com/haskell/stylish-haskell

A simple Haskell code prettifier. This tool tries to help where necessary without getting in the way.

```toml
[[language]]
name = "haskell"
formatter = { command = "stylish-haskell", args = [] }
auto-format = true
```

## fourmolu

https://github.com/fourmolu/fourmolu

Fourmolu is a formatter for Haskell source code. It is a fork of Ormolu, with the intention to continue to merge upstream improvements.

```toml
[[language]]
name = "haskell"
formatter = { command = "zsh", args = ["-c", "fourmolu --stdin-input-file $(pwd)" ] }
auto-format = true
```

# HTML and CSS

## Prettier

```toml
[[language]]
name = "html"
formatter = { command = 'prettier', args = ["--parser", "html"] }
auto-format = true

[[language]]
name = "css"
formatter = { command = 'prettier', args = ["--parser", "css"] }
auto-format = true

[[language]]
name = "scss"
formatter = { command = 'prettier', args = ["--parser", "scss"] }
auto-format = true
```

## Prettierd

```toml
[[language]]
name = "html"
formatter = { command = 'prettierd', args = [".html"] }
auto-format = true

[[language]]
name = "css"
formatter = { command = 'prettierd', args = [".css"] }
auto-format = true

[[language]]
name = "scss"
formatter = { command = 'prettierd', args = [".scss"] }
auto-format = true
```

## Deno

```toml
[[language]]
name = "html"
formatter = { command = 'deno', args = ["fmt", "-", "--ext", "html" ] }
auto-format = true

[[language]]
name = "css"
formatter = { command = "deno", args = ["fmt", "-", "--ext", "css" ] }
auto-format = true
```

## Biome

> [!NOTE]
> Biome currently [does not support `.scss` or `.html` formatting](https://biomejs.dev/internals/language-support/)

```toml
[[language]]
name = "css"
formatter = { command = 'biome', args = ["format", "--stdin-file-path", "buffer.css"] }
auto-format = true
```

# Java

## google-java-format

https://github.com/google/google-java-format

Java code formatter. Reformats Java source code to comply with [Google Java Style](https://google.github.io/styleguide/javaguide.html).

Create a shell script with the content below with execution permission, include it in the PATH to use four spaces instead of tabs.

```bash
#!/usr/bin/env bash

$JAVA_HOME/bin/java -jar <path-to-jar-file>/google-java-format-1.21.0-all-deps.jar -a $1
```

In languages.toml file:

```toml
[[language]]
name = "java"
indent = { tab-width = 4, unit = "    " }
formatter = { command = "google-java-format", args = ["-"] }
auto-format = true
```

# JavaScript (JS), TypeScript (TS), JSX and TSX

## Prettier

```toml
[[language]]
name = "javascript"
formatter = { command = 'prettier', args = ["--parser", "typescript"] }
auto-format = true

[[language]]
name = "typescript"
formatter = { command = 'prettier', args = ["--parser", "typescript"] }
auto-format = true

[[language]]
name = "tsx"
formatter = { command = 'prettier', args = ["--parser", "typescript"] }
auto-format = true
```

## Prettierd

Prettierd runs prettier as a daemon, with significant performance improvements

```toml
[[language]]
name = "javascript"
formatter = { command = 'prettierd', args = [".js"] }
auto-format = true

[[language]]
name = "typescript"
formatter = { command = 'prettierd', args = [".ts"] }
auto-format = true

[[language]]
name = "jsx"
formatter = { command = 'prettierd', args = [".jsx"] }
auto-format = true

[[language]]
name = "tsx"
formatter = { command = 'prettierd', args = [".tsx"] }
auto-format = true
```

## Deno

```toml
[[language]]
name = "javascript"
formatter = { command = 'deno', args = ["fmt", "-", "--ext", "js" ] }
auto-format = true

[[language]]
name = "typescript"
formatter = { command = 'deno', args = ["fmt", "-", "--ext", "ts" ] }
auto-format = true

[[language]]
name = "jsx"
formatter = { command = 'deno', args = ["fmt", "-", "--ext", "jsx" ] }
auto-format = true

[[language]]
name = "tsx"
formatter = { command = 'deno', args = ["fmt", "-", "--ext", "tsx" ] }
auto-format = true
```

## Biome

```toml
[[language]]
name = "javascript"
formatter = { command = 'biome', args = ["format", "--stdin-file-path", "buffer.js"] }
auto-format = true

[[language]]
name = "typescript"
formatter = { command = 'biome', args = ["format", "--stdin-file-path", "buffer.ts"] }
auto-format = true

[[language]]
name = "jsx"
formatter = { command = 'biome', args = ["format", "--stdin-file-path", "buffer.jsx"] }
auto-format = true

[[language]]
name = "tsx"
formatter = { command = 'biome', args = ["format", "--stdin-file-path", "buffer.tsx"] }
auto-format = true
```

# JSON and JSONC

## Deno

```toml
[[language]]
name = "json"
formatter = { command = 'deno', args = ["fmt", "-", "--ext", "json" ] }
auto-format = true

[[language]]
name = "jsonc"
formatter = { command = 'deno', args = ["fmt", "-", "--ext", "jsonc" ] }
auto-format = true
```

## Prettier

```toml
[[language]]
name = "json"
formatter = { command = 'prettier', args = ["--parser", "json"] }
auto-format = true

[[language]]
name = "jsonc"
formatter = { command = 'prettier', args = ["--parser", "jsonc"] }
auto-format = true
```

## Prettierd

```toml
[[language]]
name = "json"
formatter = { command = 'prettierd', args = [".json"] }
auto-format = true

[[language]]
name = "jsonc"
formatter = { command = 'prettierd', args = [".jsonc"] }
auto-format = true
```

## Biome

```toml
[[language]]
name = "json"
formatter = { command = 'biome', args = ["format", "--stdin-file-path", "buffer.json"] }
auto-format = true

[[language]]
name = "jsonc"
formatter = { command = 'biome', args = ["format", "--stdin-file-path", "buffer.jsonc"] }
auto-format = true
```

# Just

```toml
[[language]]
name = "just"
auto-format = true
formatter = { command = "just", args = ['--justfile', '/dev/stdin', '--dump'] }
```

# Laravel

## Blade

[Blade Formatter](https://github.com/shufo/blade-formatter)

- An opinionated blade template formatter for Laravel that respects readability.

```toml
[[language]]
name = "blade"
roots = ["composer.json", "index.php"]
formatter = { command = "blade-formatter", args = ["--write", "--stdin", "--wrap-line-length", "9999", "--wrap-attributes", "preserve-aligned"] }
auto-format = true
```

# Lua

## StyLua

Format lua files using [StyLua](https://github.com/JohnnyMorganz/StyLua)

```toml
[[language]]
name = "lua"
formatter = { command = "stylua", args = [ "-" ] }
auto-format = true
```

# Markdown

## Deno

```toml
[[language]]
name = "markdown"
formatter = { command = 'deno', args = ["fmt", "-", "--ext", "md" ] }
auto-format = true
```

## dprint

```toml
[[language]]
name = "markdown"
formatter = { command = "dprint", args = ["fmt", "--stdin", "md"] }
auto-format = true
```

## Prettier

```toml
[[language]]
name = "markdown"
formatter = { command = 'prettier', args = ["--parser", "markdown"] }
auto-format = true
```

## Prettierd

```toml
[[language]]
name = "markdown"
formatter = { command = 'prettierd', args = [".md"] }
auto-format = true
```

# Nix

## Nixfmt

```toml
[[language]]
name = "nix"
formatter = { command = "nixfmt" }
auto-format = true
```

# OCaml

## ocamlformat

https://github.com/ocaml-ppx/ocamlformat

```toml
[[language]]
name = "ocaml"
formatter = { command = "ocamlformat", args = ["-q", "--name=foo.ml", "-"] }
auto-format = true
```

The `--name` argument is required by ocamlformat when reading from stdin. `foo.ml` is a dummy value, the file does not have to exist for the formatter to work.

# Python

## Ruff

```toml
[[language]]
name = "python"
formatter = { command = "ruff", args = ["format", "--line-length", "88", "-"] }
auto-format = true
```

## Black

```toml
[[language]]
name = "python"
formatter = { command = "black", args = ["--quiet", "-"] }
auto-format = true
```

# Ruby

## SyntaxTree

Another formatting option for Ruby is [SyntaxTree](https://github.com/ruby-syntax-tree/syntax_tree), which is used "under the hood" by [Prettier for Ruby](https://github.com/prettier/plugin-ruby). It provides a few [configuration](https://github.com/ruby-syntax-tree/syntax_tree#configuration) options, either passed in as arguments or with a local `.streerc` file.

```toml
[[language]]
name = "ruby"
formatter = { command = "bundle", args = ["exec", "stree", "format"] }
auto-format = true
```

## StandardRB

A Ruby formatter that supports very little configuration so we can stop arguing about format and get on with our jobs. It's a wrapper around Rubocop so commands are basically identical.

```toml
[[language]]
name = "ruby"
formatter = { command = "bundle", args = ["exec", "standardrb", "--stdin", "foo.rb", "--fix", "--stderr"] }
auto-format = true
```

## RuboCop

A Ruby static code analyzer and formatter, based on the community Ruby style guide.

```toml
[[language]]
name = "ruby"
config = { solargraph = { diagnostics = true, formatting = false } }
formatter = { command = "bundle", args = ["exec", "rubocop", "--stdin", "foo.rb", "-a", "--stderr", "--fail-level", "fatal"] }
auto-format = true
```

Argument explanations:

- `--stdin foo.rb`: RuboCop requires a filename for its reports, this is a dummy value to fulfill this. Call it whatever. Make it your own. Have fun with it.
- `--stderr`: RuboCop absolutely ALWAYS prints any errors it identifies. This sends them to stderr, otherwise they'd show up in your editor.
- `--fail-level`: Any error in the RuboCop formatter will fail with error code "1." This can prevent your files from saving. Raising the `fail-level` to "fatal" will leave it on just for cases were RuboCop is not working at all.

The "config" block will prevent diagnostics from also breaking if formatting fails.

If not using RuboCop via Bundler, you can modify the `formatter` command accordingly (omitting the `bundle exec` prepend):

```ruby
formatter = { command = "rubocop", args = ["--stdin", "foo.rb", "-a", "--stderr", "--fail-level", "fatal"] }
```

Also worth a try:

```toml
[[language]]
name = "ruby"
formatter = { command = "rubocop", args = ["--stdin", "foo.rb", "-a", "--stderr", "--fail-level", "fatal"] }
auto-format = true


[[language-server.solargraph.config]]
diagnostics = true
formatting = false
```

# Rust

## dioxus fmt

`dioxus fmt` can format the `rsx!` macro:

```
[[language]]
name = "rust"
formatter = { command = "bash", args = ["-c", "rustfmt | dx fmt -f -"] }
```

# SQL

## sqlformat

https://github.com/andialbrecht/sqlparse

You can install sqlparse with pip to make the sqlformat command available.

```toml
[[language]]
name = "sql"
formatter = { command = "sqlformat", args = ["--reindent", "--indent_width", "2", "--keywords", "upper", "--identifiers", "lower", "-"] }
auto-format = true
```

# Svelte

You will also need to install https://www.npmjs.com/package/prettier-plugin-svelte in your project

## Prettier

```toml
name = "svelte"
formatter = { command = "prettier", args = ["--plugin", "prettier-plugin-svelte", "--parser", "svelte"] }
auto-format = true
```

# Swift

## swift-format

https://github.com/apple/swift-format

`swift-format` provides the formatting technology for [SourceKit-LSP](https://github.com/apple/sourcekit-lsp) and the building blocks for doing code formatting transformations.

```toml
[[language]]
name = "swift"
formatter = { command = "swift-format", args = ["format"] }
auto-format = true
```

> [!NOTE]
> Older version of swift-format does not seem to work with helix (e.g. v0.50500.0). v509.0.0 verified as working.

# TOML

## Taplo

https://github.com/tamasfe/taplo

A versatile, feature-rich TOML toolkit.

```toml
[[language]]
name = "toml"
formatter = { command = "taplo", args = ["format", "-"] }
auto-format = true
```

> [!note]
> `taplo` (with the `lsp` `feature`) can format files, but not buffers.
> And even the files that it _should_ format, may trigger "this document has been excluded", which disables formatting. So that config is necessary if you always want formatting.

## Tombi

https://tombi-toml.github.io/tombi

TOML Formatter / Linter / Language Serve

```toml
[[language]]
name = "toml"
auto-format = true
language-servers = ["tombi"]
```

# Typst

## typstyle

https://github.com/Enter-tainer/typstyle

Beautiful and reliable typst formatter

```toml
[[language]]
name = "typst"
formatter.command = "typstyle"
auto-format = true
```

## typstfmt (unmaintained)

https://github.com/astrale-sharp/typstfmt

Basic formatter for the Typst language with a future.

```toml
[[language]]
name = "typst"
formatter = { command = "typstfmt", args = ["--output", "-"] }
auto-format = true
```

# XML

## Gnome XML Library

```toml
[[language]]
name = "xml"
formatter = { command = "xmllint", args = ["--format", "-"] }
auto-format = true
```

## Tidy

```toml
[[language]]
name = "xml"
formatter = { command = "tidy", args = ["-q", "-xml", "--show-errors", "0", "--show-warnings", "0", "--force-output", "--indent", "auto",  "--vertical-space", "yes", "--tidy-mark", "no", "-wrap", "120"] }
auto-format = true
```

# Yaml

## dprint

```toml
[[language]]
name = "yaml"
formatter = { command = "dprint", args = ["fmt", "--stdin", "yaml"] }
auto-format = true
```

## Prettier

```toml
[[language]]
name = "yaml"
formatter = { command = "prettier", args = ["--parser", "yaml"] }
auto-format = true
```

## Prettierd

```toml
[[language]]
name = "yaml"
formatter = { command = "prettierd", args = [".yaml"] }
auto-format = true
```