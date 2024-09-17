#!/bin/bash

update=false

if [[ -d .git ]]; then
	echo "Installing from the source repository is not supported."
	exit 1
fi

if [[ -d "$HOME/.igor" ]]; then
	update=true
else
	mkdir "$HOME/.igor"
fi

if [[ -f igor.sh ]]; then
	cp -R . "$HOME/.igor"
else
	latest_version=$(curl -v https://github.com/willard-pro/igor/releases/latest 2>&1 | grep 'location:' | awk -F'tag/' '{print $2}' | tr -d '\r\n')
	curl -o /tmp/igor.latest.zip -LOJ https://github.com/willard-pro/igor/releases/download/${latest_version}/igor-${latest_version}.zip

	if [[ $? -ne 0 ]]; then
		echo -e "\e[31mFailed to download the latest version of Igor.  Please try again later...\e[0m"
		exit 1
	else
		unzip -o /tmp/igor.latest.zip -d $HOME/.igor
	fi
fi

if [[ $? -ne 0 ]]; then
	echo "\e[31mFailed to extract the latest version of Igor.  Please re-run the script and try again...\e[0m"
	exit 1
else
	echo -e "\e[33mThis script requires sudo permissions to make Igor availabl on the command line path\e[0m"
	sudo echo "Thank you for granting sudo permissions."

	sudo ln -s "$HOME/.igor/igor.sh" /usr/local/bin/igor

	echo -e "Igor is now installed and available on the CLI.  Type \e[1migor\e[0m and hit enter to get started."
fi