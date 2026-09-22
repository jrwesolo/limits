control 'limits-conf-file' do
  impact 1.0
  title 'limits.conf is left owned by root with the declared mode'
  desc <<~DESC
    The setup recipe seeds this file owned by an unprivileged user at mode
    0755. Correcting that is part of what the create action does, since the
    file resource it declares carries the owner, group and mode properties
    of the limits_file resource.
  DESC

  describe file('/etc/security/limits.conf') do
    it { should exist }
    its('owner') { should eq 'root' }
    its('group') { should eq 'root' }
    its('mode') { should cmp '0644' }
  end
end

control 'limits-conf-purge' do
  impact 1.0
  title 'limits.conf keeps only the limits the run declares'
  desc <<~DESC
    The fixture seeds seven limits and the recipe declares three of them,
    one as a delete, plus a delete of one that was never there. Everything
    else has to go, which is the whole difference between the create action
    and the purge action. Each expectation uses eq rather than include so
    that a duplicate would fail too.
  DESC

  describe limits_conf('/etc/security/limits.conf') do
    its('*') { should eq [%w(hard rss 20000)] }
    its('@faculty') { should eq nil }
    its('@student') { should eq [%w(hard nproc 20)] }
    its('apple') { should eq nil }
    its('ftp') { should eq nil }
  end
end

control 'limits-conf-comments' do
  impact 1.0
  title 'limits.conf keeps and adds comments as the recipe asks'
  desc <<~DESC
    Carrying a comment through a value change is the reason this cookbook
    exists rather than a template, and the limits_conf resource reports
    limits without comments, so both directions have to be read out of the
    file content: a comment that was already attached to a limit whose value
    changed, and a comment added to a limit that had none.
  DESC

  describe 'the rewritten limits.conf' do
    subject { file('/etc/security/limits.conf').content }

    it 'keeps a multi-line comment attached to a limit whose value changed' do
      expect(subject).to match(
        /# This is a test of a\n# multi-line comment\n\*\s+hard\s+rss\s+20000/
      )
    end

    it 'writes a comment onto a limit that had none' do
      expect(subject).to match(
        /# This is a new comment\n@student\s+hard\s+nproc\s+20/
      )
    end
  end
end

control 'limits-conf-rewrite' do
  impact 1.0
  title 'limits.conf is rewritten in the cookbook format'
  desc <<~DESC
    The rewrite stamps a header and a footer counting what it kept, and
    drops anything it could not parse. The fixture carries two lines that
    say in their own text that they should be removed: a line that is not a
    limit, and a comment attached to nothing.
  DESC

  describe 'the rewritten limits.conf' do
    subject { file('/etc/security/limits.conf').content }

    it 'writes the managed-by-Chef header' do
      expect(subject).to include('# This file is managed by Chef')
    end

    it 'counts the limits it kept in the footer' do
      expect(subject).to match(/# End of file \(2 limits\)/)
    end

    it 'drops a line that is not a limit' do
      expect(subject).to_not include('this is not a valid limit')
    end

    it 'drops a comment attached to no limit' do
      expect(subject).to_not include('any limit and should be removed')
    end
  end
end

control 'unpurged-file' do
  impact 1.0
  title '100_unpurged.conf takes the ownership and mode it was given'
  desc <<~DESC
    Seeded at mode 0755 owned by an unprivileged user, and declared at 0640,
    so this proves the create action applies a mode that differs from the
    default as well as correcting ownership.
  DESC

  describe file('/etc/security/limits.d/100_unpurged.conf') do
    it { should exist }
    its('owner') { should eq 'root' }
    its('group') { should eq 'root' }
    its('mode') { should cmp '0640' }
  end
end

control 'unpurged-limits' do
  impact 1.0
  title '100_unpurged.conf keeps limits no resource declares'
  desc <<~DESC
    This file is managed with the create action alone. A limit that the run
    never mentions has to survive, which is exactly what the purge action
    would have removed from limits.conf.
  DESC

  describe limits_conf('/etc/security/limits.d/100_unpurged.conf') do
    its('kitchen') { should include %w(soft core 0) }
    its('kitchen') { should include %w(soft cpu 66) }
  end

  describe 'the rewritten 100_unpurged.conf' do
    subject { file('/etc/security/limits.d/100_unpurged.conf').content }

    it 'keeps a limit it does not manage, since this file is not purged' do
      expect(subject).to match(/kitchen\s+soft\s+core\s+0/)
    end

    it 'writes the comment that came with the new limit' do
      expect(subject).to match(/# Comment for new limit\nkitchen\s+soft\s+cpu\s+66/)
    end

    it 'drops the comment the fixture attached to no limit' do
      expect(subject).to_not include('starting point')
    end
  end
end

control 'unmanaged-file' do
  impact 0.5
  title '200_unmanaged.conf is created by the limit resource alone'
  desc <<~DESC
    Nothing seeds this file and no limits_file resource manages it, so it is
    created by Limits::File#write! rather than by Chef's file resource. That
    means no owner, group or mode is enforced on it and the mode comes from
    the umask of the client run.

    The impact is lower than the rest because this control documents a gap
    rather than a guarantee. A file only gets managed permissions if a
    limits_file resource manages it, and the assertion is here so that the
    gap is visible rather than assumed.
  DESC

  describe file('/etc/security/limits.d/200_unmanaged.conf') do
    it { should exist }
    its('owner') { should eq 'root' }
    its('mode') { should cmp '0644' }
  end
end

control 'unmanaged-limit' do
  impact 1.0
  title 'a limit creates the file it is pointed at'
  desc <<~DESC
    The limit resource writes to whatever path it is given, whether or not
    anything else has ever managed that path, and whether or not the file
    exists yet.
  DESC

  describe limits_conf('/etc/security/limits.d/200_unmanaged.conf') do
    its('kitchen') { should include %w(hard nofile 65536) }
  end
end

control 'deleted-file' do
  impact 1.0
  title '300_deleted.conf is removed by the delete action'
  desc <<~DESC
    The setup recipe seeds this file so that deleting it proves something.
    Asserting the absence of a file nobody ever created would pass whether
    or not the action worked.
  DESC

  describe file('/etc/security/limits.d/300_deleted.conf') do
    it { should_not exist }
  end
end

control 'created-file' do
  impact 1.0
  title '400_created.conf is built from nothing by the create action'
  desc <<~DESC
    Every other managed file in the suite starts from one the setup recipe
    laid down, so without this the create action is never asked to make a
    file rather than adopt one.
  DESC

  describe file('/etc/security/limits.d/400_created.conf') do
    it { should exist }
    its('owner') { should eq 'root' }
    its('group') { should eq 'root' }
    its('mode') { should cmp '0600' }
  end

  describe 'the rewritten 400_created.conf' do
    subject { file('/etc/security/limits.d/400_created.conf').content }

    it 'writes the header into a file it created itself' do
      expect(subject).to include('# This file is managed by Chef')
    end

    it 'counts the limits it holds' do
      expect(subject).to match(/# End of file \(2 limits\)/)
    end
  end
end

control 'boolean-item' do
  impact 1.0
  title 'nonewprivs is written like any other item'
  desc <<~DESC
    nonewprivs takes 0 or 1 rather than a size or a count, and it is one of
    the items this cookbook accepts that an older pam_limits does not know.
    Of the platforms tested here every one carries a pam new enough, since
    the item landed in Linux-PAM 1.5.0.

    What is asserted is that the resource writes the line. Whether the
    module acts on it is a property of the pam installed on the node, which
    this cookbook does not and should not inspect.
  DESC

  describe limits_conf('/etc/security/limits.d/400_created.conf') do
    its('kitchen') { should include %w(hard nonewprivs 1) }
  end
end

control 'created-word-value' do
  impact 1.0
  title 'a value that is a word survives unchanged'
  desc <<~DESC
    pam_limits takes unlimited, infinity and -1 for most items, so the
    cookbook has to carry a word through to the file rather than coercing it
    to a number on the way.
  DESC

  describe limits_conf('/etc/security/limits.d/400_created.conf') do
    its('kitchen') { should include %w(hard nofile unlimited) }
  end
end
