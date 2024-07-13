#!/bin/bash

curl -o $TMPDIR/igor.latest.zip -LOJ https://github.com/willard-pro/igor/archive/refs/heads/main.zip
unzip -o $TMPDIR/igor.latest.zip -d "$HOME/.igor"

ln -s "$HOME/.igor/igor.sh" /usr/local/bin/igor
