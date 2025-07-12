---
title: "The power of the Unix philosophy for LLM agentic tools"
categories: ['AI']
date: 2025-07-11
tags: [ai, llm, agents, unix, philosophy, tools]
toc: true
---

I was demonstrating Claude Code to a colleague the other day - I was working on an ASP.Net Core C# service, using Claude within the JetBrains Rider IDE. And my colleague said "it uses a lot of bash commands like `find` - why doesn't it hook into the IDE to understand the structure?"

I was a bit surprised by this - I quite like the way it uses small simple commands. Musing about it afterwards, I realised that this is actually an example of the [Unix philosophy](https://en.wikipedia.org/wiki/Unix_philosophy) - "write programs that do one thing and do it well".

I am already someone who loves diving into the command-line, I have a string of handy tools I use all the time - [jq](https://jqlang.github.io/jq/), [dua](https://github.com/Byron/dua-cli), [ripgrep](https://github.com/BurntSushi/ripgrep), [pbcopy and pbpaste](https://osxdaily.com/2007/03/05/manipulating-the-clipboard-from-the-command-line/), plus all the standard shell tools like find, grep etc - I was already enjoying this aspect of using LLM-based tools; they can be easily trained to use the tools I use already.

But I realise that this also reflects a philosophical difference between different software engineering communities. There are people who love lots of small unix-style tools, who live in the terminal or at least fall back to terminal commands regularly[^1] - but there are also people who love their IDEs, their smart powerful tooling. It reminds me somewhat of the famous essay [the Cathedral and the Bazaar](http://www.catb.org/~esr/writings/cathedral-bazaar/cathedral-bazaar/) from way back in 1998.

[^1]: I'm not a terminal purist - I don't use vim, I still like GUIs for code editing, graphical tree widgets, visualisations...

A pertinent quote:

> Linus Torvalds's style of development—release early and often, delegate everything you can, be open to the point of promiscuity—came as a surprise. No quiet, reverent cathedral-building here—rather, the Linux community seemed to resemble a great babbling bazaar of differing agendas and approaches ... out of which a coherent and stable system could seemingly emerge only by a succession of miracles.

Sounds a bit familiar.[^2]

[^2]: I had a longer digression here but removed it as it went too far off piste! I encourage people to read the essay, it's suprisingly relevant still

Anyway - my colleague seemed to be surprised that the LLM wasn't embracing the large, complicated, sophisticated modelling that a tool like Rider does - in fact up to now you _needed_ a tool like Rider to understand complex ecosystems like ASP.Net.

Whereas I quite like that it _doesn't have to_ - it uses the Unix philosophy - text-based input and output (which language models naturally work well with), small fast stand-alone tools, that do one thing and one thing well. And despite the continued need for powerful IDEs, the world has shifted - even Cathedrals like ASP.Net now supply quite good command-line tools like `dotnet` for building, formatting, linting, and testing, with an LLM-friendly text interface. With all these tools, plus the ability to iterate over solutions and use trial-and-error to course correct, LLM-based tools do a quite good job of what previously needed a huge complex IDE.

Often Claude Code does a _better_ job than the smart IDEs for a lot of refactorings. I remember when refactoring IDEs first appeared, and they were amazing - I could say "extract these lines into a function" and it just worked. But now I can say to Claude "we are doing this repetitive pattern in our tests - can you change it to test against an array using Fluent Assertions instead?" and it turns:

```csharp
getBusinessResponse.People.Count.Should().Be(2);
getBusinessResponse.People.Should().Contain(p => p.Id == newPersonResponse.Id);
getBusinessResponse.People.Should().Contain(p => p.Id == personResponse1.Id);
```

into:

```csharp
getBusinessResponse.People.Select(p => p.Id)
  .Should().BeEquivalentTo(
    [newPersonResponse.Id, personResponse1.Id]);
```

and then it can find the equivalent pattern through all the tests, and do a good job of fixing them all.[^3]

[^3]: It's non-deterministic, you have to check it for hallucinations, but they are pretty rare on simple changes like this. And it will run the tests after every change, and iterate if something goes wrong.

Claude Code itself also follows this philosophy - instead of being tightly coupled to an IDE, it runs in a terminal, with a text interface, and they have plugins for various IDEs to provide a smarter user interface - using the editor's context and UI elements for changes.  But basically it's a text app - which must keep their complexity much lower than the competitors who are building their tools tightly coupled to particular editors.

Another example - my personal music collection is stored as mp3 files indexed and served by [MPD](https://www.musicpd.org/), the Music Player Daemon. It used to be in the Cathedral-like iTunes, but as Apple enshittified their apps, and my venerable iPod died (many years ago) I moved to MPD for storage, and other tools for UIs - and now this fits well with LLM tools. It has a command-line interface in [mpc](https://www.musicpd.org/clients/mpc/), I'm already using this to play music in Obsidian - see [my previous blog post](/2024/09/06/custom-mac-uri-schemes-obsidian). So it'd be easy to call this from an LLM - or wrap it in an MCP service for a home-grown Siri or Alexa like music player.

And a third example - this blog is written using [Jekyll](https://jekyllrb.com/), which means it's just markdown text. LLMs _love_ working with markdown. I don't use LLMs to write the text[^4] but I can say "please turn the word Jekyll into a link" and save a lot of annoying toil. An LLM would be much harder to integrate into a heavyweight Gui blog editor like Wix.

[^4]: I'm fine with expressing my ideas in writing, though I tend to digress too much!

---

Anyway I digress. Tired brain tends to ramble. Back to my main thought - LLM code augmentation tools work best where they, and their users, embrace Unix-philosophy tools - multiple small tools that do one thing each, that interact with simple text-based formats.

I can see this being a bit of a struggle, and a culture clash, for people who love the Cathedral model - big complex clever systems. Often these are more powerful, more robust, more carefully engineered, and safer than the Bazaar of small independent tools. But I think LLMs are tipping the balance further to where the smaller tools, despite the risks and chaos, are dramatically more productive.

We just need to make sure we keep on top of the risks and chaos, and don't drown in a world of technical debt and AI slop.
