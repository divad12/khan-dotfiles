Configuration files, and setup scripts, for Khan Academy website
developers.  A lot of what's here is Khan Academy-specific:

- Vim filetype plugins conforming to Khan Academy's style guide
- tell ack to skip crap that the deploy script litters
  (eg. combined/compressed CSS/JS files)
- Kiln authentication stuff
- a [pre-commit linter](https://github.com/Khan/khan-linter)

and the rest of it just contains generally useful things, such as

- handy `git` aliases such as `git graph`
- having `hg` pipe commands with large output to `less`
- useful Mercurial aliases and extensions such as `shelve` (similar to
  `git stash`) and `record` (similar to `git add -p && git commit`)

This is meant to complement [the dev setup on the Khan Academy Forge](https://sites.google.com/a/khanacademy.org/forge/for-khan-employees/-new-employees-onboard-doc/developer-setup).
The setup scripts here assume you have done the initial setup on that
Forge page (installing npm, etc) before running commands here.

Setup
-----
Clone this repo somewhere (I recommend into a `~/khan/devtools`
directory, but it doesn't really matter), and then run `make` in
the cloned directory:

    mkdir -p ~/khan/devtools
    cd ~/khan/devtools
    git clone git://github.com/Khan/khan-dotfiles.git
    cd khan-dotfiles
    make

This will symlink all the dotfiles in the `khan-dotfiles` directory to
your home directory.  It will not overwrite any of your existing
dotfiles but will emit a warning if it failed to symlink a file.

It will also install a lot of Python, Node.js, and other configuration files.

This script is idempotent, so it should be safe to run it multiple times.

To benefit from the `.ackrc` here, install `ack`, which is basically a
faster, more configurable `grep -r` that ignores directories like
`.git` and displays the results nicely.

Also, install [autojump](https://github.com/joelthelion/autojump) if
you're a frequent user of the terminal to navigate the filesystem.

Hello
-----
Originally extracted from [David's
dotfiles](http://github.com/divad12/dotfiles), with commits and lines
here and there stolen from [Jamie](http://github.com/phleet/dotfiles),
[Desmond](https://github.com/dmnd), and others.  Non-dotfile config
files, and the setup script, written by Craig Silverstein.

Pull requests are welcome!
