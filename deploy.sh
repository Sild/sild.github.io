#!/bin/sh

set -e

printf "\033[0;32mDeploying to Github!..\033[0m\n"

msg="rebuilding site $(date)"
if [ -n "$*" ]; then
	msg="$*"
fi

echo ""
echo ""
echo "Commit changes to $(pwd)"
hugo -D

cd public

echo ""
echo ""
echo "Commit changes to $(pwd)"
git add .
git commit -m "$msg"
git push origin

cd ..
echo ""
echo ""
echo "Commit changes to $(pwd)"
git add .
git commit -m "$msg"
git push origin
