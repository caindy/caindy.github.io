---
layout: post
title:  "More Spacemacs"
date:   2016-02-06
permalink: more-spacemacs
categories: learning editors
---

`M-x` invokes smex (find Emacs commands)

Inter-file Navigation 
`SPC b b` open Helm mini-buffer
`SPC f f` Helm find files, is less useful than
`SPC p f` Projectile find files 
`SPC p p` Projectile find project

Consider using the Ranger layer (file manager)
invoked using `SPC a r` (applications ranger)
Consier using Unimpaired layer (tpope quick cycling)
Consider using Fasd layer to complement [Fasd](https://github.com/clvv/fasd)

Intra-file Navigation
`SPC s s` SWOOP! opens a copy of the buffer then elides lines that don't match the search you type, allowing you to navigate the top buffer by selecting lines in the swoop buffer

Window navigation
`SPC <number>` navigate numbered windows
Eyebrowse layer allows `SPC W` then a number to create/navigate to a new workspace
with Eybrwose working you can using Vim's `gt` and `gT` to 

Editing
Select some text, then `s <char>` will surround with <char>
iedit, get a selection (the whole current symbol by default) then `SPC s e` to enter
iedit mode, allowing you to edit all the matched things at once
`SPC ; ;` toggle line comment

Help
`SPC h d` invokes "help describe", providing access to multipe ways of find help 
`SPC f e h` is canonical spacemacs help

Checking
`SPC t s` turns on syntax checking

Future layers to explore
OrgMode + Capture mode
Abbrev mode 

