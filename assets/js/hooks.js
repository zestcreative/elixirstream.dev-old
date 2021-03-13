let hooks = {}

hooks.PaginationScroll = {
  mounted() {
    this.handleEvent("scroll", ({ selector }) => {
      const el = document.querySelector(selector)
      if(el) {
        el.scrollIntoView({ behavior: "smooth" })
      } else {
        console.warn(`scroll event did not find ${selector} to scroll to`)
      }
    })
  }
}

hooks.PreviewImage = {
  mounted() {
    const container = this.el
    this.handleEvent("preview", ({ imgUrl }) => {
      const event = new CustomEvent("img-modal", { detail: imgUrl, bubbles: true })
      // Alpine needs some time to react first to the patch
      // before the event is dispatched
      setTimeout(() => container.dispatchEvent(event), 50)
    })
  }
}

hooks.MonocoEditor = {
  destroyed() {
    this.editor.unmount()
  },
  mounted() {
    console.log("Mounting")
    const where = this.el.dataset.mountSelector;
    const mountEl = this.el.querySelector(where)
    if (mountEl) {
      import(/* webpackChunkName: "code-editor" */ "./code-editor")
        .then(({ default: mounter }) => {
          const replace = this.el.dataset.mountReplaceSelector;
          const replaceEl = this.el.querySelector(replace)
          const editorStatus = this.el.dataset.editorStatusSelector
          const editorStatusEl = this.el.querySelector(editorStatus)
          let preferences = {}

          if(this.el.dataset.enableVim === "true") {
            preferences.vim = editorStatusEl
          } else if(this.el.dataset.enableEmacs === "true") {
            preferences.emacs = editorStatusEl
          }

          replaceEl.classList.add("hidden")
          mountEl.classList.remove("hidden")
          const editor = mounter.mount(mountEl, preferences)
          editor.setValue(replaceEl.value)
          editor.setOnChange({
            callback: (_event) => {
              let payload = editor.instance.getValue()
              replaceEl.value = payload
              this.pushEvent("code-updated", payload)
            },
            debounceMs: 1000
          })
          this.editor = editor
        });
      this.handleEvent("set_code", ({ code }) => {
        if (this.editor) {
          this.editor.setValue(code)
        }
      })
    } else {
      console.error(`Could not mount Monaco onto ${where}`)
    }

  }
}

export default hooks
