# Ensure we are on UTC
file { "/etc/localtime" :
    ensure => "/usr/local/zoneinfo/UTC"
}

# Run apt-get update when anything beneath /etc/apt/ changes
exec { "apt-get update" :
    command => "/usr/bin/apt-get update --fix-missing",
}

include apache
include php
include mysql

$docroot    = '/vagrant/www/'
$publicroot = "${docroot}public/"

# httpd setup
class {'apache::mod::php': }

apache::vhost { 'orchestra.dev' :
    priority           => 20,
    port               => 80,
    docroot            => $publicroot,
    configure_firewall => false,
    override           => ['All'],
}

a2mod { 'rewrite': ensure => present; }

# PHP Extensions
php::module { ['xdebug', 'mysql', 'curl', 'gd', 'mcrypt'] :
    notify => [ Service['httpd'], ],
}

# MySQL Server
class { 'mysql::server':
    config_hash => { 'root_password' => 'root' }
}

mysql::db { 'orchestra' :
    user     => 'orchestra',
    password => 'orchestra',
    host     => 'localhost',
    grant    => ['all'],
    charset  => 'utf8',
}

# Other Packages
$extras = ['vim', 'curl', 'phpunit']
package { $extras : ensure => 'installed' }

# Ibu.my Setup
file { $docroot:
    ensure  => 'directory',
}

file { "${docroot}storage/views/" : 
    ensure  => 'directory',
    force   => true,
    recurse => true,
    purge   => true,
}

$writeable_dirs = ["${docroot}storage/", "${publicroot}bundles/"]

file { $writeable_dirs:
    ensure  => 'directory',
    mode    => '0777',
    recurse => true,
    require => File[$docroot],
}