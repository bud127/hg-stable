
copy: tests/test-revert-unknown
copyrev: 6449f8675520ccfffa01229e222e1a914e66c72c

  $ hg init
  $ touch unknown

  $ touch a
  $ hg add a
  $ hg ci -m "1" -d "1000000 0"

  $ touch b
  $ hg add b
  $ hg ci -m "2" -d "1000000 0"

Should show unknown

  $ hg status
  ? unknown
  $ hg revert -r 0 --all
  removing b

Should show unknown and b removed

  $ hg status
  R b
  ? unknown

Should show a and unknown

  $ ls
  a
  unknown
