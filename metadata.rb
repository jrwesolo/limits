name             'limits'
maintainer       'Jordan Wesolowski'
maintainer_email 'N/A'
license          'MIT'
description      'Configures limits for the pam_limits module'
version          '2.1.0'
chef_version     '>= 12', '< 17'

# The `source_url` points to the development repository for this cookbook.  A
# `View Source` link will be displayed on this cookbook's page when uploaded to
# a Supermarket.
source_url 'https://github.com/jrwesolo/limits'

# The `issues_url` points to the location where issues for this cookbook are
# tracked.  A `View Issues` link will be displayed on this cookbook's page when
# uploaded to a Supermarket.
issues_url 'https://github.com/jrwesolo/limits/issues'

%w(centos debian fedora redhat ubuntu).each do |platform|
  supports platform
end
