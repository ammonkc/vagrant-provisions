#!/usr/bin/env bash

# xterm colors
if [[ $COLORTERM = gnome-* && $TERM = xterm ]] && infocmp gnome-256color >/dev/null 2>&1; then
    export TERM=gnome-256color
elif infocmp xterm-256color >/dev/null 2>&1; then
    export TERM=xterm-256color
fi

# Notice title
notice() { printf  "\033[1;32m=> $1\033[0m \n"; }
# Error title
error() { printf "\033[1;31m=> Error: $1\033[0m \n"; }
# List item
c_list() { printf  "  \033[1;32m✔\033[0m $1 \n"; }
# Error list item
e_list() { printf  "  \033[1;31m✖\033[0m $1 \n"; }

if [ "$EUID" -ne "0" ] ; then
    error "Script must be run as root." >&2
    exit 1
fi

install_puppet() {
    notice "Installing Puppet repo for CentOS-6.5-x86_64"
    wget -qO /tmp/puppetlabs-release-6-7.noarch.rpm \
    http://yum.puppetlabs.com/el/6/products/x86_64/puppetlabs-release-6-7.noarch.rpm

    rpm -ivh /tmp/puppetlabs-release-6-7.noarch.rpm
    rm /tmp/puppetlabs-release-6-7.noarch.rpm
    yum update -y
    notice "Installing puppet"
    yum install -y puppet facter
    notice "Puppet installed!"

    if hash git 2> /dev/null ; then
        notice "git is installed"
    else
        install_git
    fi
}

install_git() {
    notice "Installing git"
    yum install -y git
    notice "git installed!"
    return 1
}

install_puppet_modules() {
    notice "*************************"
    notice "**      Bootstrap      **"
    notice "*************************"
    notice "Install puppet modules"
    pmod_path="/etc/puppet/modules"
    vpmod_path="/tmp/vagrant-puppet-1/modules-0"
    puppet_bin="/usr/bin/puppet"
    git_bin="/usr/bin/git"
    pmods=( $(ls $pmod_path) )
    if [ -d $vpmod_path ]; then
        vpmods=( $(ls $vpmod_path) )
        for index in "${!pmod_deps[@]}"; do
            not_in_array ${pmod_deps[$index]} "${vpmods[@]}"
            missing_vpmod=$?
            if [ $missing_vpmod -gt 0 ]; then
                not_in_array ${pmod_deps[$index]} "${pmods[@]}"
                should_install=$?
                if [ $should_install -gt 0 ]; then
                    e_list "${pmod_deps[$index]} ==> ${mod_repos[$index]}"
                    if [ "${pmod_deps[$index]%%-*}" == "ammonkc" ]; then
                        $git_bin clone ${mod_repos[$index]} "${pmod_path}/${pmod_deps[$index]##*-}"
                    else
                        $puppet_bin module install ${pmod_deps[$index]} --modulepath ${pmod_path}
                    fi
                else
                    c_list "${pmod_deps[$index]} ==> ${pmod_path}"
                fi
            else
                c_list "${pmod_deps[$index]} ==> ${vpmod_path}"
            fi
        done
    else
        for index in "${!pmod_deps[@]}"; do
            not_in_array ${pmod_deps[$index]} "${pmods[@]}"
            should_install=$?
            if [ $should_install -gt 0 ]; then
                e_list "${pmod_deps[$index]} ==> ${mod_repos[$index]}"
                if [ "${pmod_deps[$index]%%-*}" == "ammonkc" ]; then
                    $git_bin clone ${mod_repos[$index]} "${pmod_path}/${pmod_deps[$index]##*-}"
                else
                    $puppet_bin module install ${pmod_deps[$index]} --modulepath ${pmod_path}
                fi
            else
                c_list "${pmod_deps[$index]} ==> ${pmod_path}"
            fi
        done
    fi
}

not_in_array() {
  local needle=$1
  local hay=$2
  shift
  for hay; do
    [[ $hay == ${needle##*-} ]] && return 0
  done
  return 1
}

#-----------------------------------------------------------------------------
# Array data
#-----------------------------------------------------------------------------

pmod_deps=(             \
    ammonkc-repo        \
    ammonkc-pkg         \
    ammonkc-server      \
    example42-apache    \
    puppetlabs-mysql    \
    puppetlabs-firewall \
    example42-php       \
    maestrodev-wget     \
)
mod_repos=(                                                 \
    https://github.com/ammonkc/puppet-repo.git              \
    https://github.com/ammonkc/puppet-pkg.git               \
    https://github.com/ammonkc/puppet-server.git            \
    https://github.com/example42/puppet-apache.git          \
    https://github.com/puppetlabs/puppetlabs-mysql.git      \
    https://github.com/puppetlabs/puppetlabs-firewall.git   \
    https://github.com/example42/puppet-php.git             \
    https://github.com/maestrodev/puppet-wget.git           \
)
#-----------------------------------------------------------------------------
# Initialize
#-----------------------------------------------------------------------------

if hash puppet 2> /dev/null ; then
    notice "Puppet is installed"
else
    install_puppet
fi

install_puppet_modules
