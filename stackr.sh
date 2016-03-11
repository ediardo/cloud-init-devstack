#!/bin/bash

# Originally developed by Szymon Wróblewski and extended by Eddie Ramirez.
readonly script_version=0.2

# Linux user
user=
# Your gerrit username
gerrit_username=
# Your email address 
gerrit_email=
# Your FUll Name
gerrit_fullname=
# Install Devstack 
with_devstack=1
# Devstack Installation Path
devstack_path=/opt/devstack

function print_version(){
  echo "stackr.sh version is ${script_version}"
}

function usage(){
  echo "Usage: $0 [OPTIONS]"
  echo ""
  echo "--user=user"
  echo "--gerrit-username=username"
  echo "--gerrit-email=email"
  echo "--with-devstack"
  echo "--devstack-path=path"
  echo ""
}

function conf_access(){
  echo '===[ Configuring access ] =================================='
  adduser --disabled-password --gecos "" $user
  cp -r /home/ubuntu/.ssh /home/$user/
  chown -R $user /home/$user/.ssh
  echo "$user ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
# uncomment the lines below only IF YOU WANT TO CHANGE DEFAULT SSHD PORT
#  sed -i "s/Port 22/Port $ssh_port\nAllowUsers $user/" /etc/ssh/sshd_config
#  service ssh restart
}

function conf_pkgs(){
  echo '===[ Configuring packages ] ================================'
  apt-get update
  apt-get upgrade
  apt-get install python-software-properties
  apt-add-repository -y ppa:fish-shell/release-2
  add-apt-repository -y ppa:webupd8team/java
  apt-get update
  cat <<EOF | debconf-set-selections
  debconf shared/accepted-oracle-license-v1-1 select true
  debconf shared/accepted-oracle-license-v1-1 seen true
EOF
}

function conf_gerrit(){
  apt-get install -y git git-review
  echo '===[ Configuring gerrit ] =================================='
  su $user <<EOSU
  git config --global user.name $gerrit_fullname
  git config --global user.email $gerrit_email
  git config --global gitreview.username $gerrit_username
   
  ssh-keygen -t rsa -N '' -f /home/$user/.ssh/id_rsa_gerrit
  cat <<EOF >> /home/$user/.ssh/config
Host gerrit review.openstack.org
  HostName review.openstack.org
  IdentityFile ~/.ssh/id_rsa_gerrit
  User $gerrit_username
EOF
EOSU
}

function conf_devstack(){
  echo '===[ Configuring devstack ] ================================'
  adduser --disabled-password --gecos "" stack
  echo "stack ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
  git clone https://git.openstack.org/openstack-dev/devstack $devstack_path
  cat <<EOF >> $devstack_path/local.conf
  [[local|localrc]]
  FLOATING_RANGE=192.168.1.224/27
  FIXED_RANGE=10.11.12.0/24
  FIXED_NETWORK_SIZE=256
  FLAT_INTERFACE=eth0
  ADMIN_PASSWORD=secrete
  DATABASE_PASSWORD=secrete
  RABBIT_PASSWORD=secrete
  SERVICE_PASSWORD=secrete

  # Do not use Nova-Network
  disable_service n-net
  # Enable Neutron
  ENABLED_SERVICES+=,q-svc,q-dhcp,q-meta,q-agt,q-l3

EOF
  chmod -R 777 $devstack_path
  su - stack -c "$devstack_path/stack.sh"
  echo '===[ END ] ================================================='
}

args=`getopt -o v::,h:: --long with-devstack,user:,gerrit-username:,gerrit-email:,gerrit-fullname:,devstack-path: -n 'stackr.sh' -- "$@"`
eval set -- "$args"
while true ; do
  case "$1" in
    --user)
      case "$2" in
        "") shift 2 ;;
        *)  user=$2 ; shift 2 ;;
      esac ;;
    --gerrit-username)
      case "$2" in
        "") echo $2; shift 2;;
        *)  gerrit_username=$2 ; shift 2 ;;
      esac ;;
    --gerrit-email)
      case "$2" in
        "") shift 2;;
        *)  gerrit_email=$2 ; shift 2 ;;
      esac ;;
    --gerrit-fullname)
      case "$2" in
        "") shift 2;;
        *)  gerrit_fullname=$2 ; shift 2 ;;
      esac ;;
    --devstack-path)
      case "$2" in
        "") shift 2;;
        *)  devstack_path=$2 ; shift 2 ;;
      esac ;;
    --with-devstack)
      case "$2" in
        *) use_rsync=1; shift ;;
      esac ;;
    -v)
      print_version ;;
    -h)
      usage ;;

    --) shift ; break ;;
    *) echo "error" ; exit 1 ;;
  esac
done

errors=0

if [ -z "${user}" ] ;  then
  echo "Set the --user or user variable"
  errors=$((errors + 1))
fi
if [ -z "${gerrit_username}" ] ;  then
  echo "Set the --gerrit-username or gerrit_username variable"
  errors=$((errors + 1))
fi
if [ -z "${gerrit_email}" ] ;  then
  echo "Set the --gerrit-email or gerrit_email variable"
  errors=$((errors + 1))
fi
if [ -z "${gerrit_fullname}" ] ;  then
  echo "Set the --gerrit-fullname or gerrit_fullname variable"
  errors=$((errors + 1))
fi
if [ -z "${devstack_path}" ] ;  then
  echo "Set the --devstack-path or devstack_path variable"
  errors=$((errors + 1))
fi

if [ "${errors}" -gt 0 ] ; then
  exit ${exit_code}
fi

conf_access
conf_pkgs
conf_gerrit

if [ "${with_devstack}" -eq 1 ] ; then
  conf_devstack
fi
