# Blot Vim Plugin

A Vim plugin that integrates the [Blot](https://github.com/joaotavora/blot) assembly viewer with Vim for C++ development.

## Features

- Display assembly output in a split window alongside your C++ source
- Highlight source-to-assembly line mappings
- Automatic blot executable detection
- Configurable key mappings

## Installation

### Using vim-plug

Add to your `.vimrc`:

```vim
Plug '/path/to/blot/vim'
```

### Manual Installation

Copy the `vim/` directory contents to your Vim configuration directory:

```bash
cp -r vim/* ~/.vim/
```

### Using Pathogen

```bash
cd ~/.vim/bundle
ln -s /path/to/blot/vim blot
```

## Usage

### Commands

- `:BlotShowAssembly` - Generate and display assembly for the current C++ file
- `:BlotHighlight` - Highlight assembly lines corresponding to current source line
- `:BlotClose` - Close the assembly buffer

### Default Key Mappings

- `<leader>ba` - Show assembly
- `<leader>bh` - Highlight current line mappings
- `<leader>bc` - Close assembly buffer

## Configuration

### Variables

```vim
" Set custom blot executable path (default: 'blot')
let g:blot_executable = '/path/to/blot'

" Set build directory for local blot executable (default: 'build-Debug')
let g:blot_build_dir = 'build-Release'

" Disable default key mappings
let g:blot_no_mappings = 1

" Enable auto-highlighting when cursor moves (experimental)
let g:blot_auto_highlight = 1
```

### Custom Key Mappings

```vim
" Disable default mappings
let g:blot_no_mappings = 1

" Set your own mappings
nnoremap <F5> :BlotShowAssembly<CR>
nnoremap <F6> :BlotHighlight<CR>
nnoremap <F7> :BlotClose<CR>
```

## How It Works

1. The plugin runs `blot --json <filename>` on the current C++ file
2. Parses the JSON output containing assembly lines and line mappings
3. Creates a new buffer with assembly syntax highlighting
4. Provides commands to highlight corresponding assembly lines

## Requirements

- Vim with JSON support (Vim 8.0+ or Neovim)
- Built blot executable (either in project `build-Debug/` or in PATH)
- C++ project with `compile_commands.json` (for blot to work)

## Troubleshooting

- **"Blot executable not found"**: Ensure blot is built or set `g:blot_executable`
- **"Blot failed"**: Check that your C++ file is in a project with `compile_commands.json`
- **No assembly output**: Verify the file compiles successfully with your build system