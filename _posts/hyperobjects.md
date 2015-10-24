Hyperobjects
=========
Introduction
------------
1. What should CQRS + Event Sourcing + REST look like in the cloud?
2. How can we provide a general and powerful domain-specific data store via
   HTTP?
3. How can we leverage immutability to create generalized enhanced capability?
4. How can we obviate the impedence mismatch between in-memory objects and
   durable writes?

### Intents
- Uniform Interface: the only message sent from clients to do work
- Activity URN: nominates the semantics for the Data property
- Tracking Id: supplied by client and can be used to correlate projections to
  client state

### Events
- Only state ever stored
- Serves as the record that a particular business activity has transpired
- Not always in one-to-one correspondence to an Intent, but can usually be
  viewed semantically as the "past tense" of an Intent.
- Mostly inconsequential to clients since the projected state is always returned

URL Anatomy
----------
URLs are translucent identifiers.

> http://bounded-context/logical-aggregate/aggregate-root-entity-id/

- DNS host name --> bounded context
- logical aggregate --> DDD aggregate
- entity id --> UUIDv4, therefore not guessable and do not disclose info

Logical Aggregate
---------------
Used to create new aggregate roots (POST/POSIT) and to search for them (QUERY).
If you wanted to see what a default Aggregate Root looked like you could POSIT
a create.
You can GET this to learn about what the aggregate does, i.e. the valid Intents
and Entity schema. You can also find out about the supported media types.

> http://bounded-context/logical-aggregate/aggregate-root-entity-id/history

Aggregate Root
--------------
Implements all the biz logic by processing Intents (POST/POSIT)
You can GET a representation and QUERY for specific properties/entities

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

POST to a `Revision`: implicit `FORK`, `303 See Other` with `Location` pointing to the new Aggregate Root

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
