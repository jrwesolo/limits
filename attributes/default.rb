# for system limits.conf
default['limits']['system_conf'] = '/etc/security/limits.conf'

# for limits.d
default['limits']['conf_dir'] = '/etc/security/limits.d'

# attributes to LWRP mapping, for example
# limits: {
#   files: {
#     system: [
#       {domain: "*", type: "-", item: "nice", value: "0",}
#     ],
#     userx: [
#       {domain: "userx", type: "-", item: "nofile", value: "4096",}
#     ],
#   },
# }
default['limits']['files'] = {}

