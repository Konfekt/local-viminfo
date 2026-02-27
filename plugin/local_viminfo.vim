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

if &compatible || exists('g:loaded_viminfo') | finish | endif

" From https://www.reddit.com/r/vim/comments/povbkh/tip_viminfo_per_project/
" Default to global viminfo if no local viminfo found.
" Start with global viminfo if local viminfo is empty.
" Respect &viminfofile if set explicitly, in particular by -i command-line
" flag, by setting viminfo file path in &viminfo instead of &viminfofile.

let s:is_nvim = has('nvim')

" Compute default and effective global locations.
if s:is_nvim
  let s:default_global_viminfofile = stdpath('state') .. '/shada/main.shada'
  let s:global_viminfofile = matchstr(&shada, '\%(^\|,\)n\zs[^,]*')
  if empty(s:global_viminfofile)
    let s:global_viminfofile = s:default_global_viminfofile
    let &shada .= (empty(&shada) ? '' : ',') .. 'n' .. s:global_viminfofile
  endif
else
  let s:default_global_viminfofile = expand('~') .. (has('win32') ? '/_viminfo' : '/.viminfo')
  let s:global_viminfofile = matchstr(&viminfo, '\%(^\|,\)n\zs[^,]*')
  if empty(s:global_viminfofile)
    let s:global_viminfofile = s:default_global_viminfofile
    let &viminfo .= (empty(&viminfo) ? '' : ',') .. 'n' .. s:global_viminfofile
  endif
endif

" Make Sessions respect local viminfo.
let v:this_session = ''
let s:last_session = ''
let s:local_viminfofile = ''

function! s:SeedLocalFromGlobal(localfile) abort
  if !filereadable(s:global_viminfofile) || getfsize(a:localfile) != 0
    return
  endif

  " Copy global -> local when local file is empty.
  if exists('*filecopy')
    call delete(a:localfile)
    call filecopy(s:global_viminfofile, a:localfile)
  else
    " Use libuv copy for Neovim (shada is binary).
    if s:is_nvim
      call luaeval('(vim.uv or vim.loop).fs_copyfile(_A[1], _A[2])', [s:global_viminfofile, a:localfile])
    else
      call writefile(readfile(s:global_viminfofile), a:localfile)
    endif
  endif
endfunction

function! s:VimInfoSessionLoad() abort
  let marker = s:is_nvim ? '.shada' : '.viminfo'
  let found = findfile(marker, getcwd() .. ';')
  if empty(found)
    return
  endif

  let found   = fnamemodify(found, ':p')
  let global  = fnamemodify(s:global_viminfofile, ':p')
  let default = fnamemodify(s:default_global_viminfofile, ':p')

  " Skip accidental pickup of default ~/.viminfo when a non-default global location is configured.
  if !s:is_nvim && found ==# default && global !=# default
    return
  endif

  " Skip self.
  if found ==# global | return | endif

  call s:SeedLocalFromGlobal(found)

  if found ==# s:local_viminfofile | return | endif
  let s:local_viminfofile = found

  if s:is_nvim
    let &shada = substitute(&shada, '\%(^\|,\)n\zs.*$', escape(found, '\&'), '')
    rshada
  else
    let &viminfo = substitute(&viminfo, '\%(^\|,\)n\zs.*$', escape(found, '\&'), '')
    rviminfo
  endif
endfunction

augroup viminfo
  autocmd!
  autocmd SessionLoadPost *
        \ if v:this_session !=# s:last_session |
        \   let s:last_session = v:this_session | call s:VimInfoSessionLoad() |
        \ endif
  if has('##SessionWritePost')
    if s:is_nvim
      autocmd SessionWritePost * wshada
    else
      autocmd SessionWritePost * wviminfo
    endif
  endif
augroup END

call s:VimInfoSessionLoad()

let g:loaded_viminfo = 1
