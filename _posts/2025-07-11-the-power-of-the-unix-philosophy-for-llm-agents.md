---
title: "The power of the Unix philosophy for LLM agents"
categories: ['AI']
date: 2025-07-11
tags: [ai, llm, agents, unix, philosophy, tools]
toc: true
---

I was demonstrating using Claude Code inside the JetBrains Rider IDE to a colleague the other day, and they said something along the lines of "it uses a lot of bash commands like find - why doesn't it hook into the IDE to understand the structure?"

I was a bit surprised about this - I quite like the way theses tools use small simple commands. Musing about it afterwards, I realised that this is actually them benefiting from the [Unix philosophy](https://en.wikipedia.org/wiki/Unix_philosophy) - "write programs that do one thing and do it well".

As someone who loves diving into the command-line, with a string of handy tools I use all the time - [jq](https://jqlang.github.io/jq/), [dua](https://github.com/Byron/dua-cli), [ripgrep](https://github.com/BurntSushi/ripgrep), [pbcopy and pbpaste](https://osxdaily.com/2007/03/05/manipulating-the-clipboard-from-the-command-line/), plus all the standard shell tools like find, grep etc - I was already enjoying this aspect of using LLM-based tools.

But I realise that this is also a philosophical difference, and might explain a barrier to using these tools for some software engineers.  It reminds me a bit of [the Cathedral and the Bazaar](https://en.wikipedia.org/wiki/The_Cathedral_and_the_Bazaar).

This was a famous essay by Eric S Raymond way back in 1998, on how open source software is built - he contrasted two key approaches:

- the Cathedral model, where code is developed mostly in private by a few core individuals, open source but still tending towards monoliths
- the Bazaar model, where code is developed more in the public, tending towards more chaotic but alsm smaller interconnected systems.

At least this is how I remember it - it's been a long time since I read it.  In a way it's an interesting foreshadowing of the Monolith vs Microservices world many years later.

Anyway - my colleague seemed to be surprised that this tooling wasn't embracing the large, complicated, sophisticated modelling that a tool like Rider can do - in fact up to now you _needed_ a tool like Rider to understand complex ecosystems like ASP.Net.

Whereas I quite like that it _doesn't have to_ - it uses a mix of small tools, dumb tools, like find and grep; plus compiler warnings, linters, unit and integration tests, and of course the LLM magic-when-it-doesn't-hallucinate textual pattern matching.  And with all this, and some trial and error, it does a quite good job of what previously needed a huge complex IDE.

I can say to Claude Code "I want to rework this Enum - the names aren't quite right, can you make them X and Y instead?" - and it will do this, without any of the complexity that Rider uses for refactoring; and it can go further, and rename related things.  It is occasionally wrong, but not so often for simple things like this; and it can do more complex refactorings that Rider doesn't handle.  One small example, we had test code that looks like

```csharp
getBusinessResponse.People.Count.Should().Be(2);
getBusinessResponse.People.Should().Contain(p => p.Id == newPersonResponse.Id);
getBusinessResponse.People.Should().Contain(p => p.Id == personResponse1.Id);
```

I said to Claude Code:
> can you rework these lines to use BeEquivalentTo and 
  test against a single array?

and it produced:

```csharp
getBusinessResponse.People.Select(p => p.Id)
  .Should().BeEquivalentTo(
    [newPersonResponse.Id, personResponse1.Id]);
```

and then ran the tests to make sure nothing broke.

Anyway, that was a digression! My point is just, the LLM tools work well with small composable tools in conjunction - and I suspect will not work as well if you want to use large complex non-composable tools.

Another example - my personal music collection is stored as mp3 files indexed and served by MPD, the Music Player Daemon.  It used to be in iTunes, but as Apple enshittified their apps, and my veneral iPod died (many years ago) I moved to MPD - it's pretty old and there are newer tools, but it's simple and works for me.

But also - it fits _very_ well with LLM tools.  It has a textual command-line interface in mpc, I'm already using this to play music in Obsidian - see [my previous blog post](/2024/09/06/custom-mac-uri-schemes-obsidian).  So it'd be easy to call this from an LLM - or wrap it in an MCP service for a home-grown Siri or Alexa like music player.

---

I'm digressing again. Tired brain tends to ramble. Back to my main thought - some people love what I see as more the Bazaar model, the Unix philosophy - lots of small tools that do one thing each, that interact well with each other. A bit more chaos and complex network effects - if I pipe `pbpaste` to `jq` and then to `sed` and maybe a bit of `xargs` I can quickly get into a tangled mess.

And some people like the Cathedral model - larger systems, often more robust and carefully engineered, with more internal complexity.

TODO conclude what ever I was trying to say?


