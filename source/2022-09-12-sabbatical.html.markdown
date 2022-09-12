---

title: A geeky kind of sabbatical
date: 2022-09-12 14:31 GMT
tags: life, tech

---

## A geeky kind of sabbatical

I am on sabbatical!  After 10 years at Thoughtworks, I'm getting a nice long break.  (I've actually been on sabbatical for a few weeks - school holidays plus usual procrastination delayed this post...)

I had to decide, a while ago - what would I do on my sabbatical?  Some people use them to travel, to see the world, to expand their horizons - but I have two small kids, so that really didn't sound much like it fit this stage of my life!

Instead, I wanted to think about things I could do while largely staying at or near home.  On thinking further, my main life goals at the moment are:

* Mental health
* Physical health
* Learning and self-improvement
* Family and family maintenance

Several of these are overlapping - I started on a venn diagram but it got a bit messy!

However, I'm also a big geek - one thing that satistfies my "Mental health" and "Learning" areas is to actually write some code.  To build something of value, and share it with others.  This is especially the case as I haven't been on a proper software delivery project since 2020 - I've done some fascinating work, but I have felt a bit disconnected from the art of writing code.

So - a major goal of my sabbatical is to try to make some big improvements to my pet project, the [Polyglot Code Tools](https://polyglot.korny.info). It might not sound much like a holiday to some!  But I love it.

I'm also doing plenty for the other categories - I'm back doing weekly yoga (which is awesome), I had a great summer holiday with the kids and my mum, and I've done lots of life-admin tasks that I won't bore people with here.  I'm also going to try for a few long bike rides - but right now I'm scratching my "I want to code" itch!

I have a few big epics planned around my tools - some of them are already done or nearing done!  For example, you can now assign users to teams, and visualise which team has changed which areas of code most in a particular timespan:

![Showing teams in the Explorer](2022-sabbatical/v060alpha1_teams.png)

This was from code I hacked together at a client, I've now re-written it cleanly, in TypeScript, and it is mostly working.

## Work in progress

* Moving to TypeScript - done!  Some areas were quite tricky - I should blog about TypeScript...
* Saving explorer settings to the browser or to file - done! This is essential as the UI grows - otherwise every time you reload the browser, all config like user teams would be lost.
* Creating and visualizing teams - mostly done! Most of what remains is UI tweaks - letting users see teams in more contexts, for example.

## Planned epics

* Filtering the UI by folder and/or programming language
  * this can really help speed on a large codebase. Sadly the layout can't change on filtering, but that doesn't matter for a lot of use cases.
* Making it work without git - ideally adding support for other SCMs, but "not crashing the UI if there is no git data" would be a good start.  And skipping git scanning would be a good way for users to get faster feedback.
* Rewriting the Voronoi layout in rust / webassembly
  * This is a big one - I've actually started a while ago, but it's tricky, especially as the JavaScript code I use currently is (a) quite prone to crashing, and (b) very much not suited to a rust-style language - lots of random state fiddling all over the place.
  * However, I suspect the result would be drastically faster - not just because rust, but also as I could ditch lots of time-consuming error-handling retries
* If it is fast enough, embedding layout in the Explorer so you can change layout at run-time.  This would make the system much more usable and the feedback loop for things like changing file ignore patterns much tighter.
* Reading the research for more ideas!  I have a number of academic papers I picked up over time, and a number of great Data Visualisation books - I want to mine those for ideas of value.
* Much better documentation - I'd like an introduction video, for instance, for people who learn from videos better than words.  And a matching step-by-step written guide.

## Possible epics

* Using a different lines-of-code tool.  I'm using a fork of [tokei](https://github.com/XAMPPRocky/tokei) which is nice and fast - but I had to fork it because I wanted to be able to strip comments from the code for complexity measures.  And maintaining the fork is annoying.  There are many other multi-language parsers out there, such as [tree-sitter](https://tree-sitter.github.io/tree-sitter/) - these might also let me do some more complex metrics like class/method length, while still supporting a lot of languages.
* Using a data server rather than JSON files.  This would take away some of the unix-style simplicity of the tool - and make it harder to run in locked down environments. But it also might add a lot of power - some calculations could be offloaded to the server, allowing for things like actually observing code as it existed at a particular point in time.  And the layout engine could run as compiled multithreaded rustm not as webassembly in a browser.
* Using other layouts than Voronoi trees.
* Other tools!  I have a [git log visualisation thing](https://github.com/kornysietsma/git-cd-chart-twuk2018) I built ages ago - it'd be great to rebuild something similar with new tools.

## Important tasks but not really epics

* Fixing publishing binaries (the tools I used to use have died!) - probably using github actions
* Adding unit tests to the Explorer - yes, I've been lax here.  The rust code is tested and mostly TDD, but the UI involved a lot of UI tweaking that just wasn't worth testing. Nowadays there is plenty of quite testable logic as well - but having started with no tests, it's hard to course correct.

## Please send me your ideas

If anyone out there has used the polyglot tools, or might be interested but can't for some reason, I'd love to hear your thoughts.  What might you be interested in seeing in a code visualisation tool?

Also, I'd love suggestions of open-source code I can look at as examples.  I can't publish examples based on client code, so I'd like more real-world projects that are a bit like business code:

* Multiple interrelated repositories - it's nice to try out how the [temporal coupling](https://polyglot.korny.info/metrics/temporal-coupling) features work - so far they haven't been awfully useful, but I'm hoping to find places where they are of value
* Lots of teams of developers.  This is a big issue with open-source samples - so much is done by individual contributors.  In day-to-day work we like to work with teams as the unit of software delivery, so I'd love places where visualising teams makes sense.
* Lots of languages.  This isn't hard really, almost everyone has a mix of languages these days.  But it'd be nice to have some languages that lack existing tools, like SQL...
* and of course, lots of code and years of git history.  (but not _too_ much code - I tried running against the linux kernel, and it works, but takes a long long time)

If you have any ideas, please contact me on [mastodon](https://mastodon.social/@korny) or [twitter](https://twitter.com/kornys) (you can comment on this blog too, but it doesn't get checked all that often!)
