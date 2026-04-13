import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    seconds: Number,
    openedAt: String,
    finishUrl: String
  }

  connect() {
    this.finished = false
    this.update()
    this.timer = setInterval(() => this.update(), 100)
  }

  disconnect() {
    if (this.timer) clearInterval(this.timer)
  }

  update() {
    const openedAt = new Date(this.openedAtValue).getTime()
    const now = Date.now()
    const elapsed = (now - openedAt) / 1000
    const remaining = Math.max(this.secondsValue - elapsed, 0)

    this.element.textContent = Math.ceil(remaining)

    const fraction = remaining / this.secondsValue
    this.element.style.setProperty("--progress", `${fraction * 100}%`)

    if (remaining <= 0) {
      clearInterval(this.timer)
      this.element.classList.add("text-red-500")
      this.triggerFinish()
    } else if (remaining <= 5) {
      this.element.classList.add("text-red-500")
      this.element.classList.remove("text-red-600")
    }
  }

  triggerFinish() {
    if (this.finished || !this.finishUrlValue) return
    this.finished = true

    const csrfToken = document.querySelector("meta[name='csrf-token']")?.content
    fetch(this.finishUrlValue, {
      method: "POST",
      headers: {
        "X-CSRF-Token": csrfToken,
        "Accept": "text/vnd.turbo-stream.html"
      }
    })
  }
}
