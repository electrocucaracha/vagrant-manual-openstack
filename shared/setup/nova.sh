#!/bin/bash

# Source the admin credentials to gain access
source /root/admin-openrc.sh

# Create the nova user
openstack user create nova --password=${NOVA_PASS} --email=nova@example.com

# Add the admin role to the nova user
openstack role add admin --user=nova --project=service

# Create the nova service entity
openstack service create --name nova \
  --description "OpenStack Compute" compute

# Create the Compute service API endpoints
openstack endpoint create --region RegionOne \
  compute public http://${COMPUTE_CONTROLLER_HOSTNAME}:8774/v2/%\(tenant_id\)s
openstack endpoint create --region RegionOne \
  compute internal http://${COMPUTE_CONTROLLER_HOSTNAME}:8774/v2/%\(tenant_id\)s
openstack endpoint create --region RegionOne \
  compute admin http://${COMPUTE_CONTROLLER_HOSTNAME}:8774/v2/%\(tenant_id\)s

# Configure database access
crudini --set /etc/nova/nova.conf database connection mysql+pymysql://nova:${NOVA_DBPASS}@${DATABASE_HOSTNAME}/nova

# Configure RabbitMQ message queue access
crudini --set /etc/nova/nova.conf DEFAULT rpc_backend rabbit
crudini --set /etc/nova/nova.conf oslo_messaging_rabbit rabbit_host ${MESSAGE_BROKER_HOSTNAME}
crudini --set /etc/nova/nova.conf oslo_messaging_rabbit rabbit_userid openstack
crudini --set /etc/nova/nova.conf oslo_messaging_rabbit rabbit_password ${RABBIT_PASS}

# Configure Identity service access
crudini --set /etc/nova/nova.conf DEFAULT auth_strategy keystone
crudini --set /etc/nova/nova.conf keystone_authtoken auth_uri http://${IDENTITY_HOSTNAME}:5000
crudini --set /etc/nova/nova.conf keystone_authtoken auth_url http://${IDENTITY_HOSTNAME}:35357
crudini --set /etc/nova/nova.conf keystone_authtoken auth_plugin password
crudini --set /etc/nova/nova.conf keystone_authtoken project_domain_id default
crudini --set /etc/nova/nova.conf keystone_authtoken user_domain_id default
crudini --set /etc/nova/nova.conf keystone_authtoken project_name service
crudini --set /etc/nova/nova.conf keystone_authtoken username nova
crudini --set /etc/nova/nova.conf keystone_authtoken password ${NOVA_PASS}

# Configure the my_ip option to use the management interface IP address of the controller node
crudini --set /etc/nova/nova.conf DEFAULT my_ip ${my_ip}

# Enable support for the Networking service
crudini --set /etc/nova/nova.conf DEFAULT network_api_class nova.network.neutronv2.api.API
crudini --set /etc/nova/nova.conf DEFAULT security_group_api neutron
crudini --set /etc/nova/nova.conf DEFAULT linuxnet_interface_driver nova.network.linux_net.NeutronLinuxBridgeInterfaceDriver
crudini --set /etc/nova/nova.conf DEFAULT firewall_driver nova.virt.firewall.NoopFirewallDriver

# Configure the VNC proxy to use the management interface IP address of the controller node
crudini --set /etc/nova/nova.conf vnc vncserver_listen ${my_ip}
crudini --set /etc/nova/nova.conf vnc vncserver_proxyclient_address ${my_ip}

# Configure the location of the Image service
crudini --set /etc/nova/nova.conf glance host ${IMAGE_HOSTNAME}

# Configure the lock path
crudini --set /etc/nova/nova.conf oslo_concurrency lock_path /var/lib/nova/tmp

# Disable the EC2 API
crudini --set /etc/nova/nova.conf DEFAULT enabled_apis osapi_compute,metadata

# Populate the Compute database
su -s /bin/sh -c "nova-manage db sync" nova
