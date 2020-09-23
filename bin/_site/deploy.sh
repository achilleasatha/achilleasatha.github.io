#!/usr/bin/env sh

echo "starting to build site"

# build site files in website
bundle exec jekyll build
git add -A
git commit -m 'updating site'
git push origin gh-pages

# copy files into serving site folder
#cp -r _site/* ../username.github.io

# move to serving folder
#cd ../username.github.io
git add -A
git commit -m 'updating site'
git push origin gh-pages

echo "finished building site"