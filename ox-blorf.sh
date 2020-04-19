#!/usr/bin/env sh
export HUGO_DEFAULT_FILE="$1"
export HUGO_BASE_DIR="$2"
emacs -Q --batch --load ./ox-blorf.el
