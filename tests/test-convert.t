  $ "$TESTDIR/hghave" unix-permissions || exit 80

  $ cat >> $HGRCPATH <<EOF
  > [extensions]
  > convert=
  > [convert]
  > hg.saverev=False
  > EOF
  $ hg help convert
  hg convert [OPTION]... SOURCE [DEST [REVMAP]]
  
  convert a foreign SCM repository to a Mercurial one.
  
      Accepted source formats [identifiers]:
  
      - Mercurial [hg]
      - CVS [cvs]
      - Darcs [darcs]
      - git [git]
      - Subversion [svn]
      - Monotone [mtn]
      - GNU Arch [gnuarch]
      - Bazaar [bzr]
      - Perforce [p4]
  
      Accepted destination formats [identifiers]:
  
      - Mercurial [hg]
      - Subversion [svn] (history on branches is not preserved)
  
      If no revision is given, all revisions will be converted. Otherwise,
      convert will only import up to the named revision (given in a format
      understood by the source).
  
      If no destination directory name is specified, it defaults to the basename
      of the source with "-hg" appended. If the destination repository doesn't
      exist, it will be created.
  
      By default, all sources except Mercurial will use --branchsort. Mercurial
      uses --sourcesort to preserve original revision numbers order. Sort modes
      have the following effects:
  
      --branchsort  convert from parent to child revision when possible, which
                    means branches are usually converted one after the other.
                    It generates more compact repositories.
      --datesort    sort revisions by date. Converted repositories have good-
                    looking changelogs but are often an order of magnitude
                    larger than the same ones generated by --branchsort.
      --sourcesort  try to preserve source revisions order, only supported by
                    Mercurial sources.
  
      If "REVMAP" isn't given, it will be put in a default location
      ("<dest>/.hg/shamap" by default). The "REVMAP" is a simple text file that
      maps each source commit ID to the destination ID for that revision, like
      so:
  
        <source ID> <destination ID>
  
      If the file doesn't exist, it's automatically created. It's updated on
      each commit copied, so "hg convert" can be interrupted and can be run
      repeatedly to copy new commits.
  
      The authormap is a simple text file that maps each source commit author to
      a destination commit author. It is handy for source SCMs that use unix
      logins to identify authors (eg: CVS). One line per author mapping and the
      line format is:
  
        source author = destination author
  
      Empty lines and lines starting with a "#" are ignored.
  
      The filemap is a file that allows filtering and remapping of files and
      directories. Each line can contain one of the following directives:
  
        include path/to/file-or-dir
  
        exclude path/to/file-or-dir
  
        rename path/to/source path/to/destination
  
      Comment lines start with "#". A specified path matches if it equals the
      full relative name of a file or one of its parent directories. The
      "include" or "exclude" directive with the longest matching path applies,
      so line order does not matter.
  
      The "include" directive causes a file, or all files under a directory, to
      be included in the destination repository, and the exclusion of all other
      files and directories not explicitly included. The "exclude" directive
      causes files or directories to be omitted. The "rename" directive renames
      a file or directory if it is converted. To rename from a subdirectory into
      the root of the repository, use "." as the path to rename to.
  
      The splicemap is a file that allows insertion of synthetic history,
      letting you specify the parents of a revision. This is useful if you want
      to e.g. give a Subversion merge two parents, or graft two disconnected
      series of history together. Each entry contains a key, followed by a
      space, followed by one or two comma-separated values:
  
        key parent1, parent2
  
      The key is the revision ID in the source revision control system whose
      parents should be modified (same format as a key in .hg/shamap). The
      values are the revision IDs (in either the source or destination revision
      control system) that should be used as the new parents for that node. For
      example, if you have merged "release-1.0" into "trunk", then you should
      specify the revision on "trunk" as the first parent and the one on the
      "release-1.0" branch as the second.
  
      The branchmap is a file that allows you to rename a branch when it is
      being brought in from whatever external repository. When used in
      conjunction with a splicemap, it allows for a powerful combination to help
      fix even the most badly mismanaged repositories and turn them into nicely
      structured Mercurial repositories. The branchmap contains lines of the
      form:
  
        original_branch_name new_branch_name
  
      where "original_branch_name" is the name of the branch in the source
      repository, and "new_branch_name" is the name of the branch is the
      destination repository. No whitespace is allowed in the branch names. This
      can be used to (for instance) move code in one repository from "default"
      to a named branch.
  
      Mercurial Source
      ''''''''''''''''
  
      The Mercurial source recognizes the following configuration options, which
      you can set on the command line with "--config":
  
      convert.hg.ignoreerrors
                    ignore integrity errors when reading. Use it to fix
                    Mercurial repositories with missing revlogs, by converting
                    from and to Mercurial. Default is False.
      convert.hg.saverev
                    store original revision ID in changeset (forces target IDs
                    to change). It takes a boolean argument and defaults to
                    False.
      convert.hg.startrev
                    convert start revision and its descendants. It takes a hg
                    revision identifier and defaults to 0.
  
      CVS Source
      ''''''''''
  
      CVS source will use a sandbox (i.e. a checked-out copy) from CVS to
      indicate the starting point of what will be converted. Direct access to
      the repository files is not needed, unless of course the repository is
      ":local:". The conversion uses the top level directory in the sandbox to
      find the CVS repository, and then uses CVS rlog commands to find files to
      convert. This means that unless a filemap is given, all files under the
      starting directory will be converted, and that any directory
      reorganization in the CVS sandbox is ignored.
  
      The following options can be used with "--config":
  
      convert.cvsps.cache
                    Set to False to disable remote log caching, for testing and
                    debugging purposes. Default is True.
      convert.cvsps.fuzz
                    Specify the maximum time (in seconds) that is allowed
                    between commits with identical user and log message in a
                    single changeset. When very large files were checked in as
                    part of a changeset then the default may not be long enough.
                    The default is 60.
      convert.cvsps.mergeto
                    Specify a regular expression to which commit log messages
                    are matched. If a match occurs, then the conversion process
                    will insert a dummy revision merging the branch on which
                    this log message occurs to the branch indicated in the
                    regex. Default is "{{mergetobranch ([-\w]+)}}"
      convert.cvsps.mergefrom
                    Specify a regular expression to which commit log messages
                    are matched. If a match occurs, then the conversion process
                    will add the most recent revision on the branch indicated in
                    the regex as the second parent of the changeset. Default is
                    "{{mergefrombranch ([-\w]+)}}"
      hook.cvslog   Specify a Python function to be called at the end of
                    gathering the CVS log. The function is passed a list with
                    the log entries, and can modify the entries in-place, or add
                    or delete them.
      hook.cvschangesets
                    Specify a Python function to be called after the changesets
                    are calculated from the the CVS log. The function is passed
                    a list with the changeset entries, and can modify the
                    changesets in-place, or add or delete them.
  
      An additional "debugcvsps" Mercurial command allows the builtin changeset
      merging code to be run without doing a conversion. Its parameters and
      output are similar to that of cvsps 2.1. Please see the command help for
      more details.
  
      Subversion Source
      '''''''''''''''''
  
      Subversion source detects classical trunk/branches/tags layouts. By
      default, the supplied "svn://repo/path/" source URL is converted as a
      single branch. If "svn://repo/path/trunk" exists it replaces the default
      branch. If "svn://repo/path/branches" exists, its subdirectories are
      listed as possible branches. If "svn://repo/path/tags" exists, it is
      looked for tags referencing converted branches. Default "trunk",
      "branches" and "tags" values can be overridden with following options. Set
      them to paths relative to the source URL, or leave them blank to disable
      auto detection.
  
      The following options can be set with "--config":
  
      convert.svn.branches
                    specify the directory containing branches. The default is
                    "branches".
      convert.svn.tags
                    specify the directory containing tags. The default is
                    "tags".
      convert.svn.trunk
                    specify the name of the trunk branch. The default is
                    "trunk".
  
      Source history can be retrieved starting at a specific revision, instead
      of being integrally converted. Only single branch conversions are
      supported.
  
      convert.svn.startrev
                    specify start Subversion revision number. The default is 0.
  
      Perforce Source
      '''''''''''''''
  
      The Perforce (P4) importer can be given a p4 depot path or a client
      specification as source. It will convert all files in the source to a flat
      Mercurial repository, ignoring labels, branches and integrations. Note
      that when a depot path is given you then usually should specify a target
      directory, because otherwise the target may be named "...-hg".
  
      It is possible to limit the amount of source history to be converted by
      specifying an initial Perforce revision:
  
      convert.p4.startrev
                    specify initial Perforce revision (a Perforce changelist
                    number).
  
      Mercurial Destination
      '''''''''''''''''''''
  
      The following options are supported:
  
      convert.hg.clonebranches
                    dispatch source branches in separate clones. The default is
                    False.
      convert.hg.tagsbranch
                    branch name for tag revisions, defaults to "default".
      convert.hg.usebranchnames
                    preserve branch names. The default is True.
  
  options:
  
   -s --source-type TYPE source repository type
   -d --dest-type TYPE   destination repository type
   -r --rev REV          import up to target revision REV
   -A --authormap FILE   remap usernames using this file
      --filemap FILE     remap file names using contents of file
      --splicemap FILE   splice synthesized history into place
      --branchmap FILE   change branch names while converting
      --branchsort       try to sort changesets by branches
      --datesort         try to sort changesets by date
      --sourcesort       preserve source changesets order
  
  use "hg -v help convert" to show more info
  $ hg init a
  $ cd a
  $ echo a > a
  $ hg ci -d'0 0' -Ama
  adding a
  $ hg cp a b
  $ hg ci -d'1 0' -mb
  $ hg rm a
  $ hg ci -d'2 0' -mc
  $ hg mv b a
  $ hg ci -d'3 0' -md
  $ echo a >> a
  $ hg ci -d'4 0' -me
  $ cd ..
  $ hg convert a 2>&1 | grep -v 'subversion python bindings could not be loaded'
  assuming destination a-hg
  initializing destination a-hg repository
  scanning source...
  sorting...
  converting...
  4 a
  3 b
  2 c
  1 d
  0 e
  $ hg --cwd a-hg pull ../a
  pulling from ../a
  searching for changes
  no changes found
  $ touch bogusfile

should fail

  $ hg convert a bogusfile
  initializing destination bogusfile repository
  abort: cannot create new bundle repository
  [255]
  $ mkdir bogusdir
  $ chmod 000 bogusdir

should fail

  $ hg convert a bogusdir
  abort: Permission denied: bogusdir
  [255]

should succeed

  $ chmod 700 bogusdir
  $ hg convert a bogusdir
  initializing destination bogusdir repository
  scanning source...
  sorting...
  converting...
  4 a
  3 b
  2 c
  1 d
  0 e

test pre and post conversion actions

  $ echo 'include b' > filemap
  $ hg convert --debug --filemap filemap a partialb | \
  >     grep 'run hg'
  run hg source pre-conversion action
  run hg sink pre-conversion action
  run hg sink post-conversion action
  run hg source post-conversion action

converting empty dir should fail "nicely

  $ mkdir emptydir

override $PATH to ensure p4 not visible; use $PYTHON in case we're
running from a devel copy, not a temp installation

  $ PATH="$BINDIR" $PYTHON "$BINDIR"/hg convert emptydir
  assuming destination emptydir-hg
  initializing destination emptydir-hg repository
  emptydir does not look like a CVS checkout
  emptydir does not look like a Git repository
  emptydir does not look like a Subversion repository
  emptydir is not a local Mercurial repository
  emptydir does not look like a darcs repository
  emptydir does not look like a monotone repository
  emptydir does not look like a GNU Arch repository
  emptydir does not look like a Bazaar repository
  cannot find required "p4" tool
  abort: emptydir: missing or unsupported repository
  [255]

convert with imaginary source type

  $ hg convert --source-type foo a a-foo
  initializing destination a-foo repository
  abort: foo: invalid source repository type
  [255]

convert with imaginary sink type

  $ hg convert --dest-type foo a a-foo
  abort: foo: invalid destination repository type
  [255]

testing: convert must not produce duplicate entries in fncache

  $ hg convert a b
  initializing destination b repository
  scanning source...
  sorting...
  converting...
  4 a
  3 b
  2 c
  1 d
  0 e

contents of fncache file:

  $ cat b/.hg/store/fncache | sort
  data/a.i
  data/b.i

test bogus URL

  $ hg convert -q bzr+ssh://foobar@selenic.com/baz baz
  abort: bzr+ssh://foobar@selenic.com/baz: missing or unsupported repository
  [255]
