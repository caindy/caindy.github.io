

*nix has a `/dev/zero` that you can read ANSI NUL from as long as you need. Combined with the `dd` command, you can create a file of any size you like, e.g.
`dd if=/dev/zero of=myfile bs=1M count=5`

`dd` also allows you to create sparse files by seeking to the appropriate size, e.g.
`dd if=/dev/null of=mysparse seek=1M count=0`

When I was building tests for a file synchronization app for Windows, I used
this `fsutil` to create sparse files. These kinds of files are created almost
instantly since there are really just metadata written to the filesystem index.
