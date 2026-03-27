# AGENTS.md

Instructions for AI coding agents working on this project.

## Tech Stack

- **Framework**: Rails 8
- **Database**: SQLite3 (all environments)
- **Frontend**: Hotwire (Turbo + Stimulus), Tailwind CSS
- **Assets**: Propshaft, Importmap
- **View rendering**: ReActionView + Herb (enhanced ERB)
- **Testing**: Minitest + Capybara (system tests)
- **Backups**: Litestream (SQLite replication)

## Essential Commands

```bash
bin/dev                    # Start dev server (Rails + Tailwind watcher)
bin/rails test             # Run unit/integration tests
bin/rails test:system      # Run system tests (Capybara)
bundle exec rubocop        # Linting
bundle exec brakeman       # Security scan
```

## Project Structure

```
app/
├── controllers/     # Request handling
├── models/          # Domain logic
├── views/           # ERB templates (processed by Herb)
├── javascript/      # Stimulus controllers
├── mailers/         # Action Mailer classes
test/
├── models/          # Model unit tests
├── controllers/     # Controller tests
├── integration/     # Integration tests
├── system/          # Browser tests (Capybara)
├── helpers/         # Helper tests
config/
├── routes.rb        # Application routes
├── database.yml     # Database config (SQLite3)
```

## Key Files

- `config/routes.rb` — Application routes
- `db/schema.rb` — Database schema
- `Gemfile` — Dependencies
- `Procfile.dev` — Development process configuration (web + tailwind watcher)

## Development Tools

- **Letter Opener Web** — Browse sent emails at `/letter_opener` in development
- **Litestream Dashboard** — View backup status at `/litestream` in development
- **LogBench** — Enhanced log viewer (run `logbench` instead of reading raw logs)
- **AmazingPrint** — Pretty-printed objects in `bin/rails console`

## Code Style

- Follow `rubocop-rails-omakase` style guide
- Use Tailwind CSS classes exclusively for styling
- Do not add/remove comments unless asked
- Keep changes minimal and focused

## Testing Guidelines

- Use Minitest (not RSpec)
- System tests use Capybara with headless Chrome
- Test the public interface, not implementation details
- One assertion per behavior; avoid redundancy
- Test files mirror `app/` structure under `test/`
