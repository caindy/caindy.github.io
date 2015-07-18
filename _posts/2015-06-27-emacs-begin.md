---
layout: post
title:  "Beginning Spacemacs"
date:   2014-06-25 13:28:03
permalink: begin-spacemacs
categories: learning
---


# And So It Begins
<blockquote class="twitter-tweet" lang="en"><p lang="en" dir="ltr">Began learning emacs via <a href="https://twitter.com/spacemacs">@spacemacs</a> Just had a strong sense of existential angst, as if by going further my life will be irrevocably altered</p>&mdash; Christopher Atkins (@CAIndy) <a href="https://twitter.com/CAIndy/status/615702309805256704">June 30, 2015</a></blockquote>

# So You Wanna Learn Emacs?
A little background about my (lack of) `vim` skills. I use `vim` keybindings quite a bit in Visual Studio, via VsVim (thanks Jared Par!), however I'm really a novice, despite heavy usage of the most basic commands. I started my programming career during the dotcom era and found my way into the industry with very little formal training due to that huge supply-side shortfall in the talent market. Over the years I've done a lot of independent professional study, having learned a few languages, but I've not really invested in learning tools outside of Visual Studio and Resharper. The latter I picked up as a Thoughtworker, along with intense use of `git`. At LambdaConf this year I met Andrew Cherry (@kolektiv) and in the course of discussing all things F#, he mentioned that he does most of his development on OSX in Emacs; I'd always intended to make an earnest attempt to learn the same, but this renewed my resolve. So, here I am.

# Getting Started
Like a lot of folks, I work on a Macbook Pro. Here's some prerequisites for getting started with Spacemacs:
{% highlight bash %}
brew tap railwaycat/emacsmacport
brew install emacs-mac
brew untap railwaycat/emacsmacport
{% endhighlight %}


So, now you've call a well-maintained version of Emac for your Mac. Now, we're going to "install" Spacemacs:
{% highlight bash %}
git clone --recursive https://github.com/syl20bnr/spacemacs ~/.emacs.d
{% endhighlight %}

That's it! Installation is just cloning the repo in your Emacs configuration folder. You'll customize Spacemacs indendently, so you can always "re-install" by doing the following:
{% highlight bash %}
cd ~/.emacs.d && git fetch && git reset origin/master --hard
{% endhighlight %}

Your initial launch in Spacemacs is a little bumpy: open emacs, allow it to update, restart. Then Update it manually (you can hit tab to navigate the buttons), then:
{% highlight bash %}
git pull --rebase
git submodule sync; git submodule update
{% endhighlight %}

Restart emacs, you should be in business. Our next task is to arm our Spacemacs with great tools. These are installed by specifying "layers"". To edit `~/.spacemacs` type `SPC f e d` and pick your layers by adding them to `dotspacemacs-configuration-layers`. My first layer was getting `zsh` working well.
{% highlight elisp %}
(shell :variables
            shell-default-shell 'multi-term
            shell-default-term-shell "/bin/zsh")
{% endhighlight %}

The following settings were about getting utf-8 characters in the terminal, but I switched to a simpler `zsh` theme in emacs mode as advised by (this article about using multi-term)[http://rawsyntax.com/blog/learn-emacs-zsh-and-multi-term/]. So, you can ignore these, but I'm recording it here:
{% highlight elisp %}
(defadvice multi-term (after advise-multi-term-coding-system)
    (set-buffer-process-coding-system 'utf-8-unix 'utf-8-unix))
  (ad-activate 'multi-term)
  (prefer-coding-system 'utf-8)
  (setq system-uses-terminfo nil)
{% endhighlight %}

Anyway, you'll want to update your `zsh` color settings per this (SO answer)[http://stackoverflow.com/a/26549524]
{% highlight bash %}
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export TERM=xterm-256color
{% endhighlight %}

Cool, one last thing for this getting started note; get your OSX layer working. It's pretty simple:
- `brew install coreutils` to get `gls`
- then add the `osx` spacemacs layer 

# Exploring
Spacemacs layers are all about making the Emacs ecosystem available via `vim`-style keybindings, but they're also a well-curated bundling of Emacs modes. I mentioned being a `vim` novice, but I did pick up a few tricks from Chris McCord. I used `CtrlP` and `NerdTree` via `vundler`. Spacemacs comes with `helm` and `Neotree` out of the box. Some commands I've been using a lot are:
- `Spc f r` recently used
- `Spc p t` toggles a `NerdTree` at the project root (it's smart like that)
- `Spc t ...` there are a lot of cool toggles here, various kinds of highlight, relative line numbers, etc.

The menus are easy to navigate, but you'll soon be ripping through these commands. Chris 

## Magit, or OhMaGit
I'm pretty comfortable with `git`. I've been using it since 2009, but only truly regularly since 2010. I'm no expert, but I can do anything I want with the tool pretty quickly. Right now it's still way more pleasant for me to `Spc '` (open my shell) and just issue `git` commands, but *Magit* is pretty rad. One thing I really like is being able to selectively modify the hunks I'm staging, and I can tell using the Magit layer via `Spc g ...` is going to be a lot faster than shelling out. Just be sure you have a cheatsheet open and force yourself to use the Magit major mode and keybindings.

## Languages
Some of the layers I'm really digging include `javascript` and `elixir`. I've still got some kinks to workout, but I can't imagine using another tool to program in these languages now.

## Next Steps
There is a *ton* to learn, but I think it's an investment that will pay off. I'm going to start using Spacemacs as my primary editor as much as possible. There are C# and F# layers that I hope will make that possible, and I'll be using the VMWare shared folder feature to edit the files in Spacemacs in OSX, then switch over to the Windows VM to compile and such. Besides that, I'd like to develop more proficiency with macros; stuff like this is just cool:
<blockquote class="twitter-tweet" lang="en"><p lang="en" dir="ltr"><a href="https://twitter.com/CAIndy">@CAIndy</a> <a href="https://twitter.com/bodil">@bodil</a> <a href="https://twitter.com/spacemacs">@spacemacs</a> Try this. Record a macro, Vim-style. Then do `SPC :` `kmacro-edit-macro`. Be amazed.</p>&mdash; deech (@deech) <a href="https://twitter.com/deech/status/616217205181652992">July 1, 2015</a></blockquote>
<script async src="//platform.twitter.com/widgets.js" charset="utf-8"></script>
