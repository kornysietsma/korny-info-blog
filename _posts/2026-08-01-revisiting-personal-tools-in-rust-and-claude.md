---
title: "Revisiting rust and Claude for personal tools"
categories: ['software development']
date: 2026-08-01
tags: [rust, claude-code, mac, mpd, genai]
toc: false
---

I'm not doing a lot of large-scale AI coding at the moment, but I'm still tinkering on side projects when i can.  I had fun revisiting an old problem this week, which turned into a nice illustration of how much has changed in the last 2 years.

_Note_ see also my standard [AI Disclaimer](/ai-disclaimer/)

## Two old hacks

Over the last couple of years I've written a couple of posts about scratching my own itches around [MPD](https://www.musicpd.org/), the music player daemon I use to play music at home.

In [Custom URI schemes in Obsidian](/2024/09/06/custom-mac-uri-schemes-obsidian/) I wanted clickable `[play](mpcuri://...)` links in my Obsidian notes, so I could keep "my favourite albums" as a markdown table. I solved that with a little python script wrapped up as a Mac app using [Platypus](https://sveinbjorn.org/platypus).

In [Mac toolbar widgets with xbar and rust](/2025/01/18/toolbar-widgets-with-xbar-and-rust/) I wanted a little menu bar widget to show and control what was playing, and I built that with [XBar](https://xbarapp.com/)

Both of these worked, but with some instability and fiddly setup and based on helpers that aren't always stable or easy to use. And as a set of hacky scripts and glue, they aren't very extensible.

## So I thought I'd try again with 2026-era Claude

It occurred to me that most of these tools were to fill my knowledge gaps - you don't need tools for Mac menu bar items and URL schemes, really, you just need to know how to write these things youself. And AI tools are great at understanding a whole bunch of fiddly system tool things that frankly I don't have the time to learn.

Also Claude has gotten much better at rust, so I thought I'd try it again at tackling all of this as a single native rust app.

So over a handful of Claude sessions in my spare time,  I built [rust-mpd-controller](https://github.com/kornysietsma/rust-mpd-controller) - one Rust binary that does both jobs at once:

- a menu bar widget showing the current track, with play controls, album navigation, playlist manipulation, and more features as I need them
- a registered `mpdcontrol://` URL scheme, so my Obsidian links still work - same encoding as before, just a new scheme name

![mpd-controller screenshot](/assets/images/2026-08-01-rust-claude-mpd/mpd-controller-screenshot.png)

No XBar. No Platypus. No shell scripts. The libraries do all the heavy lifting - [`tray-icon`](https://crates.io/crates/tray-icon) and `muda` for the menu, [`tao`](https://crates.io/crates/tao) for the event loop, [`mpd_client`](https://crates.io/crates/mpd_client) for MPD.

Better still, because the result is a proper app with a long-running process, it can do things the hacky scripts couldnt - it can listen to MPD `idle` states rather than polling, it can cache information, I can extend it to handle all sorts of future needs.

## Things have changed

In October 2023 I wrote [Playing with Rust and Copilot](/2023/10/31/playing-with-rust-and-copilot/), where I let Copilot generate a single function to split YAML frontmatter from a markdown file. It produced about fifteen lines of confidently-wrong C-style procedural code with a `break` where it needed a flag reset, and my conclusion was "handy for a minor IDE boost for simple boilerplate code, but definitely not to be trusted for anything longer; at least not in rust".

Two and a half years later, Claude Code wrote most of a 2,000-line native Mac application in a language it used to struggle with, against several libraries I'd never used, and I spent my time on design decisions rather than on reading API docs or understanding rust async event loops.

I should note this isn't just because models and harnesses have improved - that has helped, but also we've learned how to control them better - in 2023 I was using code completion, now I'm using iterative spec-driven approaches with careful model selection and lots of human-in-the-loop feedback at every stage.  Plus of course I've swapped standing on the shoulders of XBar and Platypus, for the shoulders of [tauri](https://tauri.app/) who built `tray-icon` and `muda`, plus `tao` and `mpd-client` developers.

## The barrier to entry for personal tools has plummetted

The thing that's actually significant here, for me, isn't that the code is better, it's that the *cost of writing a tool at all* has dropped far enough to change what's worth building. Scratching the itch of "I wish I had a handy music navigation interface" was just something I'd push on the long pile of "too hard to even contemplate" projects, now it's a pretty trivial spare-time project.

The code is [on GitHub](https://github.com/kornysietsma/rust-mpd-controller) under MIT. It is explicitly a personal tool - but feel free to pilfer, if any of the ideas are useful. (And the prompts are largely there in git history too - apologies for the git history, I made lots of little commits with bad names, I probably should get Claude to clean it up some day!)

As I said at the start, my standard [AI Disclaimer](/ai-disclaimer/) still applies - this is using commercial models funding money to tech oligarchs using climate-destroying data centres. It sucks. I do have some hope though - most of what I'm doing would be viable using open models (if you have the hardware) so one day we might be able to do this in a more sustainable way.

---

If you want to discuss this post, please reply to [my post on Mastodon](TODO) or [my post on Bluesky](TODO) (I'm doing both as one is more free, one is more convenient for many people)
