module Limits
  REGEX = Regexp.new(<<-'EOF', Regexp::EXTENDED).freeze
    ^(?<comment>(?:[ \t]*+\#.*+\n)++)? # optional comment (supports multi-line)
    [ \t]*+(?<domain>[^\s#]++)         # domain
    [ \t]++(?<type>[^\s#]++)           # type
    [ \t]++(?<item>[^\s#]++)           # item
    [ \t]++(?<value>[^\s#]++)          # value
    [ \t]*+(?<inline_comment>\#.*+)?$  # optional inline comment
  EOF

  # http://linux.die.net/man/5/limits.conf
  TYPES = %w(- hard soft).freeze
  ITEMS = %w(
    as
    chroot
    core
    cpu
    data
    fsize
    locks
    maxlogins
    maxsyslogins
    memlock
    msgqueue
    nice
    nofile
    nproc
    priority
    rss
    rtprio
    sigpending
    stack
  ).freeze
end
