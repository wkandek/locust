# Class: locust
# ===========================
#
# Full description of class locust here.
#
# Parameters
# ----------
#
# Document parameters here.
#
# * `sample parameter`
# Explanation of what this parameter affects and what it defaults to.
# e.g. "Specify one or more upstream ntp servers as an array."
#
# Variables
# ----------
#
# Here you should define a list of variables that this module would require.
#
# * `sample variable`
#  Explanation of how this variable affects the function of this class and if
#  it has a default. e.g. "The parameter enc_ntp_servers must be set by the
#  External Node Classifier as a comma separated list of hostnames." (Note,
#  global variables should be avoided in favor of class parameters as
#  of Puppet 2.6.)
#
# Examples
# --------
#
# @example
#    class { 'locust':
#      servers => [ 'pool.ntp.org', 'ntp.local.company.com' ],
#    }
#
# Authors
# -------
#
# Author Name <author@domain.com>
#
# Copyright
# ---------
#
# Copyright 2020 Your name here, unless otherwise noted.
#
class locust {

  package { 'python3-pip':
    ensure   => 'installed',
  } 

  package { 'locust':
    ensure   => 'installed',
    provider => 'pip3',
  }

  user { 'locust':
    ensure => 'present',
    managehome => 'true',
  }

  file { '/home/locust/locustfile.py':
    ensure => 'present',
    source => 'puppet:///modules/locust/locustfile.py',
    notify => Service['locust']
  }

  file { '/etc/systemd/system/locust.service':
    ensure => 'present',
    source => 'puppet:///modules/locust/locust.service',
  }

  service { "locust":
    ensure => "running",
    enable => "true",
  }

}
