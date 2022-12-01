---

title: New polyglot code tools releases
date: 2022-10-13 09:13 GMT
tags: life, tech

---

My sabbatical is winding up, I naturally got far less coding done than I expected!  Our lovely daughter has had a big sleep regression, so a lot of my focus has been on just getting through life rather than perfecting my code.

Still, I have actually achieved quite a lot, now that I go back and look at it - so I thought it was time for an updated blog post.

See [My initial announcement](/2020/09/06/introducing-the-polyglot-code-explorer.html) or  [The main Polyglot Code Tools site](https://polyglot.korny.info) if you want more background.

Major changes:

* Viewing activity by teams
* Saving and loading settings
* Moving to TypeScript for the explorer
* Quite a few refactorings

## Viewing by Teams

I put this at the top as it is the area that is most useful for users!

I'm a huge fan of the [Team Topologies book](https://www.goodreads.com/book/show/44135420-team-topologies) - the Team should be the core unit of delivery in a well functioning agile organisation.

So, when investigating codebases, I wanted to be able to tell which teams were operating in which areas, and how they overlap.  The end result is a view like this:

![New UI with top teams](/2022-polyglot/polyglot-062-top-teams.png)

This does need a caveat though - you need to create team information yourself!  Git doesn't tell me which user is in which team.  (In fact you also need to do a fair bit of work merging users, as git doesn't tell me that `foo@bar.com` is actually the same user as `Fulvio_Barrington@gmail.com` ...)

There is also a view that tries to show where multiple teams overlap, using SVG patterns - this is a bit experimental, but might be useful:

![Top Teams - patterned](/2022-polyglot/top-teams-patterned.png)

And you can focus on a single team (or a single user!) to see just their contribution compared to everyone else:

![Single team impact](/2022-polyglot/single-team-impact.png)

Here blue is the selected team, red is other users, and colours in between show overlap.  Also brighter colours show more change, darker show less.

## Saving and loading settings

Creating teams is a fair bit of manual work, and the Explorer, prior to version 0.6.0, was entirely stateless - there was no way to save that work!

Now, you can save the user and team settings, as well as all the other explorer settings, to JSON files or to browser local storage.  See [the docs](https://polyglot.korny.info/tools/explorer/ui#saving-and-loading-settings) for more.

## Moving to Typescript

The explorer was originally written in pretty hacky JavaScript, with quite a bit of sloppy code - this is the side project of a busy parent after all!  However, I felt the need to clean things up, and also to learn TypeScript after all the good things I'd heard about it - so did the painful job of rebuilding with types.

And it was pretty painful in places.  I do love TypeScript now - it's a brilliant way to apply flexible types to a pretty terrible language.  But some things needed a quite different approach - and some areas, such as D3 visualisations, had almost no documentation at all.  D3 does have types - but very very few examples use them, and I had to do a lot of reading source code and relying on VSCode's excellent TS support to get it all working.

This does however mean that the code is a lot cleaner - I even have a few tests now!  So future changes will be less painful and less risky.

## Other refactorings

I won't go into all the details here, but I also took the chance to clean up a bunch of code.

On the rust side, I got rid of a lot of somewhat dubious generic logic I'd written using JSON `Value` types.  I'd foolishly tried to make the code too generic - I don't know why after 30+ years of coding I still make the same mistakes - I need to have "YAGNI" as a tattoo, just to remind me to keep things simple.

I also enabled all the linters and checks I could, both in rust and TypeScript.  Honestly this is one of the biggest coding improvements I've seen in the past decade or so - automated tooling has gotten so good at spotting errors and non-idiomatic code, it is wonderful, especially for learning languages.

## Looking to the future, and for feedback

I'm going back to work in a couple of weeks - yay!  (actually I do miss it - especially interacting with people outside my family).  But I will keep making changes, as I can.

I have a long-term plan to rework the whole Voronoi layout tool - that's probably the next thing on my list.  But I'd love feedback if people are using this - what is good? What sucks?  What would you like to see?

This blog has Disqus comments, but honestly I don't read them much - probably better to chat to me on [twitter](https://twitter.com/kornys) or [mastodon](https://hachydon.io/@Korny) or face to face!  Or you can raise issues on github for specific bugs.