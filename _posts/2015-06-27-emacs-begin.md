
`brew tap railwaycat/emacsmacport`
`brew install emacs-mac`
`brew untap railwaycat/emacsmacport`
`git clone --recursive https://github.com/syl20bnr/spacemacs ~/.emacs.d`

Open emacs, allow it to update, restart
Update it manually (link), then
```
git pull --rebase
git submodule sync; git submodule update
```
Restart emacs

Edit `~/.spacemacs` `SPC f e d` and pick your layers
```
(shell :variables
            shell-default-shell 'multi-term
            shell-default-term-shell "/bin/zsh")
```

The following settings were about getting utf-8 characters in the terminal
but I hoped to use a simpler theme in emacs mode as advised by (this article about using multi-term)[http://rawsyntax.com/blog/learn-emacs-zsh-and-multi-term/]
```
(defadvice multi-term (after advise-multi-term-coding-system)
    (set-buffer-process-coding-system 'utf-8-unix 'utf-8-unix))
  (ad-activate 'multi-term)
  (prefer-coding-system 'utf-8)
  (setq system-uses-terminfo nil)

```
Update *zsh* color settings per this (SO answer)[http://stackoverflow.com/a/26549524]
```
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export TERM=xterm-256color
```
