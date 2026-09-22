module Limits
  REGEX = Regexp.new(<<-'EOF', Regexp::EXTENDED).freeze
    ^(?<comment>(?:[ \t]*+\#.*+\n)++)? # optional comment (supports multi-line)
    [ \t]*+(?<domain>[^\s#]++)         # domain
    [ \t]++(?<type>[^\s#]++)           # type
    [ \t]++(?<item>[^\s#]++)           # item
    [ \t]++(?<value>[^\s#]++)          # value
    [ \t]*+(?<inline_comment>\#.*+)?$  # optional inline comment
  EOF

  # A field has to survive being written into a line and read back by
  # REGEX above, which captures each of the four as [^\s#]++. Whitespace
  # separates fields and a '#' ends the line, in this parser and in
  # pam_limits, so a field carrying either character cannot describe a
  # limit in the first place and there is no valid input this excludes.
  FIELD = /\A[^\s#]+\z/.freeze

  # https://man7.org/linux/man-pages/man5/limits.conf.5.html
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
