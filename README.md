# kubeadm Cookbook

Chef cookbook to create a Kubernetes infrastructure using kubeadm tool:
* Single node cluster.
* Multi node cluster.

Based in the official documents:
https://kubernetes.io/docs/setup/independent/create-cluster-kubeadm/

## To run in dev environment

You will need chefdk installed.

```
chef gem install kitchen-nodes
kitchen converge
kitchen login master
```

## Requirements
### Cookbooks
none
### Platforms
The following platforms are supported and tested with Test Kitchen:

- Ubuntu 18.04+

### Chef
- Chef 12.1+

## Attributes
* default['kubeadm']['token'] = 'odp6v2.n9wtntgl7lnaz23s'
* default['kubeadm']['pod_cidr'] = '10.244.0.0/16'
* default['kubeadm']['service_cidr'] = '10.96.0.0/12'
* default['kubeadm']['dns_domain'] = 'cluster.local'
* default['kubeadm']['single_node_cluster'] = false
* default['kubeadm']['flannel_iface'] = 'eth1'
* default['kubeadm']['version'] = '1.8.3-0'
* default['kubeadm']['dashboard_commit_hash7'] = '28527b0'
* default['kubeadm']['heapster_commit_hash7'] = '9f415d0'

## Kubernetes Components
### Master
- kubelet
- kube-controller-manager (container)
- kube-scheduler (container)
- kube-apiserver (container)
- etcd (container)
- kube-dns (container)
- kube-proxy (container)
- kube-flannel (container)
- docker

This will not setup a multi-node master, and should not be used in OME's production environment at this time.

Use the runlist: recipe[kubeadm::master], recipe[kubeadm::dashboard], recipe[kubeadm::heapster]

### Nodes
- kube-flannel (container)
- kube-proxy (container)
- docker

Use the runlist: recipe[kubeadm::node]

### Add-ons
- dashboard, use recipe[kubeadm::dashboard]
- heapster/influxdb/grafana, use recipe[kubeadm::heapster]

## Test using Chef Kitchen with Vagrant and Virtualbox
The file .kitchen.yml is provided with the next servers:
* One master node
* Two worker nodes

## Access the dashboard
- Find the secret name for kubernetes-dashboard
```
$ kubectl -n kube-system get secret | grep kubernetes-dashboard-token
```
- Get the token needed to login to dashboard. 7bwww is a string found using the previous command.
```
$ kubectl -n kube-system describe secret kubernetes-dashboard-token-7bwww
```
- Use kubectl command to create a proxy
```
$ kubectl proxy
```
- Access dashboard using a local browser
http://localhost:8001/api/v1/namespaces/kube-system/services/https:kubernetes-dashboard:/proxy/

While using Vagrant, is recommended that you install Landrush plugin to create a local DNS server, and avoid having to do a manual configuration of the file /etc/hosts in each server. Check https://github.com/vagrant-landrush/landrush

## Chef Kitchen Integration Tests

### Multi-node testing
Be sure to have the next gem installed: kitchen-nodes. You can do the manual installation using:
```
$ chef exec gem install kitchen-nodes
```
### For Vagrant tests using Kitchen
- Add a private network with static IP. See .kitchen.yml file for an example.
