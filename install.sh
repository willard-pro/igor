#!/bin/bash

if [[ -d .git ]]; then
	echo "Installing from the source repository is not supported"
	exit 1
fi

if [[ -d igor.sh ]]; then
	echo "Igor has already been installed"
	exit 1
fi

mkdir "$HOME/.igor"

if [[ -f igor.sh ]]; then
	cp -R . "$HOME/.igor"
else
	curl -o /tmp/igor.latest.zip -LOJ https://github.com/willard-pro/igor/archive/refs/heads/main.zip
	unzip -o /tmp/igor.latest.zip -d "$HOME/.igor"
fi

rm "$HOME/.igor/install.sh"

echo "This script requires sudo permissions to place Igor on the command line path"
sudo echo "Thank you for granting sudo permissions."

sudo ln -s "$HOME/.igor/igor.sh" /usr/local/bin/igor

echo "Igor is now installed and available on the CLI.  Type igor and hit enter to get started."