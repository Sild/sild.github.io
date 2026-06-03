#!/bin/sh

set -e

printf "\033[0;32mDeploying to Github!..\033[0m\n"
hugo --cleanDestinationDir
git add .
git commit -m "site: update content"
git push
