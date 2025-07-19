---
title: "Clowns to the left of me ..."
categories: ['AI']
date: 2025-07-19
tags: [ai-coding-tools, software-development]
toc: true
---

I've had the song "Stuck in the Middle with You" in my head for a few weeks. (R.I.P. Michael Madsen!)

![Reservoir Dogs ear scene](/assets/images/2025-07-19-clowns-to-the-left-of-me/reservoir-dogs-scene.jpg)[^1]

[^1]: Image from _Reservoir Dogs_ (1992), directed by Quentin Tarantino. Miramax Films. Fair use for commentary and criticism.

But not because of Reservoir Dogs - but because of the public discussion about AI coding tools. (Yes, I know... feel free to walk away if you are sick of the whole thing).

I feel like there's this strange culture war, or something like it, playing out - with wild statements on both extremes - and I'm stuck in the middle.

### Hype To the left of me

There is just _so much_ AI Hype.

I'm talking here mainly about software development tools. There's plenty more ludicrous hype when it comes to other AI areas, but I'm trying to limit this to software engineering.

And the hype, as well as the naïveté, is extreme. You get people vibe coding their entire business applications with no thoughts of security. You get people claiming 50x speed improvements, or indeed "we don't need developers at all". You get people posting "I'm not a programmer but I used Copilot to build my entire product and it's awesome", with multiple variations of this. Online discussion forums seem to be full of highly risky advice - "I just turn on `--dangerously-skip-permissions`" or "use this MCP server which gives write access to your git repo and reads user-supplied comments"[^trifecta] or even worse.

[^trifecta]: Essential reading: [Simon Willison on the lethal trifecta for AI agents](https://simonwillison.net/2025/Jun/16/the-lethal-trifecta/)

Amusingly there's also quite a few comments like "oops I deleted my whole file system, what do I do now?" or "I'm not a programmer and I got Copilot to build my product but now it's broken and won't change anything - I want my money back". There's some tasty schadenfreude here but I also feel a bit sorry for some of these people, where things started _so_ nicely, but now technical debt, AI slop, and a lack of the knowledge of what "good" looks like, are making it all fall apart.

A lot of the hype is just marketing - astroturfing from fake users, or just plain press releases breathlessly reported by the media, or marketing via dubious research articles. "Look at our amazing new model, it has so much more data than the last one, it is reasoning now! We ran these benchmarks to prove it!"

A lot of the hype though does seem to be genuine users - lured by the quick result, the slick prototype, the dopamine hit of seeing all that code produced, without the boring course-corrections that feel like waste. Once you are high on the "look how much code I can make" drug, it's hard not to evangelise it to everyone else.

And as the last year or two have shown us, it's very easy for people to be fooled by LLMs, which excel at looking like something they are not. People anthropomorphise the tools all the time - "Why did Claude do this dumb thing? Can't it see the example I'm looking at of how to do it?" - they start to think this is genuine intelligence that can reason and learn, not a specific set of tools.

LLMs are wonderful machines that read your data and questions and produce results in a way that _feels_ like intelligence, but is actually just really clever pattern matching and a surrounding ecosystem of context sources and tools. Sometimes the results are amazing, occasionally they are terrible, and _you always need to check the results_ because the process is fundamentally nondeterministic, and just because 99% of the time something worked, there's always that 1% chance it was confidently wrong.

### Skeptics to the right

On the other side - the anti-AI sentiment is also pretty wild.

I think most of these folks are well meaning - far more so than the pro-AI hypers; my sympathy is with healthy skepticism in general. But they are also prone to jumping on hype - for one example the [Your Brain on ChatGPT](https://www.brainonllm.com/) paper, which is still in pre-print, not peer reviewed, and has had [some](https://theconversation.com/mit-researchers-say-using-chatgpt-can-rot-your-brain-the-truth-is-a-little-more-complicated-259450) [serious](https://www.changetechnically.fyi/2396236/episodes/17378968-you-deserve-better-brain-research) [criticism](https://www.globaleconomicnews.au/opinions/your-brain-on-chatgpt-a-forensic-takedown), still got a _huge_ amount of coverage, including [Time Magazine](https://time.com/7295195/ai-chatgpt-google-learning-school/) - this includes some classic moral panic language:

> Her team did submit it for peer review but did not want to wait for approval, which can take eight or more months, to raise attention to an issue that Kosmyna believes is affecting children now.

Oh my goodness, will nobody protect our children?!

Similarly the [recent study on experienced open-source developer productivity](https://metr.org/blog/2025-07-10-early-2025-ai-experienced-os-dev-study/) is being waved around to say "this proves they don't work" - I think this has been shared multiple times on every single tech forum I frequent. The authors of the paper evidently expected this, and provided this table, which doesn't seem to get as much mention as their headlines:

![METR study results table](/assets/images/2025-07-19-clowns-to-the-left-of-me/metr-study-table.png)

And this interesting breakdown of likely contributing factors:

![METR study contributing factors](/assets/images/2025-07-19-clowns-to-the-left-of-me/metr-contributing-factors.png)

This study is actually pretty interesting - and it does show where we should be cautious to assume self-assessment of how good these tools are. And probably real limitations in large complex codebases. But it's no "Ah-ha! The emperor has no clothes!" moment, as far as I can tell. (After I wrote this, I found that [Simon Willison has a good discussion of this paper as well](https://simonwillison.net/2025/Jul/12/ai-open-source-productivity/) - and there's a rather more severe critique at [Cat Hick's blog](https://www.fightforthehuman.com/are-developers-slowed-down-by-ai-evaluating-an-rct-and-what-it-tells-us-about-developer-productivity/) )

I also see quite a few people who have tried the most basic, un-assisted, low-context tools, and get terrible results; and then rule out AI tools as fundamentally broken. "I used copilot and its suggestions are wrong 40% of the time, often ludicrously wrong". This was where I was at 6 months ago - Copilot seemed like a handy yet often irritating Clippy, no big deal. I think this drives a lot of skepticism, people who feel they gave it a go, it didn't live up to the hype, so they've made up their minds.

And generally there's just a lot of anger and frustration, in reaction to the constant flood of hype:

![ranty example](/assets/images/2025-07-19-clowns-to-the-left-of-me/neologism-rant.png)

As I said before, I'm more sympathetic to the skeptics than the hypers. Especially when it comes to the broader AI industry - I'm always keen to read [David Gerard's Pivot to AI](https://pivot-to-ai.com/) or any of [Ed Zitron's rants](https://www.wheresyoured.at/) - see also [my downsides section later](#dont-forget-the-downsides).

But - I do find that there's a lot of talk about AI software development tools, that just plain conflicts with my personal experience.

### Stuck in the middle

So here's the problem - every day I'm flooded with articles that are ludicrously positive _and_ ludicrously negative. But what I'm seeing doesn't match either.

I personally find the tools helpful, powerful, and a definite boost. Maybe, as per the METR study, I'm losing more time learning the tools, and tweaking the context, and reading and experimenting and correcting when they get wrong, compared to the time actually saved.

But some of this is the startup costs with any new technology; some will only be paid once, some will be a slow gradual tax, especially with a technology that is changing so fast. And some will be a learning curve for us to learn when to say "Ok, this task isn't suited to LLMs and I should just do it by hand".

And they are already giving me a bunch of obvious speedups, small and large. Claude is fixing the links in this blog as I type. Claude wrote the tiny python script I use daily to list our project's outstanding pull requests.  Claude wrote a little visualisation of git activity I needed for management. Claude is drawing simple Mermaid diagrams in our docs. Claude helped me use [Snyk](https://github.com/snyk/mcp-server-snyk) to find that our project had an insecure dependency, and [Sourcebot](https://docs.sourcebot.dev/docs/features/mcp-server) to find that another project of ours had the same dependency and had a viable workaround.

And for a larger example, I've written up a [separate blog post](/2025/07/18/a-real-world-ai-coding-case-sample) detailing how I used Claude Code to implement a Kafka messaging feature in an ASP.Net Core application. This demonstrates what can actually be done with AI coding tools today - not the wild hype, not the complete dismissal, but practical reality.

## What's next?

I'm still learning - I've made masses of progress in the couple of months since I started using the tools in anger, and there's a lot more to learn!

I also want to learn how to guide our organisation, so our developers know how to use these tools effectively, carefully, and productively.

It's an exciting time - I'm having more _fun_ with these tools than I expected. There are so many benefits already, and so much potential for more.

But...

## Don't forget the downsides

I need this standard disclaimer at the end of any AI post. We must remember the context behind these tools - there are giant tech companies pushing these hard into every corner of our lives. They are run by horrible tech [broligarchs](https://en.wikipedia.org/wiki/Broligarchy)[^broligarchy] whose interests are personal power and destabilising democracy, not helping the world.

They consume vast amounts of power, which due to our failure to charge for [externalities](https://en.wikipedia.org/wiki/Externality), mean they are burning fossil fuels, consuming scarce water, and accelerating the climate crisis. And there are many signs that the funding for this is [an unsustainable bubble](https://www.wheresyoured.at/subprimeai/) and the companies and tools may collapse, or start charging significantly more and/or enshittifying the experience of users.

[^broligarchy]: Thanks [Carole Cadwalla](https://broligarchy.substack.com/about) for introducing me to the very useful term [Broligarchy](https://en.wikipedia.org/wiki/Broligarchy)!

## Further reading

I'm not alone, stuck here in the middle. For some good sensible approaches I'd also recommend [Birgitta Böckeler](https://birgitta.info/) and [Pete Hodgson](https://blog.thepete.net/blog/) and of course [Simon Willison](https://simonwillison.net/)'s blog is essential reading.