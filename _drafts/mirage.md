
I'm a huge proponent of unikernels, but to date I've not _really_ used them.
This post is about how I changed that, at least insofar at the VM serving you
this page is running on a Mirage unikernel in EC2.

Let me start by stating unequivocally that it isn't almost entirely impractical
thing to run your personal blog on a unikernel in the cloud; it's like a Rube
Goldberg machine--the point is to learn and have fun.

That being said "blog post or it didn't happen" resonates with me, as the
journey to Mirage in production required a lot more yak shaving than I had
anticipated. Perhaps someone else will pass this way and find aid in these
words.

So here's the outline of my process:
- Starting with a Github pages blog using Jekyll,
- create a Travis CI build that creates a unikernel of your `_site`
- and spins up an EC2 instance that will build an AMI from your unikernel
- then spin up another instance hosting your site based on that AMI,
- swapping CNAMEs with your production blog when everything is copacetic.

Simple enough, right? *pfffft* You'll see...

The rest of this post is an attempt to describe how to get there from "ok, I
have a Jekyll blog on Github", roughly in the order of discovery. I'm also going
to assume you already EC2, i.e. you have the AWS CLI and know a bit about IAM.
Even though Mirage is an OCaml thing, you won't really need to have any OCaml
ecosystem knowledge, as most of the code in this post is Bash shell scripting.

All that being said, the first thing we want to do is build and host our Jekyll
blog locally within a Mirage artifact. So, let's get the
[Mirage toolchain installed](https://mirage.io/wiki/install). The easiest way to
do this is to run `unikernel/mirage` off of Docker Hub, but I'm going to
describe my journey and that includes installing on OSX.

Just a warning, if you, like me, had a way out of date `~/.opam` folder lying
around... do yourself a favor and just remove it. Also, this next bit take a
while, so run this script and go make some tea.

```bash
brew update
brew install opam
opam install mirage

opam pin add camlp4 https://github.com/ocaml/camlp4.git\#4.03

opam install mirage

git clone https://github.com/mirage/mirage-skeleton
```

So, the main divergence here from what you might find in the install
instructions on mirage.io is pinning the camlp4 library. I ended up with OCaml
4.03 at this point and for whatever reason the version on OPAM didn't jive. You
may not need that step. Anyway, we are going to grab a couple of files from the
`static-website` folder in the `mirage-skeleton` project and use them to create
a unikernel from our Jekyll output.

Copy the ml files in `/static_website` to a `_mirage` folder in your Jekyll blog
repo. Here's an
[older article](http://amirchaudhry.com/from-jekyll-to-unikernel-in-fifty-lines)
about this step. Changing `config.ml` to use `../_site` instead of `htdocs`. We
can now use the `mirage` command build our unikernel.

```bash
jekyll build
cd _mirage
mirage configure --unix --net=socket
```

Your blog should be up at `http://localhost:8080`.

### Using the Docker Image

It's going to be useful to play with the build in a Linux image.

### CI

Ok, let's replicate this success in Travis. Setting us Travis is super easy, so
I'll just focus on the
[.travis.yml file](https://github.com/caindy/caindy.github.io/blob/master/.travis.yml).
I started with the
[canonical one](https://raw.githubusercontent.com/ocaml/ocaml-ci-scripts/master/.travis.yml),
which you should
[read up on](https://github.com/ocaml/ocaml-ci-scripts/blob/master/README-travis.md).
This really is where my process diverges from
[what other folks have done](http://amirchaudhry.com/unikernels-for-everyone),
so I'll give it some attention.

The main thing for me is not having a manual step in the process of publishing
my blog. There's impracticality and there's utility, and if I have to do
something besides `git push` to update my blog...

So, as mentioned earlier, we're going to have our CI build spin up an EC2
instance, the builder, to create our AMI. The main trick here is that you can
use the `cloud-init` facilities to have an EC2 instance run some code when it
boots, by passing the script in as the `--user-data` parameter. We need to get
the IAM stuff right, too, but more on that in a bit, 

Got it? After building our blog with Jekyll, we're going to run a script in our
CI build that fires up an AMI builder in EC2. We'll cover the builder script in
a bit, but I should explain here why we can't just build the AMI in Travis.

We want to use a `t2.nano` instance for the blog instance itself, because it's
so cheap (even free). Unfortunately, `t2.nano` can only run AMIs that are EBS
backed, and you can only bundle such an AMI from within an EBS backed instance.
(TODO: find they whys and wherefores about this restriction)

So, we're going to spin up a `t2.nano` running an AWS Linux AMI, because it
already has the AWS CLI tools we need to create and register our unikernel AMI 

#### Doesn't work out of the box

Had to fork the repo
https://github.com/ocaml/ocaml-ci-scripts/

`FORK_USER=caindy`
```
diff --git a/travis_mirage.ml b/travis_mirage.ml
index df0a085..d4e0065 100644
--- a/travis_mirage.ml
+++ b/travis_mirage.ml
@@ -64,7 +64,7 @@ List.iter pin pins;
 
 ?| "opam update -u";
 ?| "opam install mirage";
-?| "MODE=$MIRAGE_BACKEND mirage configure";
+?| "MODE=$MIRAGE_BACKEND make configure";
 ?| "make build";
 ?| "echo TRAVIS_BRANCH=$TRAVIS_BRANCH"
 ;;
```

`UPDATE_GCC_BINUTILS=1`


Creating a bootable AMI for instance-store backed images
Here's the [script](https://github.com/caindy/caindy.github.io/blob/instance-store/_mirage/ec2.sh)
- Create a sparse file
- Format it with a filesystem
- Mount it as a [loop device](https://en.wikipedia.org/wiki/Loop_device) 
- Put the grub info in `/boot/grub`


Travis Setup
Needed into install awscli, jekyll, and mirage stuff
Installing awscli via pip meant [apt install python-pip](https://github.com/travis-ci/travis-ci/issues/4090#issuecomment-184811689)


Make user in a group with an inline policy to write files to an S3 bucket and
put the access keys in Travis environment variables

VirtualizationType must be paravirtual since we need to use [PV-GRUB](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/UserProvidedKernels.html) to boot into our unikernel


Had to create a user [signing cert](http://docs.aws.amazon.com/AWSEC2/latest/CommandLineReference/ec2-cli-managing-certs.html?icmpid=docs_iam_console) and make available to AMI bundler

CI Role needed [PassRole](https://blogs.aws.amazon.com/security/post/Tx3M0IFB5XBOCQX/Granting-Permission-to-Launch-EC2-Instances-with-IAM-Roles-PassRole-Permission)

capture boot output 
https://alestic.com/2010/12/ec2-user-data-output/

run-instances with --key-name to allow ssh

TODO
normalize variable curly brace usage
lock down policy blog-builder-image-packing on build IAM Role

Use docker caching to make build not suck
https://github.com/travis-ci/travis-ci/issues/5358
https://pages.codeship.com/docker




