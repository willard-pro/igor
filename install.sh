#!/bin/bash

if [[ -d .git ]]; then
	echo "Installing from the source repository is not supported"
	exit 1
fi

mkdir "$HOME/.igor"

if [[ -f igor.sh ]]; then
	cp -R . "$HOME/.igor"
else
	local latest_version=$(curl -v https://github.com/willard-pro/igor/releases/latest 2>&1 | grep 'location:' | awk -F'tag/' '{print $2}')
	curl -o /tmp/igor.latest.zip -LOJ https://github.com/willard-pro/igor/releases/download/$latest_version/igor-$latest_version.zip
	unzip -o /tmp/igor.latest.zip -d $HOME/.igor
fi

echo -e "\e[33mThis script requires sudo permissions to make Igor availabl on the command line path\e[0m"
sudo echo "Thank you for granting sudo permissions."

sudo ln -s "$HOME/.igor/igor.sh" /usr/local/bin/igor

echo -e "Igor is now installed and available on the CLI.  Type \e[1migor\e[0m and hit enter to get started."