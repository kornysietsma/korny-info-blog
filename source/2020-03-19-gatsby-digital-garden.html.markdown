---
title: Building a personal digital garden with Gatsby
date: 2020-03-19 19:53 GMT
tags: tech
---
(TL;DR - you can jump ahead to the sample site at <https://kornysietsma.github.io/digital-garden-sample/> based on source and content at <https://github.com/kornysietsma/digital-garden-sample> )

For a very long time, I've used a wide range of different tools to try to manage my digital information - all sorts of digital information, the boundaries are fuzzy, but samples of the kinds of things I want to keep are:

* That interesting thought that occured to me on the train for something I might do in my vast spare time
* My code snippets from a recent cool problem I solved, in case I want to solve it again
* Personal reflections on things in my life - the classic diary entry
* Daily notes on my current client - stuff that usually goes in physical notebooks that I file and never open again
* Mentoring and leadership notes on people who I'm trying to assist
* Draft versions of blog posts I'll finish in 6 months time
* That recipe I found in a cookbook that I like
* The link that someone shared on social media that I'd like to read later - or at least, I'd like to be able to _find_ it later on the slim chance I decide to read it
* My bookmarks of useful links for a particular tech stack

and so on, and so on.  A lot of this is fuzzy and unstructured really; the lines are blurry.  The common thread is, I collect a lot of junk that sometimes I want to find again.

## Some history

I've used a bunch of things over the years - Evernote and Pocket and similar semi-commercial tools; browser bookmarks which grow endlessly and often get lost when changing browsers (and often that's good, they date quickly and Google/Ecosia/whatever can find the links faster most of the time), archive folders on disk, and on DropBox, and on Google Drive; Github gists, Remember The Milk, Trello boards.  And of course the classic - 80 open browser tabs + a "bookmarks" with folders and sub-folders and a folder "bookmarks from old laptop" and another "bookmarks from the laptop before that"

This has been going on for _decades_ - I remember having a public bookmarks web page about 20 years ago.

About 5 years ago when I was doing a lot of clojure, I got into Emacs and did a lot in the wonderful [org-mode](https://orgmode.org/) - it kind-of covers most of this, especially when combined with [orgzly on my phone](http://www.orgzly.com) - but I found it increasingly hard to use smoothly.  If I'm not using emacs all the time I forget the keystrokes; and (sorry emacs fans) the whole multiple-text-pane-ui thing just doesn't cut it for me any more.  And integration with anything means tweaking elisp and other arcane things.  If I used emacs 100% of the time this might be OK, but as an occasional user, it isn't cutting it.

About 2 years ago I realised that the blogging tools I've been using actually do a lot of what I want - if I dump _everything_ as Markdown or Asciidoc in a Jekyll site, then host it locally on my laptop, it's not bad - at least for capturing things daily as I go.  It became my digital diary - bookmarks and firehose stuff and long-term notes were still in org-mode, short-term planning was still in Trello, but the Jekyll diary worked quite well.

## Advantages of a text-based information store

* It doesn't take much storage
* It can be bulk-searched easily.  Want to find that rant I wrote about ESBs? Open a text editor or a shell, and search.
* It's easy to script - every scripting language can manipulate structured text files with ease
* It's easy to encrypt and back up - no binary files
* It doesn't get out of date easily.  If I change tools or platforms, I can write a script to merge the files into whatever the new tool needs.  This is a biggy, and my main problem with things like Evernote - I don't want to get locked in to a platform forever!  And worst case, if I find these files on an old disk in 20 years, I can still read them.  (I have email archives from the '90s somewhere, that I want to read, but I need to reverse engineer the Agent newsreader app's file format first...)

## Enter Gatsby

The Jekyll solution was doing OK as a place to put thoughts and information, and basic searching was ok in a text editor - but I was finding the web interface not awfully useful, and it was hard to organise things.

Then I was reading up on [GatsbyJS](https://www.gatsbyjs.org/), and I came across [this sample digital garden](https://github.com/johno/digital-garden) and associated articles, and I thought "I could move my diary to gatsby" - so here we are.   (See below for more on digital gardens.)

Gatsby is basically a clever idea - instead of going straight from markdown to html like Jekyll and others do, and building every other customisation by hand, why not add a couple of layers - a graphql data representation, and a JavaScript/React html production layer?

The basic flow of content then goes:

1. Base content is one of a range of formats - markdown, JSON files, images, or sourced from a CMS. (Don't get distracted by all the CMS talk - for most purposes you can just use the file system for sources)
2. You use one of a range of plugins, or custom code, to represent that data as a graphql layer.  Note this is still at build time! You don't need graphql at runtime.
3. You generate pages, still at build time, using JavaScript code which queries the GraphQL data and creates HTML pages. This all uses React for page creation, so you have a lot of power over templating, styling, and all the magic that React gives you.

That's about it. The end result is mostly static html+css. (it also includes React for things you might want to change at runtime, but the basic site works fine with JavaScript off)

And at build time you can use custom scripts to do all sorts of stuff with those static pages.

You can look at a sanitised clone of my site at https://kornysietsma.github.io/digital-garden-sample/ - source at https://github.com/kornysietsma/digital-garden-sample - the real one has a lot more content! But this hopefully shows the idea. (Note - it is designed for a wide laptop, there's no mobile support at all yet!)

The build-time page generation is in [gatsby-node.js](https://github.com/kornysietsma/digital-garden-sample/blob/master/gatsby-node.js) - this is what does the "magic" of converting all the files under `/content` into a mix of [diary entries](https://kornysietsma.github.io/digital-garden-sample/-/-/diary/2020-01-01-first-post/), [wiki pages](https://kornysietsma.github.io/digital-garden-sample/-/-/wiki/about/), and [firehose lists](https://kornysietsma.github.io/digital-garden-sample/firehose/tech/-) - plus a whole tagging and categorising system.

## What's all this "digital garden" stuff?

The digital garden - and I may be misusing the term, it's all a bit new to me - is a place where your information resides - it's not necessarily time-based like a blog, it's also a network of information, more like a wiki.

There's a good description at <https://joelhooks.com/digital-garden> - which I found from browsing the gatsby sample at <https://github.com/johno/digital-garden> - both of those link to the earlier articles [Building a digital garden](https://tomcritchlow.com/2019/02/17/building-digital-garden/) and [Of gardens and wikis](https://tomcritchlow.com/2018/10/10/of-gardens-and-wikis/) by Tom Critchlow.  You can keep following links to fascinating articles from here!

I also love [Martin Fowler's bliki](https://www.martinfowler.com/bliki) which is something very similar - a combination blog and wiki.  [Martin writes](https://www.martinfowler.com/bliki/WhatIsaBliki.html)

>I decided I wanted something that was a cross between a wiki and a blog - which Ward Cunningham immediately dubbed a bliki. Like a blog, it allows me to post short thoughts when I have them. Like a wiki it will build up a body of cross-linked pieces that I hope will still be interesting in a year's time."

My "digital garden" isn't public - there's too much confidential, or just plain half-baked, to make it public.  I might turn my blog into a garden at some stage though.  (I'm a little hesitant, because so far I've follow the mantra "use boring tools" - I want to keep my blog low-maintenance, and Gatsby is still new and rapidly changing)

## My categorisation scheme

I didn't want to go wild with hierarchies or massive structures - I've made that mistake enough times in the past!

Basically I have three types of content at the moment:

1. Diary entries - Markdown pages with a 'date' in the metadata - which get shown in reverse chronological order
2. Wiki pages - which are just Markdown pages with no date!  I do use naming conventions for where they are stored and how they are named, but otherwise they are just the same as diary entries, but they get shown alphabetically in different bits of the UI.  (and there's no magic shortcut to link to them - yet).
3. Firehose entries - which are tiny snippets, mostly URLs or brief notes - are just JSON.  All JSON files in the `/content` directory are assumed to be firehose data (more on that later) and get slurped in together.

And then I have two kinds of categorisation:

* Categories are a simple top-level category choice.  It's a bit arbitrary, the idea is to be able to browse just "work" or just "play" or just "tech" stuff.  I like single layers of organsation, it stops me over-complicating things.
* Tags are anything else.  Any content can have zero or more tags; I'm working out what tags work as I go.  You can currently only filter by a single tag at a time.

### Handling state through URLs

I did have a snag with my categories and tags - how do you keep track of state?  I wanted to say "browse all pages in the "work" category" - but I wanted that selected category to be remembered. There is no "state" in a Gatsby site - it's all static HTML, remember?  I could use tweaks like # URL suffixes but it all looked quite complex, and I'm a fan of simple.  So I just went for a routing scheme - most urls are of the form `/[category]/[tag]/page` - so if a page is accessed via `/work/fish/wish-i-was-fishing` I know it should show the `work` category and `fish` tag as highlighted.  (and yes, that means each page is rendered mulitple times for every category and tag.  But it's at build time and it's fast, so I don't really care)

(Disclaimer time - I'm a total Gatsby newbie, with no spare time so doing whatever seems to work - there may be dramatically easier ways to do this!)

### A bit more on the firehose

The firehose is where I dump the continuous deluge of stuff that I have spent decades trying to capture.  I know by now that 90% of things I see - bookmarks, video links, "to_read" entries, articles in pocket, etc - will never be looked at again.  But I like to capture them anyway, so when I go "I saw a cool thing a week ago - where is it?" I can find it.

Firehose entries are implemented as JSON snippets like this:

~~~javascript
  {
    "title": "https://www.devops-research.com/research.html",
    "date": "2020-02-06",
    "category": "tech",
    "tags": ["dora", "devops", "cd"],
    "lines": ["nice diagram summary of DORA Devops stuff"]
  },
~~~

I don't generally write JSON by hand though - on my phone I run [orgzly](http://www.orgzly.com/) and then I have a script to convert that to JSON every now and then; and I have this function in my `.zshrc` so I can add entries from a terminal by running the `firehose` command:

~~~bash
firehose() {
  pushd ~/path/to/garden

    echo "Title: "
    read title
    echo "Tags: (comma separated) "
    read tags
    jtags="$(echo "$tags" | jq -R 'split(",")')"
    echo "Category: (tech, work, personal, play, world, meta, family, other)"
    read category
    echo "url or text:"
    read url

    pdate=`date +%Y-%m-%d`

    echo "[{
\"title\": \"$title\",
\"category\": \"$category\",
\"date\": \"$pdate\",
\"tags\": ${jtags},
\"lines\": [\"${url}\"]
}]" > /tmp/fhbit.json

    INBOX=content/firehose/laptop/inbox.json
    jq -s add $INBOX /tmp/fhbit.json > /tmp/fh.json
    cp /tmp/fh.json $INBOX

    echo "updated $INBOX"
}
~~~
Of course it's pretty easy to convert any other stuff I might have lying around to JSON or Markdown - both are easy to create.

And that's the thing I'm really enjoying about Gatsby - I have _control_ - whatever bits and bobs I might want to add in the future - maybe an image gallery, maybe ebook categorisation - it's very tweakable.

## Other neat Gatsby things
There are some very cool plugins available for all sorts of neat things.  I'm generating [graphviz and mermaidjs diagrams](https://kornysietsma.github.io/digital-garden-sample/-/-/diary/2020-01-03-diagrams/) embedded in markdown files.  [Images](https://kornysietsma.github.io/digital-garden-sample/-/-/diary/2020-01-02-images/) are automatically scaled and made responsive.  And of course [source code formatting](https://kornysietsma.github.io/digital-garden-sample/-/-/diary/2020-03-14-demonstrating-source-code/) is straightforward.

## Downsides of Gatsby

First, it's pretty new - and being in node.js land, I'm regularly updating packages; even right now `npm audit` is showing a vulnerability because several libraries use `decompress` which [has a known defect](https://npmjs.com/advisories/1217) - this isn't a problem for me as I only run this code on my laptop when I rebuild the site, but would be more concerning if you were using this somewhere big.

Also, I found that a lot of the themes and starters are, frankly, more useful as demos than actual fully featured sites.  They tend to have pretty horrible CSS - not just per-component CSS, I've come to terms with that; but inline css in the middle of JSX files, and some obvious "we hacked this together until it looks OK on our machine" stuff.  They also often include all sorts of things that you might not want, or might want differently.  I tried using about 4 different quite popular starters, before I gave up and worked from the default tutorial instead.

Overall, though, it's pretty neat - I'd definitely be interested in using this on a client site, especially hooked up to a nice headless CMS.  And I'm going to keep tweaking my own gatsby digital garden for a while!  (no guaranteeing that I won't be praising some completely different alternative in another 5 years, of course)