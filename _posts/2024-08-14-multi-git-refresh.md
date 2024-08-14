---
title: Refreshing multiple git repos
categories: ['software development']
date: 2024-08-14
tags: [git, mostly-for-me]
classes: wide
toc: false
---

File under "blogging so I remember how I did this"...

I often have the situation where I have a directory full of related git repositories related to one area of work.  So I have for example `~/work/team-a/platitude-generator` and `~/work/team-a/memes` and so on.

And I just want everything up to date - especially if I come back after my non-working day or a holiday.

I used to use [a tool called gws](https://github.com/StreakyCobra/gws) to manage this, but it has a few bugs and quirks - it caches too much and I had to manually edit config files and delete caches too often.

And I did some digging and stack-overflow-browsing - I ended up just using a quite simple script.  It doesn't cache anything, it's slow as it runs `git fetch` for every repo every time, but honestly that's usually what I want anyway.

A few notes after the script.

```sh
#!/bin/bash -e

RED='\033[0;31m'
GREEN='\033[0;33m'
NC='\033[0m'

for dir in */; do
    cd "$dir" || continue

    if [ -d ".git" ]; then
        current_branch=$(git branch --show-current || "no branch")
        echo "processing $dir on $current_branch"

        status=$(git status -s | { grep -v "^?? " || true; } )

        if [ -n "$status" ]; then
            echo -e "${RED}$dir has uncommitted changes --skipping${NC}"
        else
            git fetch -q
            incoming_changes=$(git rev-list --count "..@{u}")

            echo -e "Pulling ${GREEN}$incoming_changes${NC} changes"
            git --no-pager log --pretty=format:"%h%x09%an%x09%ad%x09%s" --date=short "..@{u}"
            git pull --ff-only || rc="$?"
            if [ -n "$rc" ]; then
              echo -e "${RED}$dir fast forward failed: ${rc} ${NC}";
            fi
        fi
    else
        echo "$dir is not a git repository"
    fi

    cd ..
done

```

Notable bits:

- `status=$(git status -s | { grep -v "^?? " || true; } )` - this ignores added files.  I often have junk in repos - I don't want my update to fail because I have a log file or something kicking around!  `git pull` will fail anyway if the file is in conflict.
- I don't check against `main` - if I'm on a branch I usually want to update that branch, because that's where I'm working.  (maybe I should add a warning if `main` has un-merged changes?)
- `..@{u}` is a new-ish feature for `git log` and `git rev-list` which looks at differences between the current branch and its upstream branch.  Very handy
- `git pull --ff-only` will fail quite often, but that's OK - I want to be prompted to manually intervene if I've made local changes.
- I use `|| true` and similar because I'm running `#!/bin/bash -e` at the top, and any error will abort the script.  I find it much easier to default to failing and manually handle errors than to default to ignoring errors.
- [Shellcheck](https://www.shellcheck.net/) is my friend - I have it as a VSCode plugin and it catches most things.

I hope this is helpful to others (and to future-me).
