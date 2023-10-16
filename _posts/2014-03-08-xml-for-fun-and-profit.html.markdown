---
title: Xml manipulation in clojure
date: 2014-03-08 19:37 UTC
tags: clojure
categories: ['software development']
---

> **"XML is like violence - if it doesn't work, use more"**
<!--more-->

Clojure is awesome for parsing and processing structured data.  It has a wide range of functions for handling lists, maps (associative arrays), sets, and (if you really need them) objects.

One great example of the power of clojure for this sort of thing is processing xml.  You may hate xml, you may use json or edn or yaml or anything else you can - but ultimately, xml is still all over the place, and if you need to handle complex xml or large xml, you might want to look at clojure.

This article was started in September 2013 - but it grew, and it grew, and the blog needed some styling, and I moved to Glasgow... so it's rather late getting out of beta.
{: .notice--info}

## Introduction
*Note* - this was originally written as a no-previous-clojure-knowledge-needed post, but it got quite long.  So now I assume you know basic clojure syntax, and how to use the [`->`](http://clojuredocs.org/clojure_core/clojure.core/-%3E) and [`->>`](http://clojuredocs.org/clojure_core/clojure.core/-%3E%3E).  If this means nothing to you, check out [Clojure for the brave and true](http://www.braveclojure.com/) a great starting resource, as well as <http://clojure.org> and [the cheat sheet](http://jafingerhut.github.io/cheatsheet-clj-1.3/cheatsheet-tiptip-cdocs-summary.html).
{: .notice}

As I said at the start, handling XML in clojure is awesome - but the documentation is all over the place, especially as you need to use several different libraries together (this being the clojure way - prefer small composable functions over monolithic frameworks). Hence I'll attempt to pull everything together in this blog post - at least for _reading_ xml.

Clojure has three basic approaches to xml:

1. Parsing as structured data
1. Traversing the structured data as a sequence
1. Manipulating via zippers and their friends

More, the first two of these can be done lazily, allowing for easy processing of huge data sets.  More on this later.

## Parsing xml as structured data

Clojure comes with a built in xml parser - it can parse streams, files, or URIs into nested maps.  Unfortunately it doesn't have a simple way to parse strings, but you can make them into streams and then parse them as follows:

~~~clojure
(defn parse [s]
   (clojure.xml/parse
     (java.io.ByteArrayInputStream. (.getBytes s))))
~~~

Given an xml file like this:

~~~ xml
<top>
Baby, I'm the top
  <mid>
    <bot foo="bar">
      I'm the bottom!
    </bot>
  </mid>
</top>
~~~

calling `(parse xml)` will return a set of nested maps representing the data:

~~~clojure
{:tag :top,
 :attrs nil,
 :content [
   "Baby, I'm the top"
    {:tag :mid, 
     :attrs nil, 
     :content [
        {:tag :bot,
         :attrs {:foo "bar"},
         :content ["I'm the bottom!"]}]}]}
~~~

Once you have nested maps in clojure, you have a huge number of ways to manipulate the data just using language constructs.  For example, you can get the content above with:

~~~clojure
(first (:content (first (:content (second (:content (parse data)))))))

=> "I'm the bottom!"
~~~

Or using the [`->>`](http://clojuredocs.org/clojure_core/clojure.core/-%3E%3E) macro:

~~~clojure
(->> (parse data)
     :content
     second
     :content
     first
     :content
     first
     :content)

=> "I'm the bottom!"
~~~

You can do more than just 'first' and 'second' here - you can add functions to filter data, such as:

~~~clojure
(->> (parse data)
     :content
     (filter #(= (:tag %) :mid))
     :content
     first
     :content
     first
     :content)

=> "I'm the bottom!"
~~~

The `filter` explicitly looks for a child of the :content element with a `:tag` of `:mid`.

## Lazy parsing

Instead of using core.xml you can use the [data.xml](https://github.com/clojure/data.xml) library ([api docs here](http://clojure.github.io/data.xml/)).  This superficially works like the core.xml parser (though happily it has a parse-str function built in) :

~~~clojure
(use 'clojure.data.xml)
(parse-str xml) ; as above
~~~
results in:

~~~clojure
#clojure.data.xml.Element{
  :tag  :top,
  :attrs {},
  :content ("Baby, I'm the top"
            #clojure.data.xml.Element{
              :tag :mid,
              :attrs {},
              :content (#clojure.data.xml.Element{
                        :tag :bot,
                        :attrs {:foo "bar"},
                        :content ("I'm the bottom!")})})}
~~~

The `#clojure.data.xml.Element` values above are [records](http://clojure.org/datatypes) - which implement Map, so our code doesn't have to change.
{: .notice--info}

The big difference isn't immediately obvious: the lists in the `:content` sections, and the `Element`s, are both lazy.  They won't be evaluated until needed - which means you can process huge xml structures this way without needing to load the whole thing into memory.  If you start parsing (say) a 42G wikipedia dump, and you only look at `(first (:content dump))` then the parser will never look beyond the first well formed xml element in the body.

### A quick aside - dumping an xml element for debugging

To make sense of xml traversal, often you'll want to look at an element like the `top` element - and there's a function called `emit-element` that will convert an element back to xml for you.  However, it will convert the *whole* element, including all it's children, to xml.  So I have a couple of handy functions:

~~~clojure
(defn dbg [node]
    (if (associative? node)
      (emit-element (dissoc node :content))
      (emit-element node))
  node)

(defn as-short-xml [node]
  (clojure.string/trim ; remove trailing \n
    (with-out-str
      (if (associative? node)
        (c-xml/emit-element (dissoc node :content))
        (c-xml/emit-element node)))))
~~~

These do essentially the same thing - `dbg` will print a node as xml without it's contents.  Or if you pass it anything else, like a string "I'm the bottom!" it will pass it to emit-element, which will just print it.  And then `dbg` returns the original node for further processing - all the printing is as side effects.

`as-short-xml` instead captures the printed output as a string, and returns that - useful when you want a side-effect free function that returns a string, rather than printing.

## Traversing xml as a sequence

Clojure core includes the [xml-seq](http://clojuredocs.org/clojure_core/clojure.core/xml-seq) function that works on either of the above structures, letting you iterate over the tree of elements in a depth-first fashion.

For example, with our xml above:

~~~clojure
(map as-short-xml (xml-seq (c-d-xml/parse-str data)))

=> ("<top/>"
    "Baby, I'm the top"
    "<mid/>"
    "<bot foo='bar'/>"
    "I'm the bottom!")
~~~

The `xml-seq` function traversed the whole tree lazily from the top to the bottom.

You can of course use all the standard clojure list processing functions on the node sequence - for instance, if you wanted the first node with an attribute:

~~~ clojure
(->> (c-d-xml/parse-str data)
    xml-seq
    (filter #(not-empty (:attrs %)))
    first
    as-short-xml)

=> "<bot foo='bar'/>"
~~~

As I mentioned earlier, this is lazy - once you've found an element with an attribute, and output it, the sequence traversal will stop, and so will the parser.  Of course we are using strings here, so the whole xml string will be in memory, but you can use streams to avoid this as well.  More on this later.

## Zippers

Zippers are probably the easiest way to manage xml - once you grok them.

Zippers are a strange beast. [Wikipedia](http://en.wikipedia.org/wiki/Zipper_(data_structure)) describes them as:

>A technique of representing an aggregate data structure so that it is convenient for writing programs that traverse the structure arbitrarily and update it's contents...

I like to think of a zipper as a kind of pointer to part of a tree - at any time if you have a tree of nodes like the one above, you can have a zipper that refers to a node in the tree, and use it to navigate around the tree.  You can also use the zipper to produce a modified version of the xml document, but I'll leave that for another post.

To get a zipper from an xml tree, you need another library:

~~~clojure
(clojure.zip/xml-zip (parse-str xml))
~~~

The output of this isn't very useful.  Zippers are a little hard to view, because they need to keep track of the entire xml tree they are created from - so every time you output a zipper, you see the whole parsed xml structure, which doesn't help much.

To find out more about the current state of a zipper, you can call `clojure.zip/node`, which returns the node pointed to by the zipper.  Then you can call the same debug functions described earlier.  Here's some short functions to dump zippers:

~~~clojure
(defn dz [zipper] (do
                    (dbg (clojure.zip/node zipper))
                    zipper)) ; return the zipper for more processing
(defn az [zipper] (as-short-xml (clojure.zip/node zipper)))
~~~

## Basic zipper navigation

Zippers, like most of clojure, are immutable - to "navigate" using them, you modify a zipper with a function to get a new zipper.  The basic options are:

1. down - takes you to the first child of this node
2. up - takes you to the parent element of this node
3. right - takes you to the next sibling of this node
4. left - takes you to the previous sibling of this node

[and many many other similar navigation commands](http://richhickey.github.io/clojure/clojure.zip-api.html)

So to continue with our example xml:

~~~clojure
(-> xml
    c-zip/xml-zip
    c-zip/down
    dz
    c-zip/right
    dz
    c-zip/down
    az)

=> "Baby, I'm the top"
"<mid/>"
"<bot foo='bar'/>"
~~~

The first call to 'dz' dumps the first child of the root, the text node "Baby, I'm the top"

Then we move to it's right sibling and dump the value there - the "&lt;mid>" node.

Then we move down to it's first child, and output the "&lt;bot>" node.

I hope this is making sense.  Basically, you move the zipper around the tree to get to the node you want.  Handy for some cases, but still a little strange.

## Data.zip for zipper awesomeness

Basic zippers are just a starting point.  To really make them fly for xml manipulation, I'll use yet another library: [data.zip](http://clojure.github.io/data.zip/)

Data.zip contains the data.zip.xml namespace which has a number of simple and powerful functions that operate on xml zippers and play very nicely together.

## Accessors

There are several functions that given a zipper pointing to an xml node, extract information on it.  For example, using the zipper we had above pointing to the <bot> node, we could call `(attr zipper :foo)` which would return "bar", naturally. `(text zipper)` would return "I'm the bottom!".

There are also predicates similar to these - `(attr= :foo "bar")` returns a predicate that returns true if a given node has a "foo=bar" attribute - so `((attr= :foo "bar") zipper)` would be true.  Similarly `(text= "asdf")` is a predicate that matches based on element text, `(tag= :mid)` matches on tag name.

## Threading magic

Clojure.data.zip has two functions that look and act a little like the `->` threading macro:

**[`xml->`](http://clojure.github.io/data.zip/#clojure.data.zip.xml/xml->)** and **[`xml1->`](http://clojure.github.io/data.zip/#clojure.data.zip.xml/xml1->)**

These work similarly - they take a zipper as a starting location, and then a sequence of matchers.  They apply each matcher in order as follows:

1. If it's a function, call it on the zipper
    1. If it returns a collection, each value of the collection is passed to the next matcher
    1. If it returns a (zipper) location, the location is passed to the next matcher
    1. If it returns true, the current location is passed to the next matcher
    1. If it returns false or nil, this particular matching branch stops
1. If it's a keyword `:foo` it is converted to the predicate `(tag= :foo)` and run as above
1. If it's a string "bar" it is converted to the predicate `(text= "bar")` and run as above
1. If it's a vector, it is converted to a sub query

Note that this can result in more than one value - each matcher can return a collection, which results in more results being passed to later matchers.  The difference between `xml->` and `xml1->` is that `xml->` returns a collection of results, whereas `xml1->` returns only the first not-false-or-nil result.

The actual result is whatever comes out of the rightmost matcher function.

An example may help.  Given our xml yet again,

~~~clojure

(def z (xml-zip (parse-str xml))) ; for convenience

(xml-> z
       :mid
       :bot
       (attr= :foo "bar")
       text)

=> ("I'm the bottom!")
~~~

returns a sequence with a single element `("I'm the bottom")`.  If we'd called `xml1->` it would have just returned a single string.

This worked by taking the <top> node, looking for a child <mid> node, then a child <bot> node, then checking that node had the `foo=bar` attribute, then returning it's text.

Our xml is too simple for much more complex manipulation.  If you want to see more of the things you can do with xml and zippers, have a look at [the test cases for clojure.data.zip](https://github.com/clojure/data.zip/blob/master/src/test/clojure/clojure/data/zip/xml_test.clj) - they are far more useful than the actual documentation!

However, let's move on to a real world example - reading a big big xml file.

## Parsing Wikipedia

Wikipedia is [available for download](http://en.wikipedia.org/wiki/Wikipedia:Database_download#English-language_Wikipedia) as a big gzipped xml file.  And when I say big - it's around 9.5 GB compressed, or 44 GB of xml.  You don't really want to read it into memory.

So lets be lazy.

First some boilerplate - I'm going to include the whole namespace here, so you can try this code yourself if you want:

~~~clojure
(ns wikiparse.core
  (:require [wikiparse.util :refer [dbg as-short-xml dz az]]
            [clojure.xml :as c-xml]
            [clojure.data.xml :as c-d-xml :refer [parse]]
            [clojure.zip :as c-zip :refer [xml-zip]]
            [clojure.data.zip :as c-d-zip]
            [clojure.data.zip.xml :as c-d-z-xml
                :refer [xml-> xml1-> attr attr= text]]
            [clojure.java.io :as io]
            [clj-time.core :as time]
            [clj-time.format :as fmt]
            [clojure.pprint :refer [pprint]])
  (:import [org.apache.commons.compress.compressors.bzip2
              BZip2CompressorInputStream]))

(defn bz2-reader "produce a Reader on a bzipped file"
  [filename]
  (-> filename
      io/file
      io/input-stream 
      BZip2CompressorInputStream.
      io/reader))
~~~

The bz2-reader function will unzip the file on the fly - it's all streams and readers, so you don't need to store the whole thing in memory.

Let's start parsing the xml.  First, we'll define a reader - note, this is not something you'd ever do outside a repl, as using `def` like this puts the reader in a global symbol.  See further down for better ways to handle readers.

Then we can start parsing the xml:

~~~clojure
(def rdr (bz2-reader "wikipedia.xml.bz2"))

(def x (parse rdr))

(:tag x)

=> :mediawiki

(-> x :content first :content first :content)

=> ("Wikipedia")
~~~

The top few lines of the wikipedia dump are:

~~~xml
<mediawiki xmlns="..." version="0.8" xml:lang="en">
  <siteinfo>
    <sitename>Wikipedia</sitename>
~~~

so this looks right.

Most of the wikipedia dump is a long sequence of `<page>` tags similar to:

~~~xml
  <page>
    <title>Autism</title>
    <revision>
      <id>557666522</id>
      <timestamp>2013-05-31T11:04:03Z</timestamp>
      <text xml:space="preserve">
... lots of text here
      </text>
      <model>wikitext</model>
      <format>text/x-wiki</format>
    </revision>
  </page>
~~~

though there are some which are just redirect stubs:

~~~xml
  <page>
    <title>AccessibleComputing</title>
    <redirect title="Computer accessibility" />
    <revision>
      <id>381202555</id>
      <timestamp>2010-08-26T22:38:36Z</timestamp>
      <text xml:space="preserve">#REDIRECT [[Computer accessibility]] \{\{R from CamelCase\}\}</text>
      <model>wikitext</model>
      <format>text/x-wiki</format>
    </revision>
  </page>
~~~

Let's look for the first few titles.  How about we use the zipper stuff from before?

~~~clojure
(take 10
      (xml-> z
             :page
             :title
             text))
=> ("AccessibleComputing" "Anarchism" "AfghanistanHistory" "AfghanistanGeography" "AfghanistanPeople" "AfghanistanCommunications" "AfghanistanTransportations" "AfghanistanMilitary" "AfghanistanTransnationalIssues" "AssistiveTechnology")
~~~

Cool - how about we test laziness, let's look for the 1000th title:

~~~clojure
(nth (xml-> z
            :page
            :title
            text)
     10000)
=> "Integral domain"
~~~

Awesome - how about the 100,000th?

~~~clojure
(nth (xml-> z
            :page
            :title
            text)
     100000)
Exception in thread "RMI TCP Connection(idle)" java.lang.OutOfMemoryError: GC overhead limit exceeded
~~~

Oops - what happened to that laziness?

## Laziness - Lose your head

The trouble is, we have a reference to the original parsed xml structure in the symbol `x`.  This means that even though the pages are expanded lazily, the old pages we've looked at can't be fully garbage collected, as their parent `x` still has a reference to them.

This is called "head retention" in clojure - it's not uncommon with lazy sequences.  If you keep a reference to the head of a sequence, it can't be garbage collected.

*Worse*, the zipper library does the same thing.  Every zipper can be traversed to find it's parent - so every zipper keeps a reference to it's parent.

So we have to go back to simple structure parsing.  Don't worry, we won't throw away *all* the zipper functionality - you just have to use it on each child node, not the overall tree.

~~~clojure
(defn page-title [element]
  (xml1-> (xml-zip element)
          :title
          text))

(with-open [rdr (bz2-reader "wikipedia.xml.bz2")]
  (nth (->> rdr
         parse
         :content
         (filter #(= :page (:tag %)))
         (map page-title))
       100000))

=> "Flatonia, Texas"
~~~

(Note: with-open is a macro that automatically closes the reader when we're done)
{: .notice--info}

Success!  Getting rid of the symbol `x` means we aren't keeping the head around - and we can still use a zipper within the `page-title` function to manipulate the individual page.  For a simple task like this it is probably overkill, and will add a fair bit of overhead - especially as we are mapping the page title for the 99,999 pages we don't care about.  But the minute you want to filter or act on the page contents, you'll need that processing.

And this still only took 135 seconds, using 123 MB peak RAM on my laptop - not too bad for an unoptimised scan through 100,000 xml nodes.

## Data processing with lazy sequences

Clojure excels at processing sequences of stuff.  The wikipedia data is a bit simple for a great example, but it's a start.

First, lets write a function to transform a wikipedia xml sub-document into a useful structure:

~~~clojure
(defn page->map [page]
  (let [z (xml-zip page)]
    {:title     (xml1-> z :title text)
     :redirect  (xml1-> z :redirect (attr :title))
     :id        (xml1-> z :revision :id text)
     :timestamp (fmt/parse (xml1-> z :revision :timestamp text))
     :text      (xml1-> z :revision :text text)}))
~~~

Note I've been a bit lazy here with error checking - if there is no timestamp element this will crash horribly.
{: .notice--info}

Now let's get the first few entries:

~~~clojure
(with-open [rdr (bz2-reader filename)]
  (doall
    (take 4
          (->> rdr
               parse
               :content
               (filter #(= :page (:tag %)))
               (map page->map)))))
~~~

One strange thing I had to do here is use `doall` - this is to force non-laziness.  Clojure's laziness is great generally, but without `doall` you will get:

~~~
XMLStreamException ParseError at [row,col]:[85,2582]
Message: Stream closed  com.sun.org.apache.xerces.internal.impl.XMLStreamReaderImpl.next (XMLStreamReaderImpl.java:596)
~~~

Why?  This is a common point of pain in dealing with lazy sequences - you need to make sure you force non-lazy behaviour before you lose your data source or connection or similar.  In this case, the `with-open` call opens a file for streaming - but everything inside the `take 4` call is only processed when output is needed.  Which is after `with-open` has closed the reader on you!

So you need to add a `doall` first, which takes those 4 lazy results and forces them to be evaluated as concrete results. You wouldn't need this if all the processing of the sequence was forced within the `with-open` call in some other way.

Anyway, back to the output of the above:

~~~clojure
({:title "AccessibleComputing",
  :redirect "Computer accessibility",
  :id "381202555",
  :timestamp #<DateTime 2010-08-26T22:38:36.000Z>}
 {:title "Anarchism",
  :redirect nil,
  :id "557411769",
  :timestamp #<DateTime 2013-05-29T21:19:48.000Z>}
 {:title "AfghanistanHistory",
  :redirect "History of Afghanistan",
  :id "74466652",
  :timestamp #<DateTime 2006-09-08T04:15:52.000Z>}
 {:title "AfghanistanGeography",
  :redirect "Geography of Afghanistan",
  :id "407008307",
  :timestamp #<DateTime 2011-01-10T03:56:19.000Z>})
~~~

(I removed the text for clarity)

Ok, now we have structured data we can process it.  Let's say we want to know the first 4 articles last updated before 2008?  Ignoring redirects, of course.

~~~clojure
(with-open [rdr (bz2-reader filename)]
  (doall
    (take 4
          (->> rdr
               parse
               :content
               (filter #(= :page (:tag %)))
               (map page->map)
               (remove :redirect)
               (filter #(time/after? (time/date-time 2008) (:timestamp %)))))))

=>
({:title "Wikipedia:Complete list of encyclopedia topics (obsolete)",
  :redirect nil,
  :id "31953688",
  :timestamp #<DateTime 2005-12-19T09:54:11.000Z>}
 {:title "Wikipedia:Complete list of encyclopedia topics (obsolete)/6",
  :redirect nil,
  :id "15904520",
  :timestamp #<DateTime 2005-05-16T07:18:26.000Z>}
 {:title "Wikipedia:Complete list of encyclopedia topics (obsolete)/7",
  :redirect nil,
  :id "15904521",
  :timestamp #<DateTime 2005-05-16T07:18:30.000Z>}
 {:title "Wikipedia:Complete list of encyclopedia topics (obsolete)/8",
  :redirect nil,
  :id "15904522",
  :timestamp #<DateTime 2005-05-16T07:18:56.000Z>})
~~~

Hmm - kind of boring.  Let's strip the obsolete pages:

~~~clojure
(with-open [rdr (bz2-reader filename)]
  (doall
    (take 4
          (->> rdr
               parse
               :content
               (filter #(= :page (:tag %)))
               (map page->map)
               (remove :redirect)
               (filter #(time/after? (time/date-time 2008) (:timestamp %)))
               (remove #(re-find #"\(obsolete\)" %))))))
=>
({:title "Wikipedia:GNE Project Files/Proposed GNU Moderation System",
  :redirect nil,
  :id "57629800",
  :timestamp #<DateTime 2006-06-09T01:38:24.000Z>}
 {:title "Wikipedia:GNE Project Files/GNE Project Design",
  :redirect nil,
  :id "57629879",
  :timestamp #<DateTime 2006-06-09T01:39:07.000Z>}
 {:title "Wikipedia:GNE Project Files/Project Name",
  :redirect nil,
  :id "15910103",
  :timestamp #<DateTime 2004-04-14T22:22:01.000Z>}
 {:title "History of the Virgin Islands",
  :redirect nil,
  :id "155442896",
  :timestamp #<DateTime 2007-09-03T16:52:44.000Z>})
~~~

This should give you a taste for what you can do.  Finding the above on my laptop took almost a minute - I'm not sure how far through the wikipedia dump it searched.  Counting the number of skipped pages is left as an exercise for the reader!

## Conclusion

This is still a pretty simple data structure.  In many environments you will probably find some much worse examples - my most recent project involved parsing [xbrl](http://www.xbrl.org/specification/gnl/rec-2009-06-22/gnl-rec-2009-06-22.html) which was a lot of fun.  If you meed this sort of xml, you'll really appreciate having a language like clojure on hand.

I also haven't touched on modifying xml - the zipper frameworks have a lot of tools for on-the-fly modification of xml documents, but that's something for another article.
