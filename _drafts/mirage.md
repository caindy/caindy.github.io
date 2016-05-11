
[Install Mirage](https://mirage.io/wiki/install)
brew update
brew install opam

opam list

=-=- cryptokit.1.9 troobleshooting =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=  🐫 
=> This package relies on external (system) dependencies that may be missing. `opam depext cryptokit.1.9' may help you find the correct installation for your system.
The former package state can be restored with opam switch import "/Users/ca/.opam/backup/state-20160411154423.export" --switch system


opam install mirage

opam pin add camlp4 https://github.com/ocaml/camlp4.git\#4.03

opam install mirage

git clone https://github.com/mirage/mirage-skeleton


copy the ml files in /static_website to a _mirage folder in your Jekyll blog
repo, per http://amirchaudhry.com/from-jekyll-to-unikernel-in-fifty-lines

Changing config.ml to use ../site instead of htdocs

Then do the instructions here to test
https://github.com/mirage/mirage-skeleton/tree/master/static_website

CI

Added to my Jekyll repo
https://raw.githubusercontent.com/ocaml/ocaml-ci-scripts/master/.travis.yml

Read more here
https://github.com/ocaml/ocaml-ci-scripts/blob/master/README-travis.md



