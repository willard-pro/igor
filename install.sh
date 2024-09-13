#!/bin/bash

if [[ -d .git ]]; then
	echo "Installing from the source repository is not supported"
	exit 1
fi

mkdir "$HOME/.igor"

if [[ -f igor.sh ]]; then
	cp -R . "$HOME/.igor"
else
	curl -o /tmp/igor.latest.zip -LOJ https://github.com/willard-pro/igor/archive/refs/heads/main.zip
	unzip -o /tmp/igor.latest.zip -d $HOME/.igor
	mv $HOME/.igor/igor-main/* $HOME/.igor/

	rm -rf $HOME/.igor/igor-main
	rm -rf $HOME/.igor/.github
fi

rm $HOME/.igor/install.sh

echo -e "\e[33mThis script requires sudo permissions to make Igor availabl on the command line path\e[0m"
sudo echo "Thank you for granting sudo permissions."

sudo ln -s "$HOME/.igor/igor.sh" /usr/local/bin/igor

echo -e "Igor is now installed and available on the CLI.  Type \e[1migor\e[0m and hit enter to get started."