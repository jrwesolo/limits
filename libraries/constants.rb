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

  # Every item that man page documents, plus 'chroot'. Three of them are
  # not available everywhere, and the limit resource deliberately does not
  # gate on that. pam_limits logs an unknown item and skips the line, so
  # accepting one here writes a line that a newer pam honors, whereas
  # rejecting it would leave somebody on a current distribution unable to
  # set a limit their module supports. Which pam is installed on the node
  # is the operator's business, not this cookbook's.
  #
  #   chroot      A Debian patch rather than upstream, so it is absent from
  #               the man page above. Present on Debian and Ubuntu, absent
  #               on Fedora and Enterprise Linux.
  #   nonewprivs  Linux-PAM 1.5.0, released 2020-11-10.
  #   rttime      Linux-PAM 1.7.1, released 2025-06-17, so still ahead of
  #               most distributions. Of the platforms tested here only
  #               Fedora carries a pam new enough to honor it.
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
    nonewprivs
    nproc
    priority
    rss
    rtprio
    rttime
    sigpending
    stack
  ).freeze
end
