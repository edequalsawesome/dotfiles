#!/bin/sh
# Swap tmux prefix based on SSH status
# Called by client-attached hook so prefix adapts per-attach
if [ -n "$SSH_CONNECTION" ]; then
  tmux set -g prefix C-a
  tmux unbind C-Space
  tmux bind C-a send-prefix
else
  tmux set -g prefix C-Space
  tmux unbind C-a
  tmux bind C-Space send-prefix
fi
