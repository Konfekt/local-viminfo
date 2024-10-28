" If you work on more than one (git) project, say those of Vim and Linux, then
" you may wish to keep their file histories, bookmarks, command histories ... separate. 
" This can be achieved with separate viminfo files, by adding this snippet to your vimrc and
" a .viminfo inside your repository that, if empty, will be initially replaced by
" your current one. Then at the start of a Vim session, the viminfo file of the
" current work dir is loaded.

" Save as ~/.vim/plugin/viminfo.vim to enable a project/repo-local viminfo by `touch .viminfo/shada`.
" Add .viminfo/shade to .git/info/exclude (maybe best in the git template) to avoid cluttering git status.

" In Neovim, according to :help shada-file-name the default path is
" Unix:     "$XDG_STATE_HOME/nvim/shada/main.shada"
" Windows:  "$XDG_STATE_HOME/nvim-data/shada/main.shada"
"
" To use the same directory on both OS's, add the following line to your init.vim:
" if empty($XDG_STATE_HOME) | let $XDG_STATE_HOME = $HOME..'/.local/state' | endif
" if !isdirectory(expand($XDG_STATE_HOME)) | call mkdir(expand($XDG_STATE_HOME), 'p') | endif
" let &shada .= ',n'..$XDG_STATE_HOME..'/nvim/shada/main.shada'

" In Vim, according to :help viminfo-file-name the default path is
"
" - "$HOME/.viminfo" for Unix,
" - "$HOME\_viminfo" for Win32, and
" - s:.viminfo" for Amiga.
"
" To use XDG Base Directory Specification, add the following lines to your
" vimrc:
" if empty($XDG_STATE_HOME) | let $XDG_STATE_HOME = $HOME..'/.local/state' | endif
" if !isdirectory(expand($XDG_STATE_HOME)) | call mkdir(expand($XDG_STATE_HOME), 'p') | endif
" let &viminfo .= ',n'..$XDG_STATE_HOME..'/vim/viminfo'

if &compatible || exists('g:loaded_viminfo')
    finish
endif

" From https://www.reddit.com/r/vim/comments/povbkh/tip_viminfo_per_project/
" Default to global viminfo if no local viminfo found.
" Start with global viminfo if local viminfo is empty.
" Respect &viminfofile if set explicitly, in particular by -i command-line
" flag, by setting viminfo file path in &viminfo instead of &viminfofile.

if has('nvim')
  let s:global_viminfofile = matchstr(&shada, ',n\zs\f\+$')
  if empty('s:global_viminfofile')
    let s:global_viminfofile = stdpath("state")..'/nvim'..(has('win32') ? '-data' : '')..'/shada/main.shada'
    let &shada   .= (empty(&shada) ? '' : ',')..'n'..s:global_viminfofile
  endif
else
  let s:global_viminfofile = matchstr(&viminfo, ',n\zs\f\+$')
  if empty('s:global_viminfofile')
    let s:global_viminfofile = $HOME .. has('win32') ? '/_viminfo' : '/.viminfo'
    let &viminfo .= (empty(&viminfo) ? '' : ',')..'n'..s:global_viminfofile
  endif
endif

" Make Sessions respect local viminfo.
" Since view session files do not set v:this_session and keep the global
" current working directory, we skip those for reloading viminfo.
let v:this_session = ''
let s:last_session = ''

augroup viminfo
  autocmd!
  autocmd SessionLoadPost *
        \ if v:this_session !=# s:last_session |
        \   let s:last_session = v:this_session | call s:VimInfoSessionLoad() |
        \ endif
  if has('##SessionWritePost')
    if has('nvim')
      autocmd SessionWritePost * wshada
    else
      autocmd SessionWritePost * wviminfo
    endif
  endif
augroup END

let s:last_local_viminfofile = ''
let s:local_viminfofile= ''
function! s:VimInfoSessionLoad()
  if has('nvim')
    let s:local_viminfofile = findfile('.shada', getcwd(-1)..';')
  else
    let s:local_viminfofile = findfile('.viminfo', getcwd(-1)..';')
  endif
  if empty(s:local_viminfofile)
    return
  endif
  if getfsize(s:local_viminfofile) == 0 && exists('*filecopy')
    call delete(s:local_viminfofile)
    call filecopy(s:global_viminfofile, s:local_viminfofile)
  endif
  if s:local_viminfofile !=# s:last_local_viminfofile
    let s:last_local_viminfofile = s:local_viminfofile
    if has('nvim')
      let &shada = substitute(&shada, '\%(^\|,\)n\zs.*$', escape(s:local_viminfofile, '\'), '')
      rshada
    else
      let &viminfo = substitute(&viminfo, '\%(^\|,\)n\zs.*$', escape(s:local_viminfofile, '\'), '')
      rviminfo
    endif
  endif
endfunction
call s:VimInfoSessionLoad()

let g:loaded_viminfo = 1
