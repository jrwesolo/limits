Writing the custom resources
============================

What the two resources in `resources/` do that is not obvious, and why.
Read this before changing how either one writes a file.

Write through Chef's file resource
----------------------------------

Neither resource writes a limits file itself. Both render the content
with `Limits::File#to_s` and hand it to Chef's file resource.

Replacing a file safely has details that are easy to get wrong by hand.
Chef maintains and tests that code, so do not reimplement it in the
library.

`limit` runs it, `limits_file` declares it
------------------------------------------

The two resources reach the file resource differently, on purpose, and
making them consistent in either direction breaks something.

A declared resource reports itself. `limit` is declared once per limit
and writes the whole file each time, so twenty limits on one path would
put twenty file resources in the run and print twenty diffs of the same
file differing by a line each. The limit already reports its own change
through `converge_if_changed`, and that is the change a reader cares
about. So `limit` constructs the file resource against a throwaway run
context and calls `run_action` on it directly. The silence comes from
the run context rather than from the resource: an event dispatcher with
nothing subscribed to it means the formatter never hears about the
write. Chef does exactly this in
`Chef::GuardInterpreter::ResourceGuardInterpreter`.

`limits_file` must keep its file resource declared. It has no
`converge_if_changed` of its own, so the declared file resource is the
only thing that can mark it updated. Run quietly, it would always report
itself up to date, every `notifies` hung off it would stop firing, and
Test Kitchen's idempotency check would pass whatever it did.

The throwaway run context
-------------------------

Three details of the context `limit` builds matter. Two fixed real
bugs, and the third is defensive.

It gets a copy of the node rather than the node. `RunContext#node=`
reassigns `node.run_context`, so handing it the real node leaves the
rest of the run pointing at a context that is about to be discarded.
Chef issue 3485 is titled "Silent corruption of node.run_context".

The copy is made with `clone`, not `dup`. For a real run they are the
same thing, since `Chef::Node` overrides no copy hook and both are
shallow. They differ on the singleton class, which `dup` drops, and
ChefSpec defines the node's `#runner` method there and then calls it
from its own `run_action`. A `dup` makes `step_into` raise
`NoMethodError` in any cookbook that tests this resource.

`freeze: false`, because `clone` carries frozen state and
`RunContext#node=` writes to the copy, so a plain `clone` of a frozen
node raises `FrozenError` and fails every limit. Chef never freezes a
node itself, but a recipe can call `node.freeze` partway through a run.

What testing can see follows from this: see `test-layers.md`.

Validation belongs on the properties
------------------------------------

The field callbacks ask the same question `Limits::Entry` raises on, so
a user gets a property validation failure naming the property rather
than an exception out of a library class. Keep them in step: a rule that
exists only in the library is a rule the user meets as a stack trace.

`backup false`, deliberately
----------------------------

`limit` writes the whole file once per limit, so a run with twenty
limits on one path performs twenty writes. Backups assume a resource
that writes a file once, and this one does not. A file whose permissions
or backups should be managed gets a `limits_file` resource on it.
