#!/bin/bash

cd /root/shared
source configure.sh
cd setup

# 1. Install OpenStack Compute Service and dependencies
yum install -y yum-plugin-priorities
yum install -y http://rdo.fedorapeople.org/openstack-kilo/rdo-release-kilo.rpm
yum install -y http://dl.fedoraproject.org/pub/epel/7/x86_64/e/epel-release-7-5.noarch.rpm
yum install -y openstack-selinux deltarpm
yum upgrade -y
yum clean all
yum update -y
yum install -y openstack-nova-compute sysfsutils

# 2. Configure message broker service
crudini --set /etc/nova/nova.conf DEFAULT rpc_backend rabbit
crudini --set /etc/nova/nova.conf DEFAULT rabbit_host message-broker
crudini --set /etc/nova/nova.conf DEFAULT rabbit_password secure

# 3. Configure VNC Server
crudini --set /etc/nova/nova.conf DEFAULT vnc_enabled True
crudini --set /etc/nova/nova.conf DEFAULT vncserver_listen 127.0.0.1
crudini --set /etc/nova/nova.conf DEFAULT vncserver_proxyclient_address 127.0.0.1
crudini --set /etc/nova/nova.conf DEFAULT novncproxy_base_url http://compute-controller:6080/vnc_auto.html

crudini --set /etc/nova/nova.conf DEFAULT my_ip ${my_ip}

# 4. Configure Identity Service
crudini --set /etc/nova/nova.conf DEFAULT auth_strategy keystone
crudini --set /etc/nova/nova.conf keystone_authtoken auth_uri http://identity:5000/v2.0
crudini --set /etc/nova/nova.conf keystone_authtoken identity_uri http://identity:35357
crudini --set /etc/nova/nova.conf keystone_authtoken admin_tenant_name service
crudini --set /etc/nova/nova.conf keystone_authtoken admin_user nova
crudini --set /etc/nova/nova.conf keystone_authtoken admin_password secure

# 5. Configure Image Service
crudini --set /etc/nova/nova.conf glance host image

# 6. Use KVM or QEMU
supports_hardware_acceleration=`egrep -c '(vmx|svm)' /proc/cpuinfo`
if [ $supports_hardware_acceleration -eq 0 ]; then
  crudini --set /etc/nova/nova.conf libvirt virt_type qemu
fi

# 7. Restart services
systemctl enable libvirtd.service openstack-nova-compute.service
systemctl start libvirtd.service
systemctl start openstack-nova-compute.service
