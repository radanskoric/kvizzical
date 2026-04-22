// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"

Turbo.StreamActions.versioned_replace = function () {
  const target = this.targetElements[0]
  const payload = this.templateContent.firstElementChild

  if (!target || !payload) {
    Turbo.StreamActions.replace.call(this)
    return
  }

  const pageVersion = parseInt(target.dataset.version || "", 10)
  const payloadVersion = parseInt(payload.dataset.version || "", 10)

  if (Number.isNaN(pageVersion) || Number.isNaN(payloadVersion) || payloadVersion > pageVersion) {
    Turbo.StreamActions.replace.call(this)
  }
}
