
TL;DR
======

Build all of your services as event-sourced, RESTful Bounded Contexts with a
Uniform Interface of message-orientation and Event-Time semantics, then allow
them to autonomously organize by emitting hypermedia events on a universal
backplane. Aggregate these services as necessary to provide built-for-purpose
abstractions.

Overview
========

Hyperobjects is an architectural style for distributed systems whose primary
design objective is enabling simple, scalable, reliable enterprise-scale cloud
architectures. Besides the particular organization of components, the primary
characteristic constraints of this style are as follows.

* Hypermedia Event Messages as the engine of System state
* A uniform interface for all services that:
  * Models effectful operations as Intent messages that can be batched, allowing
    clients to synthesize new operations
  * Incorporates uniform, logical time semantics for all observable values and
    behaviors enabling:
    * point-in-time distributed consistency
    * entity timeline inspection
    * forking an entity from a previous point-in-time
    * safe "what-if" operations
  * Exposes first-class Query operations
* Command Query Responsibility Segregation

These constraints are combined with others selected from Domain-Driven
Design, Vogel's Principles of Distributed Computing, Enterprise Integration
Patterns, message-oriented programming, Representational State Transfer, event
sourcing, and stream processing.

The style is described at two levels: the System-level and the
Service-level. The System-level describes the style as an
enterprise architecture, whereas the Service-level describes the constraints and
behaviors of component services within the enterprise architecture.

Contents
--------

0. Motivation
1. Service-level Architecture
2. System-level Architecture
3. Discussion

Implementation details are described in terms of modern web technologies; the
reader is encouraged to generalize. A running example of a retail enterprise is
used to frame the narrative. The System-level architecture is modeled on the
principles outlined in Appendix A. A Service-level implementation is described
in Appendix B.

Motivation
==========

There are three main themes to the concerns Hyperobjects aims to address:
fostering serendipity, enterprise architecture in the cloud, and correctness.

Foster Serendipity
------------------
This verbiage is borrowed from Steve Vinoski. Eric Evan's calls it supple architecture. The
idea is that our software architectures should foster an environment where new
requirements are simple and easy to satisfy. At the enterprise level, such
properties included discoverability and uniformity, while the application or
service level requires composability and specificity.

Consider services like IFTTT or Zapier that enable non-trivial workflows to be
built from simple webhook technologies. Our enterprise architectures should be
at least as accomodating, allowing reactivity across various silos.

At the application level, new requirements usually mean we need to present
novel and disparate data, effecting new operations in myriad contexts. Technologies like Falcor and
Relay have ushered in so-called demand-driven development, while companies like
AWS and Netflix have shown the advantages of creating top-level services that
aggregate baseline services to provide agility in the application layer.

Enterprise Architecture in the Cloud
------------------------------------
Non-functional requirements are those without which your system doesn't
function. So, we should learn from the web and its denizens, we still need to
apply a high degree of rigor. At the same time, the value equation has changed
with the cloud. Prior to the cloud era, the solution to our non-functional
requirements often involved writing big checks to specialized hardware and
software vendors. To a large extent, this option isn't available in the cloud;
even so, it would obviate the benefits of running in the cloud.

Instead we should seek to leverage the cloud offerings to satisfy our enterprise
requirements while freeing us from the tyranny of the enterprise hardware and
software vendors. To do so we need an enteprise architecture that can be
served using PaaS offerings that are more or less homogenous across clouds.

Finally, the very nature of the cloud implies an architectural focus on
scalability and a non-differentiation of service nodes. This is a fundamentally
different approach from matching hardware to our enterprise SLAs. Stateless,
fungible service nodes have become the primary building block of the cloud.

Correctness
-----------

In recent years functional programming has made huge in-roads into mainstream
software development practice. Concomittantly, ideas from FP like immutability
have found their way into traditional enterprise OOP. Reactive Programming is
driving many of the innovations in front-end development, and CRDTs are seeing
broader adoption. Finally, testing techniques and tools abound alongside
academic innovations in theorem proving, property-based testing, concolic
testing, and other analysis techniques.

The salient point in all of these examples is an emphasis on correctness,
specifically on building confidence in the software we are shipping; a
confidence that is pre-requisite to the enterprise agility promised by
continuous delivery.

What we desire is cloud native architecture that acts in concert with these
innovations, lifting these ideas into the systems architecture, to enable
agility while helping to ensure correctness. Valuing simplicity, clarity and
generality above all, just as in the practice of programming, we wish to resolve
the tension between the cloud era realities like eventual consistency and
irregular reachability with these desires.

Service-level Architecture
==========================

Hyperobject Concepts
--------------------

### Activity Name

A URN denoting either an Intent (imperative) or an Event (past-participle), e.g.:

- Intent URN: `urn:com:contoso:consumer-shopping:cart:checkout`
- Event URN:  `urn:com:contoso:consumer-shopping:cart:checkout-succeeded`

Or,

- Intent URN: `urn:com:contoso:consumer-shopping:bundle:add-item`
- Event URN:  `urn:com:contoso:consumer-shopping:bundle:item-added`

### Intents

Clients get work done by sending (`POST`) Messages to Services called Intents.
These Intents are part of the Uniform Interface in that they define a standard
envelope format:

- Activity Name: nominates the semantics for the Data property
- Id: correlation identifier (see EIP) returned in the Resource Representation,
  opaque to service
- Data: a JSON object representing the Command Message 
- Abriged Example:

```
POST /consumer-shopping-cart/42924579adkfajl32792i98f98
{ "activity" : "urn:com:constoso:consumer-shopping:bundle:add-item",
  "id" : "asi292kajfl",
  "data" : {
    "item-id" : "ASD2AK",
    "quantity" : 2
  }
}
```

### Events

- A Value that serves as the record that a particular business activity has transpired
- Not always in one-to-one correspondence to an Intent, but can usually be
  viewed semantically as the "past tense" of an Intent.
- Mostly inconsequential to clients since the projected state is always returned

The request processing pipeline of a Hyperobject looks like this:

```
Parse     :: HTTP Request -> Intent?
Conjugate :: Intent -> State -> Event?
Apply     :: Event  -> State -> State'?
Store     :: Event  -> void
Project   :: State' -> HTTP Response
```
Outputs in question, e.g. `Intent?`, indicates a possible point of early exit from
the pipeline shou
#### Note on Durability

Jim Gray "geoplex": clustered servers in same location
Until an event is written here, it didn't happen. Why not use a queue? Need to
select entire history atomically and consistently when spinning up Aggregate
Root.

Intents should be logged separately along with the Revision URL that resulted, if applicable.


RESTful Domain-Driven Design
----------------------------

Services in Hyperobjects implement a single Bounded Context, and expose it via
RESTful interface.

-------------------------------------------------------------------------
| DDD Concept                      | REST Concept                       |
|----------------------------------|-------------------------------------
| Bounded Context                  | Network Domain                     | 
| Aggregate                        | Resource Type                      | 
| Aggregate Root                   | Resource Instance                  |
| Value in Event Time of an Entity | Representation                     |
| Entity                           | Only accessible via Aggregate Roots|

```
https://consumer-shopping-context.contoso.com/consumer-shopping-cart/42924579adkfajl32792i98f98
        \--------- bounded context ---------/\---- aggregate ------/\--- aggregate root id ---/
```

### API Surfaces

All Hyperobjects URLs are translucent identifiers with regular structure that delineate
constituent API surfaces.

- Bounded Context  
  //**consumer-shopping-context.contoso.com**/  
  Exposes service metadata (available Intents, Event Activities)  
  Also serves as entry-point for interactive documentation  
  
- Aggregates  
  //consumer-shopping-context.contoso.com/**consumer-shopping-cart**/  
  Exposes Query surface for a Resource Type e.g. Shopping Carts  
  Admits creation of new aggregate roots  

- Continuants  
  //consumer-shopping-context.contoso.com/consumer-shopping-cart/**42924579adkfajl32792i98f98**  
  Nominates the "current" version of a particular Aggregate Root  
  Primary API surface, implements domain operations (i.e. POSTed Intents)  

- Revisions  
  //consumer-shopping-context.contoso.com/consumer-shopping-cart/42924579adkfajl32792i98f98/**101**  
  Nominates an Aggregate Root at a particular point-in-event-time, e.g. 101  
  Generally exposes the same operational semantics as the Continuant, but
  results in a new Aggregate Root, a fork of the original at the point-in-event-time
  nominated by the Revision

Event-Time
----------
Every write operation (processed Intent) on an Aggregate Root is linearized
(TODO why? time-ordering requires a single arbiter of order). As outlined above
there are two effects in the processing environment:

* Encapsulated: the resultant Event is stored in a private (geoplexed) Event Log
  (eventually replicated into Event Stream)
* Observable: the HTTP response containing a Representation of the new projected state

Both of these effects are associated with a new identifer: the Revision URL.
Recall the Revision URL has an positive integer as its final component; this
number acts as an independent logical clock for each Aggregate Root, defining Event-Time
(versus Processing Time) for every Entity within the Aggregate Root.

(In Hyperobjects, there is no
global time, and processing time--aka wall-clock time--is only interesting
insofar as it is leveraged by Stream Processors (TODO define) to create posets and windows.)

Thus, every 200-level (successful) response contains a Representation of a
particular *Revision* of an Aggregate Root. Both that revision and the Event that engendered the
it can be identified by the Event-Time. 

System-level
============

Universal Backplane
-------------------

vs ESB

- "Distributed, Replicated Messaging"
- "A high-scale, durable, distributed buffer"
- Partitioned Consumers
- Internal Elasticity
- Buffer -> Downsort -> Receive Queues
- *Event Message* pull model: "postcard" hypermedia events
- Domain Events + Service Lifecycle Events

### Provisioning

Hyperobject metadata interface lists the Topic/event-URNs and/or patterns it is
interested in as well as the event-URNs it is interested in (subscriptions).
When the Hyperobject joins the Service Network, this information is used to
setup Subscriptions. Subscriptions can be patterns, e.g. `urn:tenant:bounded-context:aggregate:*`

### Ingress

- At least once delivery
- Read from service event store
  - Configurable whitelist for event data *Content Filter (342)*, mitigates
    Information Disclosure
  - default to standard postcard *Canonical Data Model (355)*:
    - subject (self/sender)
    - topic (activity/event URN)
    - correlation identifier: simple or composite
    - empty data: anyone can read the post card, should only include data 
- Deduplication, if possible

### Egress

- Downsort/Multiplexing Topic subscriptions
- Write into Hyperobject mailbox 
- Deduplication, if possible

### Loopback

A Hyperobject's subscription to itself, used to update QUERY nodes.
- Bypass Content Filter
- Makes progress even while Circuit Breaker is tripped

Discussion
==========

Common Concerns
--------------

### DRY

Individual services re-inventing the wheel: "Speed of execution" justifies (Vogels)

### Premature Complexity

Monolith can be designed for service-orientation from the beginning. In a
well-factored monolith, each bounded context should correspond to a RDBMS schema
that serves both as a logical and security boundary. The event log acts as a
global blackboard for each bounded context. Within a bounded context, normal
transactional locking is used to ensure consistency.

Appendix A: Principles of Distributed Computing
===============================================

Abridged from a [talk given by Vogles in 2009](http://www.web2expo.com/webexsf2009/public/schedule/detail/8539)

Autonomy: Individual components make decisions on local information
Asynchrony: Make progress under all circumstances (+ Back Pressure ?)
Controlled Concurrency: operations are design such that limited or no
concurrency control is required
Controlled Parallelism: use fully decentralized (p2p) techniques to remove
bottlenecks
Decentralize: remove dependencies
Decompose:
Failure Tolerant: failure normal
Local Responsibility for Consistency
Simplicity: as simple as possible but no simpler
Symmetry: all nodes can do any function


Appendix B: Hyperobject Service Implementation Details
======================================================

Logical Aggregate
---------------
Used to create new aggregate roots (POST/POSIT) and to search for them (QUERY).
If you wanted to see what a default Aggregate Root looked like you could POSIT
a create.
You can GET this to learn about what the aggregate does, i.e. the valid Intents
and Entity schema. You can also find out about the supported media types.

> http://bounded-context/logical-aggregate/aggregate-root-entity-id/history

### Revisions
Any exposed Aggregate Root State is really just a snapshot in time.
You can GET a previous version by

> http://bounded-context/logical-aggregate/aggregate-root-entity-id/revision-id

These are always returned with an Expires header of one year hence, indicating
it should *never* expire, per [RFC 2616, Sec. 14.21](http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.21)

You can think of the following as being equivalent identifiers.

> http://bounded-context/logical-aggregate/aggregate-root-entity-id/latest
> http://bounded-context/logical-aggregate/aggregate-root-entity-id/

In other words sending Intents to the latter is implicitly sending it to the
latest revision.

The first Revision is 0. To create an Aggregate Root, simply POST a create
Intent to the Logical Aggregate. This first Revision of an Aggregate Root will
generally look the same, but over time it could change as the Logical Aggregate
redefines was empty/zero looks like (e.g. as business rules for default values
evolve).

### History
You can also GET all the Events that have ever occurred to an Aggregate Root.

> http://bounded-context/logical-aggregate/aggregate-root-entity-id/history
> http://bounded-context/logical-aggregate/aggregate-root-entity-id/revision-id/history

#### Range Headers
We could support Ranges via headers to allow clients to navigate through history
explicitly; since the `revision-id` is predictable, clients in possession of a
representation (and therefore a revision), could request specific ranges of the
history. This feature might not be super valuable, given that `/history` returns
a paged mediate type. If this were implemented, `416 Requested Range Not
Satisfiable` could be return in the `authorize` step.

### Forking
You can FORK any aggregate root; this creates a new one where the empty/zero is the current
value of the targeted Revision

POST to a `Revision`: implicit `FORK`, `201 Created` with `Location` pointing to the new Aggregate Root

Entity
------
These are not addressable resources; direct interaction isn't possible. These
are owned by an Aggregate Root and are only affected by Intents processed
through the same. They are present in the representation of the Aggregate Root
and can be named in QUERY

### Promotion
Some entities are promoted 

Aggregate Root Semantics
------------------------
Hyperobjects implement a subset of the standard HTTP verbs (GET, POST, DELETE)
as well as introducing two others (POSIT, QUERY). The expected semantics of the
standard HTTP verbs are preserved. POSIT is like POST but has no durable
effects. QUERY is like GET but allows a body.

Access to all steps beginning with the (*) and those that follow it within are
serialized via a lightweight synchronization primitive.

### POST
This verb is used to send Intents to an Logical Aggregate (create) or an
Aggregate Root (all other functionality). It is the only way to get work done.
Because Hyperobjects are event sourced, they do not support PUT or PATCH in any
way.

#### Steps
`POST` is broadly the the conversion of an `Intent` to an `Event` which then is
applied to the current `State` which is then returned as a `Representation`
(projection).

- __parse__: supplied intent message is parsed and a formal Intent is created;
  returns `400 Bad Request` if a formal Intent cannot be parsed
- __authorize__: (implicit __get__ of current state) returns `403 Forbidden` if
necessary, `410 Gone` if Aggregate Root has been `archived`, and `401 Unauthorized`
in cases where a security credential is required but not present
- __conjugate__&ast;: `Intent -> Event` Conjugate is a term borrowed from
grammar and chemistry. In studying foreign languages, we will often learn to
conjugate verbs from the present tense to e.g. the past tense. This is exactly
the meaning here in converting an `Intent` to an `Event`. In chemistry the term
hews to the Latin morphology of "yoked together"; there it means "to be combined
with or joined reversibly". *Certain properties of Intents (trackingId?
activity?) are stored with the Event,* allowing them to be correlated.
- __apply__: `State + Event -> State?` return `409 Conflict` if the `Event`
could not be applied, e.g. the Aggregate's FSM doesn't support the event
at this point
- __store__: append Event to durable storage
- __project__:

### POSIT
The semantics of POSIT are exactly that of POST with the singular exception that
nothing is durably changed. In other words, POSIT skips the `store` step.

#### Steps
- parse
- authorize
- conjugate
- apply
- project

### GET
#### Steps
- authorize
- get
- project

### DELETE
#### Steps
- authorize
- get
- archive&ast;

### QUERY
#### Steps
- parse
- authorize
- query
- project

Multiplexing and Batching
----------
Rather than requiring protocol specific support for pipelining commands, Intents can be sent
in batches. Of course, these batches can only be addressed to a single URL, thus this "pipelining"
is constrained to just one resource. Succinctly, you can POST/POSIT an array of Intents to an Aggregate Root/Revision.

You can also POST/POSIT a multiplexed Intent, i.e. a message that contains orthogonal batches, to an
Aggregate Root/Revision.
`413 Request Entity Too Large` if [DynamoDb limits](http://docs.aws.amazon.com/amazondynamodb/latest/APIReference/API_BatchWriteItem.html)

### Batch
### Use Cases
#### POSIT alternative futures
#### POSIT alternate FORK

Implementation Dependencies
---------------------------
### Cache
Process exclusive, LRU, thread-safe for read and write

### Consisten Hash Routing

### Backing Store


Read Guarantees
--------------
>"Every object should have a URL." --Alan Kay

An Aggregate Root is intended to be resident in one and only one process.
Dereferencing a URL should result in the request being routed to the same
process, as long as that process is running. In most non-production scenarios,
this means hosting everything in one web server process. In production, though,
most implementations will want to improve availability and scalability by
hosting a Hyperobject on multiple servers. To do this and maintain the required
locality, a routing layer must be in place that does consistent hashing to
determine which server gets the request.

If the requested Aggregate Root doesn't exist in the Cache, then a consistent
read of the backing store is done, in all cases. This means that, ostensibly,
GET requests could be handled by any server hosting the Hyperobject, but to
ensure the highest level of consistency all reads and writes should be routed to
the same server.

Write Guarantees
----------
Ultimately, so much depends on the backing data store. Hyperobjects are more of
an architectural style than a tech stack. This first implementation uses the
amazing AWS DynamoDb. Concordantly, we have to accept very specific tradeoffs.
Importantly, we might see throttling due to
[hot keys](https://medium.com/medium-eng/how-medium-detects-hotspots-in-dynamodb-using-elasticsearch-logstash-and-kibana-aaa3d6632cfd).

### ACID
Mutations to an Aggregate Root are always serialized. Reads are consistent as of
the time they are processed, but they are always "read committed", i.e. the read
Cache is only updated when the write to the backing store is committed. *There
exists the possibility that the Cache could fail to be updated after the write
is committed to the backing store.* While extremely unlikely the consequences
are dependent upon the circumstances of the failure:

- If the Cache remains in service, but e.g. the thread was aborted, this will
result in a phantom write, i.e. the committed write will be overwritten by the
next write. Importantly, the external view remains consistent in this kind of
failure; the aborted thread will result in a 500 error being returned, so the
client will never have seen it's Intent acknowledged.
- If the Cache was unavailable, the node should fail entirely. In this case
the next read will will be consistent (in a different process) and will show
the write.
- TODO are there other ways this could fail?

### CAP
One way to think of a Hyperobject is a kind of domain-specific database. As long
as all the nodes have access to the backing store (disk, DFS, database, etc.),
they can all function to accept reads and writes. If any one node cannot connect
to the backing store, that node alone fails. Ideally this would result in a
health check failure as well and its designated Aggregate Root complement would
be handled by other servers.

Interestingly, a Hyperobject node could continue serving reads even without
access to the backing store, since any in-memory resident Aggregate Root can be
considered definitive. Of course, should the Aggregate Root not be resident when
the backing store becomes unavailable, reads will not be possible.

Choosing DynamoDb as a backing store has a number of benefits and tradeoffs.

No Transactor
-------------
Unlike Datomic, there is no central transactor component, i.e. there is no
coordination of reads or writes among the various servers hosting the
Hyperobject. This is possible because the consistent hashing router, and we
accept that a subset of aggregates will be unavailable if a node goes down. As
Joe Armstrong says, availability and horizontal scalability are the same thing.

