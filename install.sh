#!/bin/bash

# Bootstrap lazy.nvim for Neovim plugins
LAZYPATH="${XDG_DATA_HOME:-$HOME/.local/share}/nvim/lazy/lazy.nvim"
if [ ! -d "$LAZYPATH" ]; then
      git clone --filter=blob:none https://github.com/folke/lazy.nvim.git --branch=stable "$LAZYPATH"
fi

# Transfer Neovim and tmux settings to home dir
rsync -r \
      .config \
      .tmux.conf \
      ~/
