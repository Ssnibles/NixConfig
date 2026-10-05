// Worked assignment-report skeleton (fictional). Copy the shape, not the content.
// Compiles stand-alone in a notes repo: `typst compile --root <repo> <this>`.

#import "/templates/theme.typ": *
#show: theme.with(course: "COMPX000")

#set document(title: "COMPX000 Assignment 2 — Report")
#let date = "Assignment 2"

#note-title(date, "Assignment 2 — Report")

#card[
  *The big picture.* The brief asks for a bounded producer–consumer queue with a
  documented design and tests. This report maps each mark-scheme item to a section,
  then gives the design, the implementation, and the evidence.
]

== Requirements map

#block(radius: ui-radius, clip: true, stroke: 0.5pt + ui-border)[
  #table(
    columns: (auto, auto, auto),
    fill: (col, row) => if row == 0 { ui-surface-raised } else { none },
    inset: (x: 10pt, y: 6pt),
    stroke: (x, y) => (top: if y > 0 { 0.5pt + ui-border } else { none }, left: if x > 0 { 0.5pt + ui-border } else { none }),
    table.header([*Requirement*], [*Marks*], [*Where*]),
    [Bounded, thread-safe queue], [10], [§Design, §Implementation],
    [Blocking put/get], [10], [§Implementation],
    [Tests and evidence], [5], [§Testing],
    [Discussion of trade-offs], [5], [§Discussion],
  )
]

== Design

The queue is a monitor: a fixed-size array guarded by one lock, with two condition
variables, `notFull` and `notEmpty`.

#uml-class(
  "BoundedQueue",
  fields: ("- items: T[]", "- head: Int", "- count: Int", "- lock: Lock"),
  methods: ("+ put(T): void", "+ get(): T", "- waitNotEmpty(): void"),
)

Using a single lock keeps the invariant simple; the cost is that producers and
consumers contend, which §Discussion revisits.

== Implementation

```java
BoundedQueue.java
public void put(T item) throws InterruptedException {
    lock.lock();
    try {
        while (count == items.length) notFull.await();
        items[(head + count) % items.length] = item;
        count++;
        notEmpty.signal();
    } finally {
        lock.unlock();
    }
}
```

The loop (not an `if`) re-checks the condition after every wake-up, so a spurious
wake-up cannot corrupt the buffer.

== Testing

#block(radius: ui-radius, clip: true, stroke: 0.5pt + ui-border)[
  #table(
    columns: (auto, auto, auto),
    fill: (col, row) => if row == 0 { ui-surface-raised } else { none },
    inset: (x: 10pt, y: 6pt),
    stroke: (x, y) => (top: if y > 0 { 0.5pt + ui-border } else { none }, left: if x > 0 { 0.5pt + ui-border } else { none }),
    table.header([*Test*], [*Input*], [*Expected*]),
    [Empty get blocks], [consumer on empty queue], [blocks until a put],
    [Put beyond capacity], [capacity + 1 puts], [blocks until a get],
    [FIFO order], [put 1, 2, 3; get ×3], [1, 2, 3],
  )
]

All tests pass. The boundary cases (empty and full) are the ones that exposed the
original `if`-instead-of-`while` bug.

== Discussion

The single-lock design prioritises correctness and simplicity over throughput. A
two-lock or lock-free queue would scale better under heavy contention but is harder
to verify; for the brief's workload the monitor is the right trade-off.

== References

Cite the course text and any sources used, in the required style.
