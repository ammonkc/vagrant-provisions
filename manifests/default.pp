#------------------------------------------
# Vagrant Dev VM
#------------------------------------------
# - Base set up
# - Epel repo
# - basic utility packages
#
#------------------------------------------

# Set the default $PATH$ for executing commands on node systems.
Exec { path => "/usr/bin:/usr/sbin:/bin:/sbin:/usr/local/bin:" }

# Run Stages
stage { 'pre':  before  => Stage['main'] }
stage { 'post': require => Stage['main'] }

# Default node
node default {
    file { 'motd':
        ensure  => file,
        path    => '/etc/motd',
        mode    => 0644,
        content => "
        *****************************
        **     Vagrant Dev VM      **
        *****************************
            - Version:  0.0.7
            - OS:       CentOS-6.5_x86_64
            - Box:      CentOS-6.5
            - Hostname: ${fqdn}
            - IP:       ${ipaddress_eth1}
            - User:     vagrant@${fqdn}
            - Password: vagrant
            - Code:     /vagrant
\n"
    }
}

# register run stages
class { 'repo::epel': stage => pre; }

#------------------------------------------
# Utils
#------------------------------------------
if $utils == 'true' {
    info("Installing Utilities")
    include pkg::utils
}

#------------------------------------------
# dotfiles
#------------------------------------------
if $dotfiles == 'true' {
    if $utils != 'true' {
        info("Installing dotfiles dependencies")
        pkg::install { [ 'git', 'tree', 'vim-enhanced', 'zsh', 'bc' ]:
            stage => pre
        }
    }
    exec { "dotfiles":
        command => "bash < <( curl https://raw.github.com/ammonkc/dotfiles/linux/bootstrap.sh )",
        path    => "/bin/",
    }
}

#------------------------------------------
# LAMP stack - Apache/MySQL/PHP
#------------------------------------------
if $puppet_node =~ /^lamp.([0-9a-zA-Z]*-?[0-9a-zA-Z]*)([0-9a-zA-Z]*_?[0-9a-zA-Z]*)\.vagrant.dev$/ {
    include server::lamp
}

#------------------------------------------
# LEMP stack - Nginx/MySQL/PHP
#------------------------------------------
if $puppet_node =~ /^lemp.([0-9a-zA-Z]*-?[0-9a-zA-Z]*)([0-9a-zA-Z]*_?[0-9a-zA-Z]*)\.vagrant.dev$/ {
    include server::lemp
}

#------------------------------------------
# Node.js
#------------------------------------------
if $nodejs == 'true' {
    include node-js
}
