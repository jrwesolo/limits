require_relative '../spec_helper'

# Three things here that nothing else can reach.
#
# The first is what converge_if_changed decides. A limit writes its file
# through a Chef file resource run against an event dispatcher nobody is
# subscribed to, so that write reports nothing and converge_if_changed is
# the only thing that can mark the resource updated. Everything a user
# hangs off a limit, every notifies and every subscribes, rests on that
# decision being right.
#
# The second is property validation, which the integration suites cannot
# test at all: a limit that fails validation fails the converge, and a
# converge that fails is a Test Kitchen run that fails.
#
# The third is that the file is written through Chef's file resource at
# all, which is what makes the write replace the file in one step. Nothing
# else notices a regression to a direct write, since the bytes are the
# same.
#
# What is deliberately absent is any assertion about the bytes written
# beyond that one limit. The file resource is run rather than declared, so
# it never enters the resource collection and no matcher can see it. The
# content it is handed is Limits::File#to_s, which spec/libraries covers
# directly, and the file that lands on disk is covered by the integration
# suites.
describe 'limit' do
  platform 'ubuntu', '24.04'
  step_into :limit

  let(:path) { '/etc/security/limits.conf' }

  let(:seed) do
    <<~'LIMITS'
      # a comment belonging to the limit below
      kitchen soft nofile 1024
    LIMITS
  end

  # The same stubbing the library specs use, with the difference that a
  # converge reads a great many files that are not this one, so the real
  # implementation has to stay reachable underneath.
  before do
    allow(::File).to receive(:exist?).and_call_original
    allow(::File).to receive(:read).and_call_original
    allow(::File).to receive(:exist?).with(path).and_return(true)
    allow(::File).to receive(:read).with(path).and_return(seed)
  end

  # The limit already in the seed, named by the three properties that
  # identify one.
  def existing
    { domain: 'kitchen', type: 'soft', item: 'nofile' }
  end

  # A recorder is what makes the converge decision observable. The
  # parameter is not called action, because a local by that name inside
  # the block would shadow the action method the resources use.
  #
  # converge_block runs its block against a Chef::Recipe, so the example's
  # own methods are out of scope inside it. Locals are not, because the
  # block closes over them.
  def converge_limit(properties, wanted = :create)
    limits_path = path

    chef_runner.converge_block do
      ruby_block 'recorder' do
        block {}
        action :nothing
      end

      limit 'under test' do
        path limits_path
        properties.each { |property, value| send(property, value) }
        action wanted
        notifies :run, 'ruby_block[recorder]', :immediately
      end
    end
  end

  describe 'action :create' do
    it 'does nothing when the limit is already what it should be' do
      expect(converge_limit(existing.merge(value: 1024)))
        .to_not run_ruby_block('recorder')
    end

    # A value arrives as a String from a node attribute or a template as
    # readily as it does as an Integer, and the two have to compare equal
    # or the resource would rewrite the file on every run.
    it 'does nothing when a numeric string equals the value in the file' do
      expect(converge_limit(existing.merge(value: '1024')))
        .to_not run_ruby_block('recorder')
    end

    it 'converges when the value differs' do
      expect(converge_limit(existing.merge(value: 2048)))
        .to run_ruby_block('recorder')
    end

    # A comment is written with every line rstripped, so one carrying
    # trailing whitespace could never equal the comment read back off disk.
    # The property coerces to the same normalized form the parser yields,
    # which is what keeps this from converging forever on a file it is
    # already happy with.
    it 'does nothing when the comment differs only by trailing whitespace' do
      already = 'a comment belonging to the limit below'

      expect(converge_limit(existing.merge(value: 1024, comment: "#{already}   ")))
        .to_not run_ruby_block('recorder')
    end

    # A comment holds its own text. The '#' in the file belongs to the
    # file, so giving the property the text alone matches what is already
    # there, and giving it a '#' of its own asks for a different comment.
    it 'does nothing when the comment matches the text already in the file' do
      expect(converge_limit(existing.merge(value: 1024, comment: 'a comment belonging to the limit below')))
        .to_not run_ruby_block('recorder')
    end

    it 'converges when the comment adds a hash the file does not have' do
      expect(converge_limit(existing.merge(value: 1024, comment: '# a comment belonging to the limit below')))
        .to run_ruby_block('recorder')
    end

    # The case that could not be expressed at all while the property took a
    # '#' off what it was given. Nothing is refused now, and it settles.
    context 'with a comment whose own text starts with a hash' do
      let(:seed) do
        <<~'LIMITS'
          # #4127 see the ticket
          kitchen soft nofile 1024
        LIMITS
      end

      it 'does nothing when the file already carries it' do
        expect(converge_limit(existing.merge(value: 1024, comment: '#4127 see the ticket')))
          .to_not run_ruby_block('recorder')
      end
    end

    it 'converges when only the comment differs' do
      expect(converge_limit(existing.merge(value: 1024, comment: 'different words')))
        .to run_ruby_block('recorder')
    end

    it 'converges when the limit is not in the file at all' do
      expect(converge_limit(domain: 'newcomer', type: 'hard', item: 'nproc', value: 20))
        .to run_ruby_block('recorder')
    end
  end

  describe 'action :delete' do
    it 'converges when the limit is there' do
      expect(converge_limit(existing, :delete)).to run_ruby_block('recorder')
    end

    # load_current_value gives up on a limit that is not in the file, and
    # the action is written to do nothing rather than to write the file
    # back out unchanged.
    it 'does nothing when the limit is not there' do
      expect(converge_limit({ domain: 'stranger', type: 'hard', item: 'nproc' }, :delete))
        .to_not run_ruby_block('recorder')
    end
  end

  # A limit replaces its file in one step, so pam never reads a partial
  # one, and that holds only while the content goes through Chef's file
  # resource. A direct ::File.write truncates the destination first, writes
  # the same bytes, and passes every other test here and in the integration
  # suites. The file resource is run rather than declared, so no matcher can
  # see it, and it is caught on its way through instead.
  #
  # ::File.write is stubbed for the managed path so that a regression fails
  # on the assertion below rather than on the host refusing the write, and
  # so that it cannot touch the host's own file.
  describe 'writing the file' do
    it 'hands the content to a file resource rather than writing it directly' do
      allow(::File).to receive(:write).and_call_original
      allow(::File).to receive(:write).with(path, anything)

      handed = []
      allow(Chef::Resource::File).to receive(:new).and_wrap_original do |original, *args|
        original.call(*args).tap do |resource|
          next unless resource.path == path

          allow(resource).to receive(:run_action).and_call_original
          handed << resource
        end
      end

      converge_limit(existing.merge(value: 2048))

      expect(::File).to_not have_received(:write).with(path, anything)
      expect(handed.size).to eq(1)
      expect(handed.first.content).to match(/^kitchen\s+soft\s+nofile\s+2048$/)
      expect(handed.first).to have_received(:run_action).with(:create)
    end
  end

  # Whitespace and '#' are refused because pam_limits splits a line on
  # whitespace and ends it at a '#', so a field carrying either could not
  # be read back from the file it was written to. The resource asks the
  # question so that the failure names the property, rather than letting
  # it surface later out of Limits::Entry.
  describe 'property validation' do
    it 'refuses a domain containing whitespace' do
      expect { converge_limit(existing.merge(domain: 'two words', value: 1)) }
        .to raise_error(Chef::Exceptions::ValidationFailed, /whitespace/)
    end

    it 'refuses a value containing a hash' do
      expect { converge_limit(existing.merge(value: 'no#good')) }
        .to raise_error(Chef::Exceptions::ValidationFailed, /whitespace or #/)
    end

    it 'refuses an empty domain' do
      expect { converge_limit(existing.merge(domain: '', value: 1)) }
        .to raise_error(Chef::Exceptions::ValidationFailed, /should not be empty/)
    end

    it 'refuses a type that is not soft, hard or both' do
      expect { converge_limit(existing.merge(type: 'sideways', value: 1)) }
        .to raise_error(Chef::Exceptions::ValidationFailed)
    end

    it 'refuses an item pam_limits does not define' do
      expect { converge_limit(existing.merge(item: 'bogus', value: 1)) }
        .to raise_error(Chef::Exceptions::ValidationFailed)
    end

    it 'requires a value to create a limit' do
      expect { converge_limit(existing) }
        .to raise_error(Chef::Exceptions::ValidationFailed)
    end
  end
end
