#!/bin/bash
bundle exec middleman build
git add docs
echo "don't forget to commit and push!"
