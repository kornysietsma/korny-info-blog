---
title: Using Chaos Engineering to test-drive your architecture
date: 2019-04-24 10:21 GMT
tags: 
layout: layout
---

<!--
Local url: http://127.0.0.1:4567/drafts/2019-04-chaos-engineering.html
-->

<!-- To cover:

  * Evolutionary architecture and fitness functions http://evolutionaryarchitecture.com/ffkatas/list.html
  * Russ' toolkit
  * Incremental - test one thing at a time
  * The importance of visualisation\
  * Bureau of Sabotage? https://en.wikipedia.org/wiki/Bureau_of_Sabotage
 -->

- TOC
{:toc}

## Introduction
Chaos Engineering tools and techniques are extremely useful for anyone planning or operating a distributed system.  I want to talk about our experiences using Jepsen, and a bit of Chaos Monkey, to test-drive a client's architecture - enabling us to validate their plans, based on data derived from tests, rather than based on theorising or guessing.

A lot of Chaos Engineering discussion talks about disrupting your systems in production - and while I think this is an excellent thing to do, we also found a lot of value _incrementally_ testing our systems - working out how they break in controlled simplified environments, before trying to identify failures in a genuine production configuration.

I also see these techniques as a great enabler for [evolutionary architecture](http://evolutionaryarchitecture.com/precis.html) - you can use chaos engineering to develop automated fitness functions, so you can be sure your systems are still resilient and reliable even as your architecture grows and evolves over time.

### What is Chaos Engineering?

Frank Herbert had a concept in some of his Science Fiction stories of a ["Bureau of Sabotage"](https://en.wikipedia.org/wiki/Bureau_of_Sabotage) - a quasi-official group whose job was to interfere violently with the smooth workings of a futuristic perfect government.

[Chaos Engineering](https://en.wikipedia.org/wiki/Chaos_engineering) feels a bit similar - your goal is to deliberately break things, to mess up the smooth workings of your systems so you can see the hidden faults and failings; so you know how things will break before they break naturally.

Critically, you don't need to be building a massively complex system to benefit from this!  Even if you are "just" using someone else's distributed database or queue, you still need to answer a few key questions:

* How should you configure your systems?  Network topology, timeouts, client setup - there are a lot of settings to consider.
* What happens when something goes wrong - can you guarantee no data loss? Will you be alerted? Is it possible to manually repair things in the worst case?
* What are the tradeoffs between performance, resiliency, and cost?

### What does "resilience" mean?

*TODO: look up a nice definition?*

This is a very complex question! If you want to know more, you could check out [Aphyr's detailed hierarchy of consistency models](https://jepsen.io/consistency) or there is some great coverage in [Martin Kleppmann's "Designing Data-Intensive Applications"](https://www.goodreads.com/book/show/23463279-designing-data-intensive-applications).  TODO: other references?  Is Aphyr too low level?  Does Martin have anything?

For our specific purposes, we were helping a client evaluate a system with fairly standard requirements:

- It has to have a good up-time - it needs to be distributed across multiple data centres, so even if a significant outage occurs, users should be able to keep using the system to some degree, even if only to read data.
- It has to never lose committed user data - if a user hit a "save" button and the system responds with "OK", the data should be saved.
- It has to recover from some faults automatically - intermittent failures should not cause major outages.
- It has to handle exceptional situations well - if something goes badly wrong, we still want to be able to manually recover.

#### Dealing with Partitions
There are a lot of things that can go wrong in a distributed system, but often it's worth focusing on one of the worst situations - a network partition.  Other problems like having a server crash can be dangerous, but not as complex to solve as when your servers are alive, but not talking to each other - this can lead to a "split brain" situation where your distributed system has two or more views of reality, and all consensus is lost.

#### Doesn't CAP theorem mean ... 

Sigh.  A lot of distributed system discussions spend too much effort talking about CAP theorem. I like the [CAP FAQ](https://www.the-paper-trail.org/page/cap-faq/) for a good summary - fundamentally:

- Partitions are _going to happen_ - you can never assume "P" is negotiable, unless you are running on a single server.
- So really you need to decide - when something goes wrong, which is more important, consistency or availability? Would you prefer to show users a warning page, or invalid data?
- Also, there are multiple levels of "consistency" - see [Aphyr's neat chart](https://jepsen.io/consistency) - and each higher degree of consistency comes with extra tradeoffs.

#### How does MongoDB approach resilience?

MongoDB uses a quorum-based consensus approach - this is quite common among distributed data stores, though many delegate to tools like consul, etcd or zookeeper to manage the consensus:

![Common resiliency architecture diagram](2019-04-chaos-engineering/resiliency1.png)

- Several distributed nodes have databases operating on replicas of the same data
- The databases have some sort of consensus mechanism that elects a "Primary" node on start-up, and re-elects one if something goes wrong.
- Clients use a discovery mechanism to know which is the current primary node, and to redirect to a different primary if it changes
- Clients write data to the primary node, which then replicates changes to other nodes
- Clients read data from the primary node by default
  - Clients may get less critical data in other ways for better performance - monthly reports might not need to be 
- Nodes communicate between themselves, to replicate data and to detect and handle failures

A network partition is where some or all nodes can't see each other.  A simple case is where some non-primary nodes are split from the rest:
![Split with primary majority](2019-04-chaos-engineering/resiliency2.png)

In this case, the left-hand network is OK - clients can still talk to the primary, these nodes might panic a bit: "We can't see some nodes! Oh no!" - but you still have more than 50% of the network available.  This is how consensus systems work - the majority of nodes can see each other, they can maintain consensus about the state of the data.

The right-hand two nodes will panic, but they can't get a consensus so they will stay in a failed state until the network comes back.

What if the network splits like this?
![Split with primary minority](2019-04-chaos-engineering/resiliency3.png)

Now, the left-hand side no longer has a majority and should detect an error state.  The right-hand network has the majority of nodes, it can only assume that the primary has crashed, and it will trigger a new election and find a new primary.

A client connected to the old primary will need to be redirected somehow to the new primary (if it can see it!) - for example the client may have a list of all node IP addresses, so it can ask other nodes where the primary is now.

You can increase the reliability of writes and reads, at the expense of performance, by tweaking how you trust the distributed network.  In MongoDB you can use [write concerns](https://docs.mongodb.com/manual/reference/write-concern/) to say "Don't count data as written successfully until the majority of nodes have confirmed they have seen it", and similarly [read concerns](https://docs.mongodb.com/manual/reference/read-concern/) to say "Don't return un-committed data from queries".  Tweaking these options is complex though - which is why it's good to test them!  I'll try to cover a few more specific examples later in this article.

*Note* - this is a deliberately brief and incomplete introduction to this topic.  If you want more gory details, you are far better off reading [Martin Kleppmann's book mentioned earlier](https://www.goodreads.com/book/show/23463279-designing-data-intensive-applications)) or *TODO* suggest other background reading

### So how do you test this?

This is where Chaos Engineering comes in!

The [original idea](https://en.wikipedia.org/wiki/Chaos_engineering#History) came from Netflix's experiences building large-scale cloud-based systems.  They had the idea of deliberately causing breakdowns in their production systems - having their own "Bureau of Sabotage" who would deliberately break things, to make sure that their overall system was genuinely resilient - if the systems are genuinely resilient, when  a server crashes, or a network switch dies, the problems will self-heal and end-users should never know anything was wrong.

As I mentioned earlier, testing in production is a powerful approach for mature organisations - but there's also value in using similar approaches to test failure *incrementally and iteratively*, starting with testing simple failures in isolated systems that you can completely control.

Our Jepsen-based approach was broadly:

#### 1. Set up a test system

The first stage of testing is to build a system to test system - containing a subset of what you'd have in production; client systems, database servers, and associated monitoring and logging.

We used an [Infrastructure as Code](https://infrastructure-as-code.com/) approach - everything we did was written as version-controlled code, so our environments, tests and outputs were clear and repeatable.

#### 2. Break the test system

The next stage is to break things!  There are thousands of things that can go wrong - we used Jepsen and Chaos Monkey tools to inject problems into the systems as they operated.

Again, everything was scripted as code, everything was version controlled, and all outputs were stored for analysis.

#### 3. Analyse the results

This is typically a mix of automated and manual analysis.  We used automated analysis to gather immediate feedback on "what went wrong" and "how much data did we lose".  And manual review of the output to understand more about "why?" and to look at things to tweak and change.

#### 4. Document the results

This is a key part of our approach - as we work, we document what we did.  Again, everything is scripted, everything is code - our documents were grown from AsciiDoc text files, and automated graphs built from logs, and automated screenshots taken from monitoring tools.

#### 5. Iterate!

This isn't an approach you can plan and execute in a waterfall fashion.  By it's very nature, you need to incrementally grow a suite of things to test - you need to iterate on what failures to simulate, you need to iterate on your network topology, you need to iterate on the complexity of your tests - from simple "let's break a 3-node network" potentially all the way to "let's run tests in production"

## Applying this in practice - our Chaos Engineering experience report

A few years ago one of our large clients was in the process of building a new system based on a microservices architecture, and they asked us to provide an early review of their planned approach, especially how they planned to use MongoDB as a distributed store for their user data.
After our initial review of their plans we suggested that it would be best to actually _test_ their approach, rather than just trying to reason about it.

So we agreed to set up a small team to build out some tests.  We chose to initially use [Jepsen](https://jepsen.io/) for a chaos engineering tool - we had some familiarity with Clojure, and it seemed like a good tool for our planned iterative approach; we also used the [Yahoo Cloud Serving Benchmark](https://en.wikipedia.org/wiki/YCSB) for some load testing, though this article is mostly focusing on the Jepsen tests.

### What is Jepsen?

Jepsen is an [open source](https://github.com/aphyr/jepsen) systems testing library, written in Clojure by Kyle Kingsbury aka [Aphyr](https://aphyr.com/about). It allows you to set up a distributed system, run a bunch of destructive operations against that system, and verify that the history of those operations make sense.

Jepsen is _not_ a load testing tool or a general purpose chaos engineering toolkit - there are other tools that may be better for other kinds of testing.  (And there are newer tools emerging in this space - I'll list some other options to try later in this article)

But it's very powerful for building simple isolated tests, and analysing the results in quite sophisticated ways.

#### How is a Jepsen test structured?
Very broadly, Jepsen consists of a client and a number of distributed nodes:
![Jepsen overview](2019-04-chaos-engineering/jepsen.png)

The Jepsen client does most of the work - it runs the main clojure application, which spawns a number of worker threads, and a single `nemesis` thread.

The client communicates with a number of nodes, typically named `n1`, `n2`, `n3` and so on.  These can be real servers, or for playing around you can use Docker or Vagrant to set up a virtual network.  Jepsen provides basic tools for configuring the servers; we used these for initial experimentation but ultimately it was easier for us to configure them using a mature tool like Ansible.

At the core of the client is a `test` definition, which consists of a map of a number of things:

- the name of the test
- the nodes being tested against
- a [`client`](https://github.com/jepsen-io/jepsen/blob/master/jepsen/src/jepsen/client.clj) definition - clients that do normal operations during your test
- a [`nemesis`](https://github.com/jepsen-io/jepsen/blob/master/jepsen/src/jepsen/nemesis.clj) definition - the thing that is going to break something
- a [`generator`](https://github.com/jepsen-io/jepsen/blob/master/jepsen/src/jepsen/generator.clj) - this generates operations for your test.  More on generators in a bit.
- a `model` - this represents the abstract behaviour of a system, for correctness checking
- a `checker` - this is run at the end of the test to see if the history of the system corresponds to the given model
- a bunch of other standard things that clients and the rest might need

You can read more about setting up basic Jepsen tests in the [Jepsen tutorial](https://github.com/jepsen-io/jepsen/blob/master/doc/tutorial/index.md)

A key concept is the generator - it lets you compose operations and nemeses together in all sorts of different ways.  For example [in the Jepsen tutorial](https://github.com/jepsen-io/jepsen/blob/master/doc/tutorial/03-client.md) there is a test with a simple generator:

~~~clojure
  :generator (->> r
                (gen/stagger 1)
                (gen/nemesis nil)
                (gen/time-limit 15))}))
~~~

Here `r` is the operation - in this example a "read" operation".  `gen/stagger` introduces random noise in the timing between operations.  `gen/nemesis` defines what happens on the `nemesis` process (nothing in this case).  And `gen/time-limit` stops the generators after 15 seconds - otherwise the generator will keep producing operations forever.

Generators are a fairly complex thing to get your head around - it's worth reading the source at <https://github.com/jepsen-io/jepsen/blob/master/jepsen/src/jepsen/generator.clj> - you need a decent grounding in clojure too.  Fundamentally a generator is a stateful object which spawns a sequence of "operations", potentially separated by `sleep`s to delay the rate of tests.

The Jepsen test runner orchestrates all of the above components:

- It opens an ssh session to each server node
- It sets up the operating system and databases if needed
- It creates a nemesis thread, and a pool of client threads
- It creates a global history list for capturing operation history
- Each thread cycles through the generator, generating each operation requested with the timing specified
  - Each operation is executed on the appropriate client thread
  - The nemesis operation is executed as requested on the nemesis thread
  - The result of each operation is appended to the history

Once the generator runs out of new operations:

- tear down any databases / server settings
- invoke the checker with the model and any accumulated history, returning success/failure.

#### How do checkers work?

For rigourous tests of linearizability, Jepsen uses the [Knossos](https://github.com/jepsen-io/knossos) library to examine the entire history of a test run, and detect whether the history was actually linearizable.

For most of our tests, this is overkill.  We aren't really trying to prove if our operations are strictly linearizable - we mostly wanted a broader understanding of how many operations failed/succeeded, which we could do by other cheaper approaches.  So we just created custom checkers to validate overall stats for each experiment.

### Early testing - setup and exploration

Like I mentioned earlier - the only way to go about this is iteratively.  We started by going "broad" - testing a lot of small things fairly quickly, and then narrowing down to the _important_ things once we had an idea of how to test, what failure modes there were, what tests were worthwhile, and what we needed to measure.  

The [Cockroach Labs blog article on their Jepsen approaches](https://www.cockroachlabs.com/blog/diy-jepsen-testing-cockroachdb/) were invaluable at this stage - especially as they link to their git history so we could play along with their different stages of maturity.

For an example of the sort of tests we wrote while experimenting - we wrote a test client which created a single MongoDB document in a collection, then repeatedly appended integers to a list in that document:

~~~clojure
(defrecord Client [db-name
                   coll-name
                   id
                   client
                   coll]
  client/Client  ; implements the Jepsen Client protocol
  (setup! [this test node]
    (info "setting up client on " node )
    (let [client (mongo/cluster-client test)
          coll   (-> client
                     (mongo/db db-name)
                     (mongo/collection coll-name))]
      ; Create initial document
      (mongo/upsert! coll {:_id id, :value []})

      (assoc this :client client, :coll coll)))

  (invoke! [this test op]
    (util/with-timing-logs op
      (util/with-mongodb-errors op #{:read}
        (case (:f op)
          :read (read-doc op coll id)
          :add (add-int-to-doc op coll id)))))

  (teardown! [_ test]
    (.close ^java.io.Closeable client)))
~~~

This client boils down to:

- Create a single MongoDB document with a constant ID and an empty `value` array
- When a `:read` operation is executed, read the document
- When an `:add` operation is executed, add an integer to the array in the document (it uses the MongoDB [$push](https://docs.mongodb.com/manual/reference/operator/update/push/) operator internally)
- There are also wrappers like `with-timing-logs` and `with-mongodb-errors` to make sure we track how the commands performed, and handle any MongoDB exceptions correctly.

Our actual test definition: (note that we pass the chosen delay and nemesis functions as parameters)

~~~clojure
(defn append-ints-test
  [opts the-delayer the-nemesis]
  (merge
    (base-test "append-ints" opts)
    {:client    (client opts)
     :generator (gen/phases
                  (->> (infinite-adds)
                       gen/seq
                       the-delayer
                       (gen/nemesis
                         (util/cyclic-nemesis-gen opts))
                       (gen/time-limit (:time-limit opts)))
                  (->> {:type :invoke, :f :read, :value nil}
                       gen/once
                       gen/clients))
     :checker   (check-sets)
     :nemesis the-nemesis}
    opts))
~~~

This shows some of the things you can do with generators - we use `(gen/phases)` to combine two test phases:

- A first phase which sends an infinite series of `:add` operations to the clients, until a time limit is met, with a nemesis that runs intermittently
- A second final phase which sends a single `:read` operation to the clients, to read the document's final state.

`infinite-adds` is a classic bit of clojure:

~~~clojure
(defn infinite-adds []
  (map (partial array-map
                :type :invoke
                :f :add
                :value)
       (range)))
~~~

This returns an infinite sequence:

~~~clojure
`({:type  :invoke
   :f     :add
   :value 0}
  {:type  :invoke
   :f     :add
   :value 1}
   ... and so on
~~~

At the end of this test we had a straightforward checker that looked at the single `:read` result, and at the history, and identified all mismatches between the history of (apparently) successful writes and the actual final value in mongodb.

This was mostly a learning exercise - appending to an array is an idempotent operation so we weren't testing linearizability or the like, just  "can we string together a pile of operations and see how they fail?".

### A more realistic test - creating and updating artificial user data

For the bulk of our tests, we wanted to simulate realistic client behaviour, under reasonably heavy loads.  The main scope of our client's project was managing information about users - so we wanted to simulate reading and writing users, using MongoDB documents similar to those used by the client, and similar client logic. (As clojure runs on the JVM, and the client project was in Java, we could have directly called their code - but it was simple enough to replicate key parts in our tests, and made the tests less tightly coupled to their code, which was under active development)

The client also had some peculiar extra transaction logic - they had their own distributed transaction mechanism, whereby an orchestration system established "pending" changes to each document; multiple microservices could then participate in those transactions, and the orchestration system could then "commit" or "roll back" those transactions when done.  I'm not going to go into the detailed reasons why this is a very bad idea - but we simulated it in our client as well.

At startup our Jepsen client created a simulated production database, with a large number of random users using the [faker](https://github.com/paraseba/faker) library, resulting in users like:

~~~json
{
  "_id" : 364992,
  "email" : "rhiannon-schimmel @gmail.com",
  "first-name" : "Judge",
  "last-name" : "Kuhlman",
  "address" : {
    "street" : "229 Mabelle Mountains",
    "county" : "Lothian",
    "postcode" : "IW47 3KA"
  },
  "phone" : {
    "primary" : "917-524-0981",
    "mobile" : "1-314-339-4989 x74262"
  }
}
~~~

Our main test function looked like:

~~~clojure
(defn user-test
  [opts the-delayer the-nemesis]
  (merge
    (base-test "etla-simulator" opts)
    {:client    (client opts)
     :generator   (->> mixed-ops
                       the-delayer
                       (gen/nemesis
                         (util/single-nemesis-gen opts))
                       (gen/time-limit (:time-limit opts)))
     :checker   (checker/compose
                  {
                   :checker (etla-checker/checker state "jepsen" "participants" (:checker-mode opts))
                   :histogram (histogram-producing-checker)
                   })
     :nemesis   the-nemesis}
    opts))
~~~

The client was fairly similar to the example given earlier, except it created all the required random users at startup, and the `invoke!` function was:

~~~clojure
  (invoke! [this test op]
    (util/with-timing-logs op
      (case (:f op)
        :create (create-random-participant (:participant-dao this) op)
        :update (update-random-participant (:participant-dao this) op)
        :read (read-random-participant (:participant-dao this) op))))
~~~

Basically three operations were supported - create, update and read.  Create creates a new random user, update modifies a few fields in a user, and read just reads a user at random.  These operations also created and committed the client's pseudo-transaction logic.

The `mixed-ops` generator produced a random combination of these operations - configurable per test. By default it generated 1% creates, 10% updates and 89% reads, but test scenarios could override these proportions.

The `nemesis` was set up with a configurable nemesis which ran once per test, at a specified time interval for a specified duration.  More on that later.

The `checker` inspected the history log, and a supplementary `state` object, and calculated a number of overall test metrics:

- counts of the number of kinds of operations performed, and their results - e.g. number of successful create/update/read operations, number of failures, number of indeterminate results
- a list of any pseudo-transactions that were not fully committed
- a list of any user ids in the `state` but not found in the database 
- a list of any "unexpected" user ids - that existed in the database but should not have (due to failed writes)
- a list of any users where the value of the user in the database did not match what was expected from the Jepsen history
- an overall "valid" status

The overall validity was determined by not whether everything worked, but by whether everything was reliably reported - writes and updates either failed (and did not change the databse) or succeeded (and _did_ change the database).

One other thing in the test's checker is that call to `(histogram-producing-checker)` - this called the [HdrHistogram](http://hdrhistogram.org/) Java library, using timings from the Jepsen history logs, to produce `.hgrm` files which we could later use to produce timing plots like this one:

![HdrHistogram](2019-04-chaos-engineering/histogram-ok.png)

#### First test - baselining performance on one node with no nemesis

This was our very first actually useful test - baselining how a normal set of user operations performed on a single-node network.

Settings were fairly simple:

- The test ran for 600 seconds
- 100,000 users were pre-created
- Operations were 1% creates, 10% updates and 89% reads
- 500 workers were used
- a simple random test delay was used, set up to consume an operation every 0.25 seconds
  - so the result should be 2000 operations per second on average
- Mongodb clients were set up with:
  - write-concern "majority"
  - read-concern "default"
  - read-preference "primary"

The actual operations performed were:

|---
|**operation**|**result**|**count**|**median response time**
|===
|:read|:ok|1,066,947|0.6ms
|:create|:ok|11,912|21ms
|:update|:ok|120,175|22ms
|---

The histogram of performance data was:

![histogram](2019-04-chaos-engineering/baseline-one-node/histogram.png)


And the overall behaviour over time was:

![grafana](2019-04-chaos-engineering/baseline-one-node/grafana.png)

These were our main outputs from each test - a performance histogram, to identify how real performance was distributed, and a grafana graph (automatically captured as a screenshot) to see performance over time.  Note these use log scales! So small variations in graphs might actually be quite large.

The grafana output shows a lot of data - note there are two Y axes, on the left is response times, with 9 filled curves (as the output was set up for 3 mongodb nodes); on the right is responses per second, with 4 solid lines for "create OK", "update OK", "read OK" and "failed".

There are also two vertical lines to show when the nemesis started and finished - there was no nemesis in this run, so nothing happened at those times!

Also the bottom third of the graph shows failures and their response times.

---

For the baseline, it was pretty clear that reads took less than 1ms, creates and updates took around 20ms - there were a few spikes of slower responses, but only in the slowest 1% of responses, and many of those were during the initial setup time of the test.

TODO: add a bit more discussion on generating the report from asciidoc?  Need to work out where to fit that in.

---

**UP TO HERE**

---

## Headings for bits still to write:

### Nemeses

### Monitoring and collecting results

### Generating the reports - asciidoc and friends

### What did we find?

There is a *lot* that could be put here!

(a warning note about how this may no longer apply to current mongo versions)

#### (Separate sections for useful things from our report)

### Also tested - load testing, queueing

## What didn't we get to?

- testing client's pseudo-transactions fully
- testing recovery
- microservice interaction - including [whatever the patterns are for microservice interaction]
- interaction of REST and Queues

## What I would do next time

### New tools

### Focus on the important things

### Evolutionary Architecture and Continous Delivery



## TODO: Other things to put somewhere or mention
* general grammar fixes - choose a tense and stick to it!
* better CSS for tables

* AWS implications - availability zones, needing an odd number of nodes, using an arbiter
* more on performance testing
* more detailed version of our "incremental approach"
* moving to production environment
