---
title: Custom URI schemes in Obisidian (on a mac)
categories: ['entertainment']
date: 2024-09-06
tags: [mac, obsidian, mpd, platypus, mostly-for-me]
toc: false
---
My youngest child started school this week, so I have a bit of time for blogging!

This is another "a neat hack that I'm sharing partly so I remember how I did it in the future"...

## The problem

Basically, I have a big ripped mp3 music collection I play using the venerable [MPD Music Player Daemon](https://www.musicpd.org/) system.  I can play tracks and playlists fine with MPD-compatible applications, but I quite often want to listen to and browse music based on albums not tracks.  I want "these are my favourite albums" and "these are recent ones I'm still learning" and the like.

Fundamentally mp3 tags are not set up for this - especially for ratings, as the support for rating tags is (a) based on individual files not albums, and (b) pretty inconsistent - different systems use different rating scales, a "3 star" rating on iTunes is different from other apps.  It's a mess.

The core problem is that "I like this track (or album)" doesn't make sense as metadata - what happens when you share music? Whose rating counts?  Do you have one global rating or per-user ratings - and where does that end?

So, after looking for a while at various options, I realised I could just use markdown pages in my Obsidian vault to handle album lists.  I can make a "favourite albums" page, and then just add/remove albums from there manually.

But - I'd want a way to play those albums, directly from my vault.  A list is no use if you can't play them.

I could play them from the command-line using [mpc](https://www.musicpd.org/doc/mpc/html/) - I just needed a way to call mpc from an Obsidian page

## First try - using buttons

I've used a few ways to add custom buttons to Obsidian before, I thought maybe I could add a button you click to play an album.

I found the [Meta Bind Plugin](https://www.moritzjung.dev/obsidian-meta-bind-plugin-docs/) seems to have replaced the Buttons plugin I used to use.  It has a way to [run inline Javascript](https://www.moritzjung.dev/obsidian-meta-bind-plugin-docs/reference/buttonactions/inlinejs/) which would do what I need.

And this basic code worked, by writing a `meta-bind-button` code block like:

```yaml
label: play an album
hidden: false
style: default
actions:
  - type: inlineJS
    code: |
      const execSync = require('child_process').execSync;
      execSync('/opt/homebrew/bin/mpc add "Albums/R/Radiohead/A Moon Shaped Pool"', { encoding: 'utf-8' });
```

However - I hit a snag. Two snags really.  First - the buttons produced this way couldn't be included in a table, and I wanted a table like:

| album              | artist    | year |              |
| ------------------ | --------- | ---- | ---------------- |
| A moon shaped pool | Radiohead | 2016 | [play](){: .btn} |
| hail to the thief  | Radiohead | 2003 | [play](){: .btn} |
| kid a              | Radiohead | 2000 | [play](){: .btn} |

Those buttons could be made but it required yet more code - I had to give every `meta-bind-button` snipped an ID, and then refer to the ID in the table.

The second snag was that the block of code above was verbose, hard to generate - and adding IDs made it even harder to generate.

## A second idea - how about a magic link?

I'd seen links before with custom schemes to trigger actions. Obsidian itself [has a custom scheme](https://help.obsidian.md/Extending+Obsidian/Obsidian+URI) - maybe I could register my own scheme? How hard could it be?

Enter the Platypus! No, not Perry - [this Platypus](https://sveinbjorn.org/platypus)

Platypus is a very neat tool that wraps your own custom scripts - shell scripts or python/ruby/whatever scripts - in a Mac app.

Apart from being handy for running apps, I also found it had a very handy feature - [You can register your app as a URI scheme handler](https://sveinbjorn.org/files/manpages/PlatypusDocumentation.html#advanced-options)

So - I wrote a very generic `mpc` wrapper in python:

```python
#!/usr/bin/python3

import subprocess
import sys
import shlex
from urllib.parse import urlparse, unquote

if len(sys.argv) != 2:
    print("ALERT:MpcUri|No or too many arguments provided:", len(sys.argv))
    sys.exit(1)

argument = unquote(sys.argv[1])

if not argument.startswith("mpcuri://"):
    print("ALERT:MpcUri|Argument does not start with mpcuri://", argument)
    sys.exit(1)

arguments = shlex.split(argument.split("mpcuri://")[1])

result = subprocess.run(["/opt/homebrew/bin/mpc"] + arguments,
                        stdout=subprocess.PIPE, stderr=subprocess.STDOUT)

print("NOTIFICATION:McpUri output|" + ":".join(result.stdout.decode("utf-8").split("\n")))
```

and then I used Platypus to wrap this script in an app, and registered it to the `mcpuri::` URI scheme.  (the process is a bit fiddly - I had to play around a bit to get the right settings, but it wasn't too hard)

This works nicely!  Now I can run arbitrary MCP commands with a link - e.g. to stop playing I can make a link `[stop](mpcuri://stop)` which turns into a shell command `mpc stop`

And I can easily generate these links with a bit more scripting, so my eventual "top albums" table can include rows like:

| artist    | album                      | date       |                                                                                           |
| --------- | -------------------------- | ---------- | ----------------------------------------------------------------------------------------- |
| Radiohead | Kid A                      | 2000-08-03 | [play](mpcuri://add%20%22Albums%2FR%2FRadiohead%2FKid%20A%22)                              |
| Radiohead | OK Computer                | 1997-05-21 | [play](mpcuri://add%20%22Albums%2FR%2FRadiohead%2FOK%20Computer%22)                        |
| Radiohead | The Bends                  | 1995-03-08 | [play](mpcuri://add%20%22Albums%2FR%2FRadiohead%2FThe%20Bends%22)                          |

Where the `play` links are markdown links like: `[play](mpcuri://add%20%22Albums%2FR%2FRadiohead%2FKid%20A%22)`

Needless to say this only works on my computer, and it's very hacky - but it works!
