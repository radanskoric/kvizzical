# Kvizzical

A quiz app built with Rails 8. Create quizzes, host live games, and let players join in.

## Getting started

This project comes with a devcontainer, which is the easiest way to get up and running. Just open it in a supported editor (VS Code, Codespaces, etc.) and the environment will be set up for you. From there:

```bash
bin/dev
```

## Running tests

```bash
bin/rails test            # unit & integration tests
bin/rails test:system     # browser tests (headless Chrome)
```

## Linting

```bash
bundle exec rubocop       # check style
bundle exec rubocop -A    # auto-fix what it can
bundle exec brakeman      # security scan
```

## Development tools

- **Letter Opener Web** — preview emails at `/letter_opener`
- **Litestream Dashboard** — check backup status at `/litestream`
- **LogBench** — run `logbench` instead of digging through raw logs
- **AmazingPrint** — prettier objects in `bin/rails console`

## Tech stuff

SQLite3 everywhere, Hotwire (Turbo + Stimulus) for the frontend, Tailwind for styling, Propshaft for assets, and Herb for enhanced ERB templates. Backups handled by Litestream.

## Contributors

Created by: [Radan Skorić](https://radan.dev/)
