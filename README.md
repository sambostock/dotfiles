# dotfiles

Repo for settings, configurations, and other dotfiles.

## Installation

### Git

Prepend `~/.gitconfig` with the following:

    [include]
            path = <path to dotfiles repo>/git/gitconfig

and create the symbolic link `~/.config/git/ignore` pointing to
`<path to dotfiles repo>/git/gitignore`
