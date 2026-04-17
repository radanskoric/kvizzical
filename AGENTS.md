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
db/
├── migrate/         # Schema changes, including auth/session migrations
```

## Key Files

- `config/routes.rb` — Application routes
- `db/schema.rb` — Database schema
- `Gemfile` — Dependencies
- `Procfile.dev` — Development process configuration (web + tailwind watcher)
- `app/controllers/concerns/authentication.rb` — Cookie-backed authenticated session handling
- `app/controllers/application_controller.rb` — Shared authenticated/anonymous player resolution
- `app/controllers/registrations_controller.rb` — Account creation and anonymous-to-registered upgrades
- `app/controllers/play_controller.rb` — Public quiz participation flow
- `app/controllers/games_controller.rb` — Host-only quiz control flow
- `app/models/user.rb` — Shared anonymous participant and registered account model
- `app/models/session.rb` — Authenticated browser sessions

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

## Authentication & Session Model

- Registered accounts use `User` plus cookie-backed `Session` records via `Authentication`
- Anonymous quiz participants still use the ad hoc `session[:user_session_token]` flow
- `ApplicationController#current_player_user` prefers the authenticated user and falls back to the anonymous participant user
- Registration requires `name`, `email_address`, `password`, and `password_confirmation`
- Registering while anonymous should upgrade the anonymous `User` when possible and prefill the registration name from the anonymous session
- Hosting quiz games and viewing the host dashboard require authentication; joining and playing remain public

## Testing Guidelines

- Use Minitest (not RSpec)
- System tests use Capybara with headless Chrome
- Test the public interface, not implementation details
- One assertion per behavior; avoid redundancy
- Test files mirror `app/` structure under `test/`
- All changes must preserve or restore `100%` line coverage and
`100%` branch coverage by the end of the task.
- After every change, once `bin/rails test` is green, also run `bin/rails test:system` and ensure it is green.
- Prefer multi-session system tests for Hotwire live-update behavior instead of spying on internal broadcast calls.
- In host/player scenarios, sign the host session in explicitly before visiting `game_path` or posting host actions.
- Keep anonymous play coverage intact: joining and answering should continue to work without registration.
- If a major new user-facing feature is added, consider adding or extending a system test for it.
- For registration coverage, assert both fresh sign-up and upgrading an anonymous participant into a registered account.
- For host/player live update scenarios, assert user-visible content first (for example joined player names or visible count text) instead of relying on implementation-specific DOM hooks when possible.
- Prefer model-level Turbo broadcast tests using `ActionCable::TestHelper` (`capture_broadcasts` / `broadcasts`) for asserting correct broadcasts.
