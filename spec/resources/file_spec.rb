require_relative '../spec_helper'

# The purge action decides what to remove by asking the resource collection
# which limits Chef declares, rather than by looking at the file. That rule
# is the whole behavior of the action and it cannot be tested without a
# converge, since there is no resource collection otherwise.
#
# Stepping into limits_file converges the custom resource for real while
# leaving the file resource it declares alone, so the assertions are made
# against the content that resource was handed and nothing is written.
describe 'limits_file' do
  platform 'ubuntu', '24.04'
  step_into :limits_file

  let(:path) { '/etc/security/limits.conf' }

  let(:seed) do
    <<~'LIMITS'
      kitchen soft nofile 1024
      stranger hard nproc 50
    LIMITS
  end

  # The path the limit resource claims, which is the same as the file being
  # purged except where a context says otherwise.
  let(:declared_path) { path }

  # The same stubbing the library specs use, with the difference that a
  # converge reads a great many files that are not this one, so the real
  # implementation has to stay reachable underneath.
  before do
    allow(::File).to receive(:exist?).and_call_original
    allow(::File).to receive(:read).and_call_original
    allow(::File).to receive(:exist?).with(path).and_return(true)
    allow(::File).to receive(:read).with(path).and_return(seed)
  end

  # converge_block runs its block against a Chef::Recipe, so the example's
  # own methods and instance variables are out of scope inside it. Locals
  # are not, because the block closes over them.
  let(:chef_run) do
    purged = path
    declared = declared_path

    chef_runner.converge_block do
      limits_file purged do
        action :purge
      end

      limit 'declared but never converged' do
        path declared
        domain 'kitchen'
        type 'soft'
        item 'nofile'
        value 1024
        action :nothing
      end
    end
  end

  describe 'action :purge' do
    context 'with a limit resource declaring one of the limits in the file' do
      # The limit declares action :nothing and nothing notifies it, so it
      # never converges. Being in the collection is the whole of what
      # protects it, which is why the action reads the collection rather
      # than asking the file what is already in it.
      it 'keeps the declared limit' do
        expect(chef_run).to render_file(path)
          .with_content(/^kitchen\s+soft\s+nofile\s+1024$/)
      end

      it 'removes a limit no resource declares' do
        expect(chef_run).to_not render_file(path).with_content(/stranger/)
      end

      # A file managed by purge alone still gets the resource's ownership
      # and mode, rather than keeping whatever it already had.
      it 'carries owner, group and mode' do
        expect(chef_run).to create_file(path)
          .with(owner: 'root', group: 'root', mode: '0644')
      end
    end

    context 'with the limit resource naming a different path' do
      let(:declared_path) { '/etc/security/limits.d/elsewhere.conf' }

      it 'removes the limit it does not protect' do
        expect(chef_run).to_not render_file(path)
          .with_content(/^kitchen\s+soft\s+nofile\s+1024$/)
      end
    end

    context 'with every limit in the file declared by a resource' do
      let(:seed) { "kitchen soft nofile 1024\n" }

      # The action was not asked to create anything, so with nothing to
      # remove it hands the file resource no content and the file keeps
      # whatever format it was already in.
      it 'leaves the content alone' do
        expect(chef_run.file(path).content).to be_nil
      end

      # Ownership and mode are not conditional on a run finding something
      # to purge. A file corrected on the run that purged it and then
      # chmodded by hand would never be corrected again, because every run
      # after the first has nothing left to remove.
      it 'still carries owner, group and mode' do
        expect(chef_run).to create_file(path)
          .with(owner: 'root', group: 'root', mode: '0644')
      end
    end

    context 'with no file on the path at all' do
      before do
        allow(::File).to receive(:exist?).with(path).and_return(false)
      end

      # Purge manages a file somebody else wrote. It is not a way to ask
      # for one, so it declares nothing rather than laying down an empty
      # file with the resource's ownership on it.
      it 'declares no file resource' do
        expect(chef_run).to_not create_file(path)
      end
    end
  end
end
