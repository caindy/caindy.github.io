---
layout: post
title:  "F# 2015 Advent Cookies"
date:   2015-12-06 00:00:00Z
permalink: fsharp-advent-2015
categories: fsharp
---
The big brains in FP have for a long time shared [Functional Pearls](https://wiki.haskell.org/Research_papers/Functional_pearls):
> elegant, instructive examples of functional programming. They are supposed to be fun, and they teach important programming techniques and fundamental design principles

In some communities sharing of another kind happens at this time of year: [cookie swaps](https://www.google.com/search?q=cookie+swap "it really is a thing").
[F# Advent](https://sergeytihon.wordpress.com/2015/10/25/f-advent-calendar-in-english-2015/) is becoming a tradition in its own right, and my contribution is what I'd like to call _F# Cookies_.

An Cookie is a (sometimes) elegant use of the particularly flexible and concise syntax of the language to create a "mouthful" of programming goodness.
In other words we take syntactic sugar and make something delicious. As with most kinds of cookies, I make no claim that any of these are good for you, but I hope you'll enjoy them nonetheless.

Let's get started with removing some boilerplate when parsing numeric values out of a string.
<script src="https://gist.github.com/caindy/bca4f64f1212e2426d5e.js"></script>
This code allows us use the `TryParse` static method that is common to most of the BCL numeric types, e.g. Byte, Int32, etc. implicitly.
It does this through the use of statically-resolved type parameters. This is an extremely powerful feature that enables all kinds of
wonderment, though it can be difficult to get the syntax right at first.

Speaking of statically resolved types, [Mauricio](https://twitter.com/mausch) and [Lev](https://twitter.com/eulerfx) are the great chefs behind this next cookie.
With a little bit of hacking with [Fleece](https://github.com/mausch/Fleece/blob/master/Fleece/Fleece.fs) ([see also](https://gist.github.com/eulerfx/68975495f41bc3ce5683))
I was able to obtain this result:
<script src="https://gist.github.com/caindy/24e15d24621d31dec3a9.js"></script>
The cool thing here is the use of the `(?)` operator to change `jgetopt json "someKey"` to `json?someKey`. The use of a question mark also points at the "maybe" semantics; very tasty!
You should definitely read [this year's advent article](http://techgroup.jet.com/blog/2015/11-27-how-jet-build-microservices-with/index.html) from [Rachel](https://twitter.com/RachelReese) to learn more about this kind of thing.

Finally, I'll leave you with a really unhealthy batch.
<script src="https://gist.github.com/caindy/9bf281ecada30038510e.js"></script>
Besides being a silly way to send holiday greetings, the `(|Twelvetide|)` pattern show that F# allows an active pattern match in a parameter. Parameters are patterns;
most of the time they are of the form `(arg : T)`, but just as you can write `let (Some f') = f` you can write `let f (Some s) = s`. Really, you should avoid doing this and pay
attention to the compiler warnings to avoid runtime exceptions, but it does highlight how central pattern matching is to F#.
