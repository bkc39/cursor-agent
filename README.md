# cursor-agent.el

An Emacs wrapper that launches the `cursor-agent` executable in a `vterm` buffer.

## Install

If you manage `vterm` with `use-package` + `:vc`, you can declare it alongside
`cursor-agent`:

```elisp
(use-package vterm
  :vc (:url "https://github.com/akermu/emacs-libvterm.git")
  :commands vterm)

(use-package cursor-agent
  :vc (:url "https://github.com/bkc39/cursor-agent")
  :when (and (executable-find "cursor-agent")
             (locate-library "vterm"))
  :after vterm
  :commands (cursor-agent cursor-agent-run cursor-agent-restart))
```

## Usage

- `M-x cursor-agent` starts (or switches to) a vterm buffer running `cursor-agent`.
- `C-u M-x cursor-agent` restarts it.
- `M-x cursor-agent-run` prompts for extra CLI args.
