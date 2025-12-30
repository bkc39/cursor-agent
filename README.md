# cursor-agent.el

An Emacs wrapper that launches the `cursor-agent` executable in a `vterm` buffer.

## Install (use-package + :vc)

```elisp
(use-package cursor-agent
  :vc (:url "https://github.com/yourname/cursor-agent")
  :commands (cursor-agent cursor-agent-run cursor-agent-restart))
```

## Usage

- `M-x cursor-agent` starts (or switches to) a vterm buffer running `cursor-agent`.
- `C-u M-x cursor-agent` restarts it.
- `M-x cursor-agent-run` prompts for extra CLI args.

