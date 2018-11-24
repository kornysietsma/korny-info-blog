#!/bin/bash
bundle exec middleman build
git add docs
git commit -m "rebuilt from middleman"
echo "don't forget to push!"
