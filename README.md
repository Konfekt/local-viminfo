If you work on more than one (git) project, say those of (Neo)Vim and Linux, then you may wish to keep their file / command / search histories, bookmarks, ... separate. 
<!-- Once this plugin is installed, that is, , you can enable a project/repo-local viminfo by `touch .viminfo` (respectively `touch .shada`): -->
This can be achieved in Vim (respectively Neovim) with (repo-)local viminfo (respectively shada) files, by

1. installing once and for all this plug-in (that is, put `plugin/viminfo.vim` into your `&runtime` path, say `~/.vim`) and
1. adding a `.viminfo` (respectively `.shada`) file in (the root folder of) your repository that, if empty, will be initially replaced by your current one (so that `touch .viminfo` would branch off the repo-local history from your current global one).

Now at the start of a (Neo)Vim session, if present, the viminfo file of the current work dir is loaded (and otherwise the usual, global, viminfo).

To avoid cluttering git status, add a line reading

```
/.viminfo
```

(respectively `.shada`) to `.git/info/exclude` (and maybe directly in the git template folder).

# Default Shada

In Neovim, according to `:help shada-file-name` the default path of the shada file is

- Unix:     `"$XDG_STATE_HOME/nvim/shada/main.shada"`
- Windows:  `"$XDG_STATE_HOME/nvim-data/shada/main.shada"`

To use the same directory on both OS's, add the following line to your Vimrc:

```vim
if empty($XDG_STATE_HOME) | let $XDG_STATE_HOME = $HOME..'/.local/state' | endif
if !isdirectory(expand($XDG_STATE_HOME)) | call mkdir(expand($XDG_STATE_HOME), 'p') | endif
let &shada .= ',n'..$XDG_STATE_HOME..'/nvim/shada/main.shada'
```

# Default Viminfo

In Vim, according to `:help viminfo-file-name` the default path is

- `"$HOME/.viminfo"` for Unix,
- `"$HOME\_viminfo"` for Win32, and
- `s:.viminfo` for Amiga.

To use the XDG Base Directory Specification, add the following lines to your
vimrc:

```vim
if empty($XDG_STATE_HOME) | let $XDG_STATE_HOME = $HOME..'/.local/state' | endif
if !isdirectory(expand($XDG_STATE_HOME)) | call mkdir(expand($XDG_STATE_HOME), 'p') | endif
let &viminfo .= ',n'..$XDG_STATE_HOME..'/vim/viminfo'
```

# History

This plug-in expands [this hint](https://www.reddit.com/r/vim/comments/povbkh/tip_viminfo_per_project/) by

- Defaulting to the global viminfo (set by the ending of `,n` in `&viminfo` respectively `&shada`) if no local viminfo found.
- Starting with the global viminfo if local viminfo is empty.
- Respecting &viminfofile if set explicitly, in particular by -i command-line flag, by setting viminfo file path in &viminfo instead of &viminfofile.

# Add-On

A great companion is [vim-addon-local-vimrc](https://github.com/MarcWeber/vim-addon-local-vimrc/) for finer control of your vim settings per project.
