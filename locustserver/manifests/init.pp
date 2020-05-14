class locustserver {

  include locust

  package { 'nginx':
    ensure   => 'installed',
  } 

  file { '/etc/ssl/certs/dhparam.pem':
    ensure => 'present',
    source => 'puppet:///modules/locustserver/dhparam.pem', 
  }

  file { '/etc/ssl/certs/nginx.crt':
    ensure => 'present',
    source => 'puppet:///modules/locustserver/nginx.crt', 
  }

  file { '/etc/ssl/private/nginx.key':
    ensure => 'present',
    source => 'puppet:///modules/locustserver/nginx.key', 
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
