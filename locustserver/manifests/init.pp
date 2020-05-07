class locustserver {

  package { 'python3-pip':
    ensure   => 'installed',
  } 

  package { 'nginx':
    ensure   => 'installed',
  } 

  file { '/etc/ssl/certs/dhparam.pem':
    ensure => 'present',
    source => 'puppet:///modules/locustserver/dhparam.pem', 
  }

  file { '/etc/ssl/certs/nginx-selfsigned.crt':
    ensure => 'present',
    source => 'puppet:///modules/locustserver/nginx-selfsigned.crt', 
  }

  file { '/etc/ssl/private/nginx-selfsigned.key':
    ensure => 'present',
    source => 'puppet:///modules/locustserver/nginx-selfsigned.key', 
  }

  file { '/etc/nginx/sites-enabled/default':
    ensure => 'present',
    source => 'puppet:///modules/locustserver/default', 
    notify => Service["nginx"]
  }

  file { '/etc/nginx/htpasswd':
    ensure => 'present',
    source => 'puppet:///modules/locustserver/htpasswd', 
  }

  package { 'locust':
    ensure   => 'installed',
    provider => 'pip3',
  }

  user { 'locust':
    ensure => 'present',
    managehome => 'true',
  }

  service { "nginx":
    ensure => "running",
    enable => "true",
  }

  file { '/etc/systemd/system/locustserver.service':
    ensure => 'present',
    source => 'puppet:///modules/locustserver/locustserver.service', 
  }

  file { '/home/locust/locustfile.py':
    ensure => 'present',
    source => 'puppet:///modules/locustserver/locustfile.py', 
  }

  service { "locustserver":
    ensure => "running",
    enable => "true",
  }

}
