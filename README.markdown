Dotfiles for Khan Academy website developers. Originally extracted from [David's dotfiles](http://github.com/divad12/dotfiles), with commits and lines here and there stolen from [Jamie](http://github.com/phleet/dotfiles), [Desmond](https://github.com/dmnd), and others.

A lot of what's here is Khan Academy-specific:

- Vim filetype plugins conforming to Khan Academy's style guide
- tell ack to skip crap that the deploy script litters (eg. combined/compressed CSS/JS files)
- Kiln authentication stuff
- a [JS pre-commit linter](https://github.com/benkomalo/khan-linter)

and the rest of it just contains generally useful things, such as

- having `hg` pipe commands with large output to `less`
- useful Mercurial aliases and extensions such as `shelve` (similar to `git stash`) and `record` (similar to `git add -p && git commit`)
- handy `git` aliases such as `git graph`

This is meant to complement [the dev setup on the Khan Academy Forge](https://sites.google.com/a/khanacademy.org/forge/for-khan-employees/-new-employees-onboard-doc/developer-setup).

Setup
-----
Clone this repo and then run `make` in the cloned directory.

    git clone git://github.com/divad12/khan-dotfiles.git
    cd khan-dotfiles
    make

This will symlink all the dotfiles in the `khan-dotfiles` directory to your home directory. It will not overwrite any of your existing dotfiles but will emit a warning if it failed to symlink a file.

Have a look through the `.hgrc` to try out what the aliases and extensions do, and continue with the rest of the [developer setup](https://sites.google.com/a/khanacademy.org/forge/for-khan-employees/-new-employees-onboard-doc/developer-setup) to install some scripts that the `.hgrc` here relies on.

To benefit from the `.ackrc` here, install `ack`, which is basically a faster, more configurable `grep -r` that ignores directories like `.git` and displays the results nicely.

Also, install [autojump](https://github.com/joelthelion/autojump) if you're a frequent user of the terminal to navigate the filesystem.

TODO(david): Automate all this in the Makefile.

Hello
-----
It's 3 am and I need to sleep so I can wake up and help our four interns starting later this morning to get set up, so there's a lot of stuff missing. Pull requests are welcome!
