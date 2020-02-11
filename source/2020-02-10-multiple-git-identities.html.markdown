---
title: multiple git identities
date: 2020-02-10 08:18 GMT
tags: tech
---

This is another "I do this a lot so am blogging about it for future me" article.  There is a lot of info about this out there, but doesn't tend to be in a single place, so I'm summarizing the wisdom of others.

_Note_ this post assumes recent versions of `git` and `openssh` - and the approaches don't always work with tools that do their own git or ssh manipulation, such as IDEs; if they don't read system git/ssh configs, you might be out of luck.  (also this assumes a un*x/Mac operating system, not sure if any of this works on Windows though the same principles probably apply)

## The problem

Regularly, I want to have more than one git identity - often on the same host, such as github.  A classic example is when I was working at GDS - they have open-source code on public github repositories, but in order to keep my home git separate from my work git, I wanted to use a different ssh key and email for GDS repos than for my own.

### Problem one - ssh identity

Under the covers, when you run `git clone git@github.com:foo/bar` it actually uses `ssh` - more, it uses `ssh git@github.com` passing a public key file (typically `~/.ssh/id_rsa.pub`) as your identity.  And these tools tend to assume that "git@github.com" is one person with one identity, not some sort of Jekyll and Hyde mess.

(Note: I strongly suggest you use `ssh-agent` and `ssh-add` to store keys in the agent - but that's a digression)

### Approach one: multiple ssh host aliases
This is the easiest fix, but it does break some tools that don't understand ssh configs.

Recent openssh versions let you specify host aliases - if you set up your `~/.ssh/config` as follows:

~~~
Host github.com
  HostName github.com
  User git
  IdentityFile ~/.ssh/id_rsa

Host github.com_foobar
  HostName github.com
  User git
  IdentityFile ~/.ssh/id_rsa_foobar
~~~

Then ssh recognises `github.com_foobar` as an alias for `github.com` but with a different identity.  So `git clone git@github.com_foobar:foo/bar` will use the `id_rsa_foobar` identity file!

#### problems
The main problem here is that `github.com_foobar` doesn't exist - it's not a real host that exists in DNS.  Git understands this, but there's a chance that other tools won't look in git config, or will do a host lookup or something, and fail.  (This is happening less as more people start using ssh aliases, but it definitely still happens)

### Approach two: Overriding the ssh command
You can also tell `git` to use a different `ssh` command:

~~~
GIT_SSH_COMMAND="ssh -i ~/.ssh/id_rsa_foobar" git clone git@github.com_foobar:foo/bar
~~~

This works nicely - but you need to override the ssh command every time you interact with a remote repository.  You can set the command for a specific repository once you have a local clone with:

~~~
git config core.sshCommand "ssh -i ~/.ssh/id_rsa_foobar"
~~~

This modifies the file `.git/config` and adds a section like:

~~~
[core]
    sshCommand = ssh -i ~/.ssh/id_rsa_foobar
~~~

You can also override this for a specific directory path, in your git config - more on the per-path settings below.

#### problems
Again, many tools won't look in your git config - especially as this is quite a new git feature.  This probably works a bit less often than overriding the host - and may fail in more strange ways, at least overriding the host can give you a clear error like "no such host github.com_foobar"!  But at least it won't fail if something tries to check the host exists.

### Approach three - switching your key files around

This is probably the least recommended option, as it's fiddly and easy to get wrong.  But if all else fails, you can always store your `id_rsa_foobar` and normal `id_rsa` files somewhere outside `~/.ssh` and write scripts to copy the correct file in when you want to change identity.  Obviously this is hacky and global - and easy to forget that you changed it and didn't change it back.

### What about HTTPS URLs?

If you don't mind entering your git username and password every time, https makes this easy!

But if you want to cache the username/password, then you'll have the same problem - you'll need to fiddle around with how to get the git credential helper to cache different values depending on your repo; I haven't really played with that area so can't help you!

## Problem two - name and email in git logs

This is a more subtle problem.  Generally you want to have commit logs against your name and email, so you run something like:

~~~
git config --global user.name "Korny Sietsma"
git config --global user.email "korny@sietsma.com"
~~~

But then when you push to a repo you cloned as "Fnordo the Terrible", it will still see that global config and your commit logs will have "Korny Sietsma" all over them.  (Note there are ways to retrospectively fix that, but they are very fiddly)

You can set the same config locally on each repo:

~~~
git config --local user.name "Fnordo the Terrible"
git config --global user.email "terrible@foobar.com"
~~~

but you need to remember this for every repo.

An alternative with recent git versions is, you can edit the global git config and add _per directory settings_ - put something like this in `~/.gitconfig` :

~~~
[user]
    name = Korny Sietsma
    email = korny@sietsma.com
[includeIf "gitdir:~/projects/foobar/"]
    path = ~/projects/foobar/custom_gitconfig
~~~

and then in the file `~/projects/foobar/custom_gitconfig` you can provide overrides _which apply for any git project under `~/projects/foobar/` !_

~~~
[user]
    name = Fnordo the Terrible
    email = terrible@foobar.com
~~~

This trick also applies to ssh settings - you can add a core.sshCommand as described above to your custom git config.

**Note** however this config applies to git repositories under `~/projects/foobar` - but not to arbitrary directories not yet in git.  So if you CD to `~/projects/foobar/` and then run `git clone` it won't be smart enough to clone with an overridden ssh command.

## Bonus prize - other per-directory configurations

Once you can set git config per directory tree, there are some very handy things you can do.

For instance, I like to set a default git commit template - especially if you are pair or mob programming, it's good to add `<Co-authored-by>` tags at the end. [Github understands these and will show all listed people as authors.](https://help.github.com/en/github/committing-changes-to-your-project/creating-a-commit-with-multiple-authors) Apparently [GitLab supports these as well](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/17919). If you are interested there are also a [number of other similar conventions](https://git.wiki.kernel.org/index.php/CommitMessageConventions) - but don't go overboard!

It's also worth reading [Chris Beams' article](https://chris.beams.io/posts/git-commit/) on how to write a good commit message.  This is much easier if you have a template to work from!

You can do this by setting the `commit.template` config setting to point to a template file - and you can do this in your per-project include file:

~~~
[commit]
        template = ~/projects/foobar/commit_template.txt
~~~

Then make a template file like:
~~~
GTFO-XXXX Change description

more details

Co-authored-by: Fnordo the Terrible <terrible@foobar.com>
Co-authored-by: Siobhan the Unpronounceable <siobhan@foobar.com>
~~~

You can even write your own scripts to build these templates yourself.

The possibilities of per-directory git config are endless - you can also set up project-level pre-commit or other hooks in a similar way.  (Hooks are also great for making sure you format commit messages correctly! But that's a whole different subject)

## Problem 3 - web browser identity

There are still some headaches with multiple git identites if you use a web browser to open https://github.com and don't remember who you are logged in as.  Github (and other git hosts) have all sorts of UI tools for commits, PRs etc., and they will identify you by your current browser cookies.

My preferred approach here is to set up my browser with multiple segregated sandboxes - I'm not going to go into all the details here, but take a look at [Profiles](https://support.google.com/chrome/answer/2364824) if you are using Google Chrome, or [Multi-account containers](https://addons.mozilla.org/en-GB/firefox/addon/multi-account-containers/) if you are using FireFox.  Both of these let you keep one set of browser tabs logged in as your private identity, and one as your work identity.  

They are also great for walling off apps like Facebook from other websites.  If only one profile is logged in on Facebook, other profiles won't be leaking identity accidentally.

I hope this is useful to people out there - feel free to comment below!
