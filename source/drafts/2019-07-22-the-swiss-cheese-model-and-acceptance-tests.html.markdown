---

title: The swiss cheese model and acceptance tests
date: 2019-07-22 16:35 GMT
tags: testing tech 

---

## Testing and Agile
I've seen testing, especially acceptance testing, done horribly wrongly over the years, and sadly I often see the same anti-patterns repeated over and over; so I thought it'd be worth talking about my perspectives on this thorny subject.

First off, I think it's worth emphasising that _automated testing is at the heart of agile software development_.  Agile development assumes "building quality in", and that means tests. I've seen places with _no_ tests, or nothing but a suite of slow fragile end-to-end tests run on a snowflake environment, who want to "go agile".  You can't just "go agile" without a solid underpinning of low-level tests that _enable_ you to move fast without breaking things.  Going agile without good tests is like embracing modern surgery but skipping all that pointless handwashing stuff.

All of this is doubly true when moving towards continuous delivery - I strongly recommend people read the "Technical Practices" chapter in "_Accelerate_" [^accelerate] (really, just go read the whole book - it's awesome, providing the _data_ behind the benefits of agile and CD).

## The test pyramid

A classic metaphor in automated testing is [the test pyramid:](https://martinfowler.com/bliki/TestPyramid.html) 

![test pyramid](../2019-07-22-the-swiss-cheese-model-and-acceptance-tests/Testing_Pyramid.svg)

it's been a useful model for ages, and still a good conversation starter, but it lacks a few things:

- It isn't clear really what the horizontal dimension is - does wider mean more tests? More test scenarios? More features tested?
- It isn't clear what the vertical dimension is - where do contract tests fit? What about chaos engineering / resiliency tests?  What if you test at an API not a UI?  Should you test in a particular order?
- In many cases the best shape is nothing like a pyramid - some systems are well suited to integration tests, and tend to a pear-shape.  Some systems are more of an hourglass, with lots of UI/API tests and lots of unit tests and not much between.

I've seen people tweak the pyramid - adding layers, adding axes, adding explanations - but fundamentally I think it's a bit flawed.

## A different perspective - Swiss Cheese

I recently came across a new-ish metaphor: the Swiss Cheese model of testing - which I quite like. It's a lot more nuanced than the old Test Pyramid, and helpful when it comes to talking about both _why_ we test, and _how_ we should test.

The basic idea is: consider your tests like a big stack of swiss cheese slices - you know, the kind with holes in them:

![swiss cheese](../2019-07-22-the-swiss-cheese-model-and-acceptance-tests/Swiss_cheese.jpg)

Now layer those cheese slices vertically - each layer represents a different kind of tests.  Order them in the order you run them - usually simplest, fastest feedback first, then slower layers below them:

![swiss cheese slices](../2019-07-22-the-swiss-cheese-model-and-acceptance-tests/test_swiss_cheese.svg)

You can imagine defects as physical bugs which fall down the diagram, and are caught at different levels - different slices of cheese.

Some bugs might fall all the way through a series of holes and not get caught.  This is bad.

![swiss cheese slices](../2019-07-22-the-swiss-cheese-model-and-acceptance-tests/bug_catching.svg)

Each layer, and each kind of test, has different tradeoffs such as:

- *How fast is the feedback cycle?* Can developers know they have a problem _as they type_ (e.g. with a linter), or as soon as they save a file, or [when they run a 10 second test suite](https://blog.ploeh.dk/2012/05/24/TDDtestsuitesshouldrunin10secondsorless/)? Or do they have to wait until the evening after they pushed their code changes?  Continuous Integration is what we'd like - every commit runs every test - but some layers are going to be slow or expensive.
- *How fragile are the tests?* - do they fail in confusing and obscure ways? Are they reliable, failing the same way from the same problem? Or failing the same way from different problems?
- *How expensive are the tests?* - do they take a lot of effort to write? Do they need re-writing whenever you change code?

And each layer has holes - things that are not sensible to test at that level.  You don't test your exception handling in a browser test.  You don't test your microservice interactions in a unit test.

_Note_ I haven't prescribed what the precise test phases are - there's a lot of "it depends" on choosing your tests.  There's a whole other blog post to be written about my preferred test layers!

A basic principle here though is - *don't repeat yourself*. There's not a lot of value testing the same thing multiple times.  The cheese layers will always overlap a bit - but if you have a fast simple unit test to verify the text of a validation message, don't also have a slow fragile browser-based end-to-end test that verifies the same thing!

This is especially true of manual tests - the typical top of the classical test pyramid.  You shouldn't manually re-test what you have automatically tested.  You might "kick the tyres" to make sure that everything works OK.  You might test in production, relying on monitoring and A/B testing to identify problems early.  But you really want to catch everything you can before that point!

Also it's somewhat up to you to decide what is most appropriate for which layer.  Fast feedback is good, but so are clear expressive tests that are easy to change.  A classic example is database interactions - it's almost always better to test against a real database, possibly an in-memory one, than to try to mock it out.

# Acceptance tests

One "cheese slice" I definitely *don't* want to see is the "acceptance tests" slice.  Don't get me wrong, I love acceptance tests, I love the idea of defining "done" for a user story by clear unambiguous tests.

But too many people assume there must be an accepance test stage - a single "slice" in this model - which contains all the acceptance tests.  This means those tests usually end up near the bottom of the pile, in a suite of large slow expensive browser-driven tests, that have to run against a production-like environment.

Sure, that's appealing - lots of us started like that, learning the magic of BDD and Cucumber and Selenium, building amazing suites of exhaustive browser-based tests.  But that magic was _slow_, and _fragile_ - and no amount of tinkering with clever setups and special approaches got past the fact that the tests took far far too long to run, and were fragile, and hampered rapid development.

Besides, they encouraged people to only think of "acceptance" in terms of "clicks and buttons" - where were the tests for "it should handle network failures gracefully" or "it should send exception logs to the auditing system"?

(I do think there's value in _some_ browser-driven end-to-end tests - there are bugs you can only catch that way.  But call them "smoke tests" or "end-to-end tests" or something, not "acceptance tests".  If you want lots of tests of UI features, consider tools that test within the framework you use, like [enzyme](https://airbnb.io/enzyme/) for react - you might want several "cheese slices" of UI tests - see [how the material UI tests are layered](https://github.com/mui-org/material-ui/blob/master/test/README.md) for an example.)

In my opinion, acceptance criteria should be tested at _whatever level is most effective_ for testing that requirement:

![acceptance tests](../2019-07-22-the-swiss-cheese-model-and-acceptance-tests/acceptance_tests.svg)

If the acceptance criterion is "it should have the title `Fnord Motor Company`" then that can be a simple browser-based test against a stubbed back end.  If the acceptance criterion is "it should not accept a password shorter than 10 characters" then that might be a pair of unit tests, one to check that the UI validation is good, and one to check that the server-side validation is good. If the acceptance criterion is  "it should respond within 30ms under peak load" then that might be part of a performance test suite.

If you really feel the need to trace acceptance tests back to stories, you can probably work out a way to tag the tests and report on them somehow - but I'd ask, why bother?  Are you ever going to use that information?  Maybe it's sufficient to just list the tests in the stories, and check they are there as part of signing the story as done, and not try to track the relationship beyond that.

## User stories are a point in time, tests are forever

Another problem with an Acceptance Test layer, is that user stories express the requirements at the time the story was written - usually with changes right up to the point of delivery.  At the time of finishing a story, acceptance tests will demonstrate it works - but the next story, or the one after that, will change the behaviour.  If your tests are too strongly structured around the stories, they can hamper change - you need to think "OK, it's now the `Flawed Motor Company`, I need to find all the old acceptance criteria that might have tested for this".  

And again, this is especially time consuming if that test is in a UI-based test suite which takes a long time to run and is hard to debug.

If your acceptance test was just a note in the original story "this is demonstrated by the view-layer test XYZ" then you wouldn't need to change anything except the single failing test - if there was ever a pressing need to prove the original acceptance criteria were checked,  a code archeologist could dig through version control history to find the test XYZ at the time the story was completed.

## The QA role and test slices

This also highlights a common organisational problem - when there is an individual or team whose role is entirely Quality Assurance, and who tests independently to the rest of the team.

It is only natural that this kind of QA will tend to work at a single layer - without close collaboration with developers, it is next to impossible to work with unit test or other fast feedback layers.

And this is a reason why you shouldn't test this way!  Don't get me wrong, I'm not advocating getting rid of QA folks - a good QA specialist can be an invaluable team member.  But they should be working _with_ the developers, to encourage them to write good tests, to spot the gaps in their test automation, and to provide a vital whole-project perspective on quality.

The "Accelerate" [^accelerate] folks put it better than I can: 

> [context: talking about qualities of high performing teams]
>
> Developers primarily create and maintain acceptance tests, and they can easily
> reproduce and fix them on their development workstations. 
>
> It is interesting to note
> that having automated tests primarily created and maintained either by QA or an
> outsourced party is not correlated with IT performance.
>
> The theory behind this is
> that when developers are involved in creating and maintaining acceptance tests,
> there are two important effects. First, the code becomes more testable when
> developers write tests. This is one of the main reasons why test-driven development
> (TDD) is an important practice‚ as it forces developers to create more testable designs.
> Second, when developers are responsible for the automated tests, they care more
> about them and will invest more effort into maintaining and fixing them.
>

> None of this means that we should be getting rid of testers.  Testers serve an essential role in the software delivery lifecycle, performing manual testing such as exploratory, usability, and acceptance testing, and *helping to create and evolve suites of automated tests by working alongside developers*.

The best QAs I've worked with were awesome assets to the team.  They didn't write that many tests on their own though - instead they worked closelt with developers to ensure that they understood their tests, that the tests covered as many cheese holes
as possible, and that the test fitted in with their big-picture vision of the overall testing suite - Were tests at the right level? Was enough being tested?  Were acceptance criteria being met? And what areas would still need exploratory testing?

# In summary

* Write tests at as low a level as is sensible.
* Write tests that cover all the things that could go wrong.  Where you can.
* Don't repeat yourself!
* Integrate continuously - and run all the tests on each commit.  Or as many as you can.
* Define acceptance criteria, and write acceptance tests, at the lowest level that makes sense.
* Let the QAs overview the tests, let the developers write them, work as a team.

Comments? Questions? See the comments section at the bottom of this page.

----

## Various references:

[Wikipedia](https://en.wikipedia.org/wiki/Swiss_cheese_model) has an article about this metaphor in accident causation - this seems to date the idea back to 1990, when looking at layered threat mitigations

[Glennan Carnie - the Swiss Cheese Model](https://blog.feabhas.com/2011/12/effective-testing-the-swiss-cheese-model/) is a good introduction to the metaphor, but seems to talk more about static analysis than kinds of tests

[My colleague Sarah Hutchins wrote this article recently about the Swiss Cheese Model](https://semblanceoffunctionality.com/swiss-cheese-model/) - with a bit of a different focus, looking at strategic decisions about what to test where. [Vinod Kumaar R's article](https://vinodkumaar.wordpress.com/2018/03/05/swiss-cheese-model-to-understand-test-coverage/) has more useful perspectives.

[Martin Fowler](https://martinfowler.com/bliki/TestPyramid.html) has a good basic article about the Test Pyramid in his bliki, and the same site also has [Ham Vocke's article with more practical examples](https://martinfowler.com/articles/practical-test-pyramid.html)

I also quite like [Gregory Paciga's "testing is like a box of rocks" metaphor](https://gerg.dev/2018/05/testing-is-like-a-box-of-rocks/)

## Image sources:

<a href="https://commons.wikimedia.org/wiki/File:Swiss_cheese.jpg">Swiss cheese</a> image by <a href="https://commons.wikimedia.org/wiki/User:Ekg917">Ekg917</a>, <a href="https://creativecommons.org/licenses/by-sa/4.0/legalcode" rel="license">CC BY-SA 4.0</a> 

Test Pyramid image by Abbe98 [<a href="https://creativecommons.org/licenses/by-sa/4.0">CC BY-SA 4.0</a>], <a href="https://commons.wikimedia.org/wiki/File:Testing_Pyramid.svg">via Wikimedia Commons</a>

## Thanks:

- to my colleagues [Nishi Ningegowda](https://twitter.com/googflow), [Jim Barritt](https://twitter.com/jimbarritt), [Steve Aylward](https://twitter.com/staylward), and of course [Becky Thorn Sietsma](https://twitter.com/becky_thorn) for their useful feedback!

## Footnotes:

[^accelerate]:  Nicole Forsgren, Jez Humble & Gene Kim - Accelerate <https://itrevolution.com/book/accelerate/>
