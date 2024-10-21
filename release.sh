#!/bin/sh

set -e

printf "\033[0;32mDeploying to Github!..\033[0m\n"
hugo
git add .
git commit -am "up content"
git push
