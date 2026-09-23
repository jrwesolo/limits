Choosing a test layer
=====================

`CONTRIBUTING.md` says which layer a new test goes in, and `TESTING.md`
how each layer is built. This is the part usually learned by breaking
something: what each layer cannot see, and the traps in each.

The cheapest layer that can catch the regression wins. A test that could
have been a library spec and was written as an integration control costs
a container and a minute every run, forever, and usually proves less.

`spec/resources`, ChefSpec
--------------------------

Keep it to what only a converge decides. Most resource behavior is
library behavior reached the long way round, and belongs in
`spec/libraries`.

`step_into` converges the resource for real, and these resources read
whichever path they are handed. Stub `::File` for the managed path, or
the spec reads the host's own `/etc/security/limits.conf`. Writing is
not the risk: ChefSpec skips every resource it has not stepped into,
including one a custom resource runs directly.

The two resources are not visible in the same way. `limits_file` declares
its file resource, so `create_file` and `render_file` work against it.
`limit` runs its file resource rather than declaring it, so that resource
never enters the collection and no matcher can see it or what it was
handed. Test a limit through what `converge_if_changed` decides, with a
recorder the limit notifies, and leave the content to `spec/libraries`.
The one exception is whether the file resource is used at all, which a
spec answers by wrapping `Chef::Resource::File.new` to catch the
instance. Stub `::File.write` for the managed path in that spec, so a
regression fails on the assertion rather than on the host refusing the
write, and cannot write the host's file either.

ChefSpec cannot tell whether `limits_file` reported itself updated. It
replaces `Chef::Provider#compile_and_converge_action` with a bare
`instance_eval`, so the step that marks a resource updated because a
resource it declared was updated never runs, and a `limits_file` always
looks up to date. Its notification tests live in the integration suite
for that reason.

`chefspec` is required from `spec/spec_helper.rb` rather than from the
specs that need it. Its RSpec integration is a `config.include`, and
RSpec injects a module added after a group exists into that group. Its
API defines a default `subject` of the Chef run, so requiring it from a
file loaded after `spec/libraries` overrides the subject those groups
already declared, and `describe 'Limits::ITEMS'` starts looking for a
cookbook named `Limits`.

`test/integration`, Test Kitchen and InSpec
-------------------------------------------

Everything that is only true of a real filesystem: the bytes that land,
ownership and mode, and idempotency across a second converge. The suites
run with `deprecations_as_errors` and `enforce_idempotency`, so a
resource that is not idempotent fails rather than merely looking noisy.

This is the layer that costs the most, so anything that can be decided
without a container should be.
