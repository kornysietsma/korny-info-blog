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
Chaos Engineering tools and techniques are extremely useful for anyone planning or operating a distributed system. And many of us are building distributed systems! As Martin Fowler notes [in his article about Microservice trade-offs](https://martinfowler.com/articles/microservice-trade-offs.html#distribution), Microservices architectures are inherently distributed, and we need to handle all the problems this entails.

In this article I want to talk about our experiences using Jepsen, and a bit of Chaos Monkey, to test-drive a client's architecture - enabling us to validate their plans, based on data derived from tests, rather than based on theorising or guessing.

A lot of Chaos Engineering discussion talks about attacking your systems in production - and while I think this is an excellent thing to do, we also found a lot of value _incrementally_ testing our systems - working out how they break in controlled simplified environments, before trying to identify failures in a genuine production configuration.

I also see these techniques as a great enabler for [evolutionary architecture](http://evolutionaryarchitecture.com/precis.html) - you can use chaos engineering to develop automated fitness functions, so you can be sure your systems are still resilient and reliable even as your architecture grows and evolves over time.

### What is Chaos Engineering?

The Science Fiction author Frank Herbert wrote stories around a ["Bureau of Sabotage"](https://en.wikipedia.org/wiki/Bureau_of_Sabotage) - a quasi-official group whose job was to interfere violently with the smooth workings of a futuristic perfect government.

[Chaos Engineering](https://en.wikipedia.org/wiki/Chaos_engineering) feels a bit similar - your goal is to deliberately break things, to mess up the smooth workings of your systems so you can see the hidden faults and failings; so you know how things will break before they break naturally.

Critically, you don't need to be building a massively complex system to benefit from this!  Even if you are "just" using someone else's distributed database or queue, you still need to answer a few key questions:

* How should you configure your systems?  Network topology, timeouts, client setup - there are a lot of settings to consider.
* What happens when something goes wrong - can you guarantee no data loss? Will you be alerted? Is it possible to manually repair things in the worst case?
* What are the tradeoffs between performance, resiliency, and cost?

### What does "resilience" mean?

[Database Reliability Engineering](https://www.goodreads.com/book/show/36523657-database-reliability-engineering) describes resilient systems as having three specific traits:

- Low MRRT (mean time to recover) due to automated remediation to well-monitored failure scenarios.
- Low impact during failures due to distributed and redundant environments.
- The ability to treat failure as a normal scenario in the system, ensuring that automated and manual remediation is well documented, solidly engineered, practiced, and integrated into normal day-to-day operations.

A key consideration of "treating failure as a normal scenario" is that at any time, in any failure scenario, you want to be sure your system is appropriately _consistent_ - when a user has made changes, those changes should be made or not made.  Potentially you might have some level of eventual consistency - a change might be on a queue or partially distributed - but you don't want the user to be told "sure, your data was saved" and then find it has been lost in transit.

(Note that this is a very complex area!  If you want to know more, you could check out [Aphyr's detailed hierarchy of consistency models](https://jepsen.io/consistency) or there is some great coverage in [Martin Kleppmann's "Designing Data-Intensive Applications"](https://www.goodreads.com/book/show/23463279-designing-data-intensive-applications))

For our particular client there were a fairly obvious set of requirements; and these are quite common among normal business systems with large but not Facebook-scale numbers of users:

- It had to have a good up-time - it needed to be distributed across multiple data centres, so even if a significant outage occured, users should be able to keep using the system to some degree, even if only to read data.
- It had to never lose committed user data - if a user hit a "save" button and the system responds with "OK", the data should be saved.
- It had to recover from some faults automatically - intermittent failures should not cause major outages.
- It had to handle exceptional situations well - if something goes badly wrong, we still want to be able to recover eventually, even if this involves manual steps.

#### Focusing on Partitions
There are a lot of things that can go wrong in a distributed system, but often it's worth focusing on one of the worst situations - a network partition.  This is when some parts of your network lose connectivity with other parts of your network.  If you are distributed across more than one physical location, this is all too possible!

Other problems like having a single server fail can be dangerous, and we did test these - but it's useful to start with a worst-case scenario early on.  The absolute worst case is if your network is split and you end up with a "split brain" situation where you have two partial networks with diverging views of reality!

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

A simple kind of network partition is where some non-primary nodes are split from the rest:
![Split with primary majority](2019-04-chaos-engineering/resiliency2.png)

In this case, the left-hand network is OK - clients can still talk to the primary, these nodes might panic a bit: "We can't see some nodes! Oh no!" - but you still have more than 50% of the network available.  This is how consensus systems work - the majority of nodes can see each other, they can maintain consensus about the state of the data.

The right-hand two nodes will panic, but they can't get a consensus so they will stay in a failed state until the network comes back.

What if the network splits like this?
![Split with primary minority](2019-04-chaos-engineering/resiliency3.png)

Now, the left-hand side no longer has a majority and should detect an error state.  The right-hand network has the majority of nodes, it can only assume that the primary has crashed, and it will trigger a new election and find a new primary.

A client connected to the old primary will need to be redirected somehow to the new primary (if it can see it!) - for example the client may have a list of all node IP addresses, so it can ask other nodes where the primary is now.

You can increase the reliability of writes and reads, at the expense of performance, by tweaking how you trust the distributed network.  In MongoDB you can use [write concerns](https://docs.mongodb.com/manual/reference/write-concern/) to say "Don't count data as written successfully until the majority of nodes have confirmed they have seen it", and similarly [read concerns](https://docs.mongodb.com/manual/reference/read-concern/) to say "Don't return un-committed data from queries".  Tweaking these options is complex though - which is why it's good to test them!  I'll try to cover a few more specific examples later in this article.

<!-- TODO: I'm removing this as it got linked above - if the above link got removed again, this should be _somewhere_

*Note* - this is a deliberately brief and incomplete introduction to this topic.  If you want more gory details, you are far better off reading [Martin Kleppmann's book mentioned earlier](https://www.goodreads.com/book/show/23463279-designing-data-intensive-applications) or *TODO* suggest other background reading -->

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

One of our large clients was in the process of building a new system based on a microservices architecture, and they asked us to provide an early review of their planned approach, especially how they planned to use MongoDB as a distributed store for their user data.
After our initial review of their plans we suggested that it would be best to actually _test_ their approach, rather than just trying to reason about it.

So we agreed to set up a small team to build out some tests.  We chose to initially use [Jepsen](https://jepsen.io/) for a chaos engineering tool - we had some familiarity with Clojure, and it seemed like a good tool for our planned iterative approach; we also used the [Yahoo Cloud Serving Benchmark](https://en.wikipedia.org/wiki/YCSB) for some load testing, though this article is mostly focusing on the Jepsen tests.

### A warning about applying these results too literally

My goal here is to talk about approaches and things to try.  I'm not trying to say "You should do X with MongoDB"!  This analysis was done a while ago - the particular results may depend on which version of MongoDB you run, on which client libraries you use, on what patterns of usage you have, and on what network topology you use.

So don't act on any of my specific conclusions here - test things yourself, and find out what works in your environment.

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
  ; ... and so on
~~~

At the end of this test we had a straightforward checker that looked at the single `:read` result, and at the history, and identified all mismatches between the history of (apparently) successful writes and the actual final value in mongodb.

This was mostly a learning exercise - appending to an array is an idempotent operation so we weren't testing linearizability or the like, just  "can we string together a pile of operations and see how they fail?".

### More realistic tests - creating and updating artificial user data

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

### First test - baselining performance on one node with no nemesis

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
  - read-concern "majority"
  - read-preference "primary"

#### The five test stages
I mentioned earlier the 5 iterative stages of our tests - in this case they were:

##### 1. Set up a test system

We used Terraform and Ansible to set up the servers initially - Jepsen has some logic for server provisioning, but we preferred to use more mature tools.

We didn't re-build the servers for every test - only when something fundamental changed like topology or storage media.

##### 2. Break the test system

For this test we had no nemesis, so nothing broke.

##### 3. Analyse the results

We used the checker described above for a high-level analysis, and an overall "Pass/Fail" rating - of course with no nemesis, this returned entirely successful results:

|---
|**operation**|**result**|**count**|**median response time**
|===
|:read|:ok|1,066,947|0.6ms
|:create|:ok|11,912|21ms
|:update|:ok|120,175|22ms
|---

We also generated a histogram of performance timings using [HdrHistogram](http://hdrhistogram.org/) :

![histogram](2019-04-chaos-engineering/baseline-one-node/histogram.png)

And we generated Grafana charts of how the system operated over time:

![grafana](2019-04-chaos-engineering/baseline-one-node/grafana.png)

Note both of these use log scales! It's hard to capture failures on a linear scale - one big result can dwarf normal results.  But this does mean you need take some care interpreting the charts.

The grafana output shows a lot of data - note there are two Y axes, on the left is a log of response times, with 9 filled curves (as the output was set up for 3 mongodb nodes); on the right is a linear scale of responses per second, with 4 solid lines for "create OK", "update OK", "read OK" and "failed".

There are also two vertical lines to show when the nemesis started and finished - there was no nemesis in this run, so nothing happened at those times.

Also the bottom third of the graph shows failures and their response times - again, empty for a run with no nemesis.

##### 4. Document the results

Our test results needed to be analysed, understood, and most importantly _communicated_.  So as we ran tests, we generated documentation.

We used ruby scripts based on the [AsciiDoctor](https://asciidoctor.org/) library to generate our documentation - for this test our documentation template looked like:

~~~
= Baseline on a single node

This scenario establishes baseline performance on a single MongoDB node.

There is no nemesis as this is just to establish normal performance with this
topology.

== Operations performed

[cols="<,^,>,>"]
|===
|operation|result|count|50th pct
|:read|:ok|1,066,947|0.6ms
|:create|:ok|11,912|21ms
|:update|:ok|120,175|22ms
|===

== Metrics
[[img-grafana]]
.results over time
image::jepsen/baseline-one-node/grafana.png[scaledwidth=100%]

== Latency graph
[[img-histogram]]
.latency histogram
image::jepsen/baseline-one-node/histogram.png[scaledwidth=100%]
~~~

The first paragraph was hand-written, and the other sections could be tweaked from a basic template.  Images were copied from our test output, or generated - the `histogram.png` file was generated by a [script similar to this one](https://github.com/HdrHistogram/HdrHistogram/blob/master/gnuplotExample/make_percentile_plot) which converted the HdrHistogram output to an image using `gnuplot`.

##### 5. Iterate

The next stage was to iterate - to start breaking things and analysing the results!

### More baselining

We also ran some baselines on other topologies - a 3-node replica set in one Availability Zone, and a 5-node replica set split across three Availability Zones.

The results were actually very similar - when nothing goes wrong, even a 5-node cluster didn't perform much worse than a single node under these loads:

|---
|**operation**|**result**|**count**|**50th pct**|**95th pct**|**99.9th pct**
|===
|`:read`|`:ok`|1064769|0.60ms|1.10ms|22.46ms
|`:update`|`:ok`|119507|26.77ms|43.71ms|68.68ms
|`:create`|`:ok`|12067|26.03ms|42.86ms|63.41ms
|---

Across the baselines, it was pretty clear that most reads took around 1ms, most creates and updates took around 27ms - there were a few spikes of slower responses, but many of those were during the initial setup time of the test.  (In hindsight it would have been good to gather these stats ignoring the first few ms of data!)

### First nemeses - splitting the network

The first few nemeses we used were testing a range of network splits; we ran several different scenarios:

- A network split on a 3-node network, with the Primary in the majority
- A network split on a 3-node network, with the Primary in the minority
- The same as the above, but tinkering with timeouts
- Network splits on a 5-node network split across multiple availability zones

This used a simple Jepsen nemesis:

~~~clojure
(defn minority-partitioner
  "partitions such that the primary is in the smaller partition"
  [client test op]
  (let [nodecount (count (:nodes test))]
    (assert (<= 3 nodecount))
    (assert (odd? nodecount))

    (if-let [primary (cluster/primary client)]
      (do
        (info "Minority partitioner using primary:" primary)
        (let [minority-size (/ 2 (dec nodecount))
              without-primary (remove (fn [x] (= x primary)) (:nodes test))
              [friends foes] (split-at (dec minority-size) without-primary)
              grudge [(conj friends primary) foes]
              _ (info "partioning into:" grudge)]
          (n/partition! test (n/complete-grudge grudge))
          (assoc op :value (str "Cut off " (pr-str grudge)))))
      (do
        (warn "No primary known - can't partition")
        (assoc op :value (str "No primary known - can't partition"))))))
~~~

I'm not going to try to explain all of this, hopefully you can glean a general idea of how it might work:

- Find the primary node (the MongoDB client should know this)
- Remove the primary from the list of nodes
- Bisect the remaining nodes into two random sub-lists
- Add the primary back into one list
- Split the network using [partition!](https://github.com/jepsen-io/jepsen/blob/0.1.2/jepsen/src/jepsen/nemesis.clj#L21)  (note this is from Jepsen 0.1.2 - later versions have different function names here)
  - under the covers, this calls `iptables` on each of the servers to drop and recover network connections

The first test was a fairly "safe" - there is a network split, but the primary node is not affected - it can't see some nodes, but it can still see a majority of nodes:

![Split with primary majority](2019-04-chaos-engineering/resiliency2.png)

The result was, as expected, no real impact - individual MongoDB nodes had extra work recognising that a server was missing, and presumably that server had extra work catching up when it came back on line - but a majority of nodes could keep working without issues, so the client didn't even notice.

The other tests were the more troublesome scenario, where the primary needs to change as it is in the smaller network:

![Split with primary minority](2019-04-chaos-engineering/resiliency3.png)

On a 3-node network, this had a very clear dramatic effect:

![histogram](2019-04-chaos-engineering/primary-split/histogram.png)

Quite a lot of Create and Update operations failed - and they took around 10 seconds to fail.  ("info" is roughly equivalent to "fail" here - it just means the failure was a socket timeout so the operation might have been committed before the connection died)

Viewing grafana results shows how things behaved when the network was split:

![grafana](2019-04-chaos-engineering/primary-split/grafana.png)

Zooming in to the time around the start of the split:

![grafana](2019-04-chaos-engineering/primary-split/grafana2.png)

- At 14:50:30 the nemesis starts (note there are 2 start lines now - one for when the nemesis is triggered, and when it is complete.  ssh-ing to all the nodes and executing `iptables` isn't instantaneous)
- the `create` and `update` response times drop off immediately (these are the filled curves - the solid unfilled lines are _counts_ of responses, and have a 10-second granularity, so are not so useful here)
- the `read` response times are initially OK - which might be surprising!  But the vast majority of our reads only need to read from the primary node.  Despite the [read concern of "majority"](https://docs.mongodb.com/manual/reference/read-concern-majority/#readconcern.%22majority%22), any data that has been written and replicated in the past, is available to read immediately.
- around 14:50:40 there are spikes in read performances - this is presumably when the network election is starting, it's not clear whether they are struggling to find a primary to read from, or precisely what happens.
- also around this time a bunch of `info` results show up in the bottom section - these are Jepsen's way of indicating indeterminite results.  These are `create` and `update` calls from around 14:50:30 that are now returning errors, 10 seconds after the nemesis started.
- around 20 seconds in, at 14:50:50, some writes are starting to succeed - but these are quite slow responses, and it takes a while to stabilise. Things aren't really better until 14:51:10 - 40 seconds after the split.

Fourty seconds is a _really long time_ in user land.  We wanted to know why it took so long to recover - the new primary was elected after about 10 seconds, what was going on?

From our investigations, it seemed that the problem might be the MongoDB client configuration - the client keeps a pool of connections to the Primary server, but it uses a heartbeat to poll the server for changes - and this [heartbeat frequency](http://mongodb.github.io/mongo-java-driver/3.8/javadoc/com/mongodb/MongoClientOptions.Builder.html#heartbeatFrequency-int-) defaults to 10 seconds.  And the timeouts for connecting to the server and the default socket timeout are 20 seconds each - this means a client can spend quite a while not noticing that the topology has fixed itself.

In the spirit of incremental change, we ran a test with smaller client timeouts:

|===
|setting|default|new test
|===
|heartbeat-frequency|10,000ms|1000ms
|heartbeat-connect-timeout|20,000ms|5000ms
|heartbeat-socket-timeout|20,000ms|5000ms
|===

The results were much cleaner:

![grafana](2019-04-chaos-engineering/primary-split-short-timeouts/grafana2.png)

It seems that tweaking the client timeouts definitely helped - writes recovered in around 23 seconds, compared to 40 seconds previously. (Of course there's a risk that in lowering timeouts, more accidental failures would occur in a flakey network)

This was also a great validation of our test-driven approach.  It's very hard to read all the MongoDB documents, even with access to expert administrators and the like, and be completely sure of the implications of this sort of setting.  It's much more straightforward to evaluate these settings through tests.

### Testing on a more realistic network

So far, we were testing on three nodes in a single Amazon availability zone - effectively, three nodes in a single datacentre.  This isn't very useful for real resilience - the most likely cause of a network split is problems in the connections _between_ datacentres, rather than within one.  Also network time between availability zones is always going to be significantly greater than within one zone.

So we wanted to run MongoDB across two zones - but then there's a catch - you need an odd number of servers to have a quorum-based election, so you can be sure of a majority.  You shouldn't just put 3 nodes in one zone and 2 in another, either - if the larger zone had a serious problem, the smaller zone could not recover on it's own - it's better to be able to survive with any single zone unavailable.

We had an extra twist on this project - at the time, Amazon only _had_ two availability zones in the UK!  We could run servers in Ireland, but our client didn't want to store any data outside the UK.

Enter the [Arbiter](https://docs.mongodb.com/manual/tutorial/add-replica-set-arbiter/) node.  An Arbiter is basically a no-data-stored-here server - it participates in elections, so it can help recover a network when a whole zone goes away.  (It also counts towards the "majority" for write concerns - otherwise in this scenario it'd be impossible to write anything when one AZ goes down)  We can put an arbiter in Ireland without it storing any data:

![multi-az topology](2019-04-chaos-engineering/multi-az.png)

The results of splitting with this topology were similar to the 3-node scenarios, but with somewhat longer recovery times and more errors:

![grafana](2019-04-chaos-engineering/ha-primary-split/grafana.png)

We also started to notice some other ugly problems though in this scenario - our checker reported:

~~~clojure
:database-irregularities {
  :not-in-db [], 
  :ok-mismatches [],
  :info-mismatches [155890 208477],
  :fail-mismatches []}}
~~~

This indicated that for two participants, the database had differences from our client's view of the world - the client saw `:info` errors, which generally means a `MongoSocketReadException` or similar, and it assumed these were failures - but the database indicated that these changes _had_ been applied successfully.

This was something we saw several times in other tests as well.  *You can't guarantee that a failed write actually failed* - there is a slim chance that the write succeeded, and was written to a majority of nodes, but something failed before that success was reported back to the client.

This had significant implications for the application design - effectively the software design has to deal with uncertain results - either by retrying the operation until a conclusive result was returned (and this required operations to be idempotent!) or by making sure any error of this sort was able to be identified and fixed manually.

### More nemeses, more tests

I'm not going to cover all the things we tested here - we generated a 133 page report, no-one wants to read all of that!  Hopefully by now you get the idea of the sort of outputs you can get from these tests.

I will give a brief overview though of things we looked at.

#### Using TLS

We wanted to know the impact of enabling TLS between the MongoDB nodes - by default MongoDB uses unencrypted connections between replicas for heartbeats and replication.

Enabling TLS incurred a roughly 15% performance penalty on creates and updates, and a lower penalty on reads - for our client, they chose to accept this slowness in return for extra security.

#### Running out of disk space

Running out of disk space can be messy - a server might think it's running just fine, but then be unable to write any logs...

We tested both running out of space on the root volume, and on the `/journal` volume to simulate Mongo dying because it was writing too many journal entries.

Interestingly, these tests had lots of problems - but not when the disk was full; the problems started much earlier, because filling a 25G journal disk incurred a lot of extra I/O load, and this itself caused a lot of slow-downs and failures.

Which led to our next test:

#### Heavy I/O load

We tested this using the [BurnIO](https://github.com/Netflix/SimianArmy/blob/master/src/main/resources/scripts/burnio.sh) script from Netflix's Chaos Monkey (now Simian Army) tools - on the `/`, `/data` and `/journal` drives of our servers.

As expected, this caused significant latency problems - but no actual errors.  Our main conclusion here was to monitor these volumes, and check the IOPS requirements more carefully under realistic loads in a performance test.

#### Heavy CPU utilisation

Again we used the Chaos Monkey [BurnCPU](https://github.com/Netflix/SimianArmy/blob/master/src/main/resources/scripts/burncpu.sh) script for this test.

Generally heavy CPU loads didn't impact MongoDB much - this was not a big concern.

#### Corrupt networks, packet loss, increased network latency

We ran tests using several other [Chaos Monkey scripts](https://github.com/Netflix/SimianArmy/blob/master/src/main/resources/scripts/) - most of them were informative, but generally MongoDB was pretty resilient to network issues; things slowed down but not dramatically, and no data was lost.


---

---

**UP TO HERE**

---

## Headings for bits still to write:

### Read Concerns
We tested Jepsen only with "majority" - talk about why, and YCSB results.

Also a gap in our analysis - should have tested write-then-read sometimes?

### Also tested - load testing, queueing

## What didn't we get to?

- testing microservice comms - circuit breakers, other stuff mentioned in Release It! and Martin's article
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
* mention the benefits in forcing you to have good monitoring and alerting!!!
* more on performance testing
* more detailed version of our "incremental approach"
* moving to production environment


# References

[Martin Kleppmann's "Designing Data-Intensive Applications"](https://www.goodreads.com/book/show/23463279-designing-data-intensive-applications)

[Database Reliability Engineering](https://www.goodreads.com/book/show/36523657-database-reliability-engineering)

Aphyr's websites

Martin's articles

Release It!

