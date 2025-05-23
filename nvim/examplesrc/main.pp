# Puppet manifest for testing language support

# Variables and facts
$app_name = 'example-app'
$app_user = 'appuser'
$app_home = "/opt/${app_name}"

# Facts-based conditionals
$is_redhat = $facts['os']['family'] == 'RedHat'
$is_debian = $facts['os']['family'] == 'Debian'

# Hiera lookup with default
$app_port = lookup('app_port', Integer, 'first', 8080)
$app_env = lookup('app_environment', String, 'first', 'production')

notify { "System Info":
  message => "Running ${facts['os']['name']} with ${facts['processors']['count']} CPUs",
}

# Custom defined type
define app_config_file (
  String $content,
  String $owner = $app_user,
  String $mode = '0644',
) {
  file { $title:
    ensure  => file,
    owner   => $owner,
    mode    => $mode,
    content => $content,
    require => User[$owner],
  }
}

# Class with parameters
class base_system (
  Boolean $manage_firewall = true,
  Array[String] $packages = ['curl', 'wget', 'git'],
) {
  
  # Install packages
  package { $packages:
    ensure => installed,
  }

  # Conditional firewall management
  if $manage_firewall and !$facts['os']['family'] == 'windows' {
    case $facts['os']['family'] {
      'RedHat': {
        service { 'firewalld':
          ensure => running,
          enable => true,
        }
      }
      'Debian': {
        package { 'ufw':
          ensure => installed,
        }
      }
      default: {
        notify { 'Firewall not configured':
          message => "Unsupported OS family: ${facts['os']['family']}",
        }
      }
    }
  }
}

# Application class
class application (
  String $user = $app_user,
  String $home_dir = $app_home,
  Integer $port = $app_port,
  String $environment = $app_env,
) {
  
  # Create user
  user { $user:
    ensure     => present,
    home       => $home_dir,
    shell      => '/bin/bash',
    managehome => true,
  }

  # Create directories
  $directories = [$home_dir, "${home_dir}/config", "${home_dir}/logs"]

  file { $directories:
    ensure  => directory,
    owner   => $user,
    mode    => '0755',
    require => User[$user],
  }

  # Configuration file using defined type
  app_config_file { "${home_dir}/config/app.conf":
    content => "port=${port}\nenvironment=${environment}\n",
  }

  # Service
  service { $app_name:
    ensure  => running,
    enable  => true,
    require => [User[$user], File[$directories]],
  }
}

# Custom function
function validate_port(Integer $port) >> Boolean {
  if $port < 1024 or $port > 65535 {
    fail("Invalid port: ${port}")
  }
  true
}

# Resource collector
File <| owner == $app_user |> {
  require => User[$app_user],
}

# Virtual resources
@package { 'htop':
  ensure => installed,
  tag    => 'monitoring',
}

@package { 'tcpdump':
  ensure => installed,
  tag    => 'network',
}

# Realize based on facts
if $facts['role'] == 'monitoring' {
  Package <| tag == 'monitoring' |>
}

# Node classification
node default {
  include base_system
  include application
  
  # Conditional include
  if $facts['environment'] == 'production' {
    class { 'monitoring':
      enable => true,
    }
  }
} 