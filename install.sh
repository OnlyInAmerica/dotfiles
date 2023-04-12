#!/bin/bash

# Ensure submodules are ready
git submodule update --init --recursive

# Transfer vim and tmux settings to home dir
rsync -r \
      .vim \
      .vimrc \
      .tmux.conf \
      ~/
