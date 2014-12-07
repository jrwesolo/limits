name             'limits'
maintainer       'Jordan Wesolowski'
maintainer_email 'jrwesolo@gmail.com'
license          'MIT'
description      'Configures limits'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version '1.0.0'

# Berkshelf blows up with these, will add later.
# source_url 'https://github.com/jrwesolo/limits'
# issues_url 'https://github.com/jrwesolo/limits/issues'

%w(ubuntu debian fedora centos redhat).each do |p|
  supports p
end
