#
# Cookbook:: .
# Recipe:: master
#
# Copyright:: 2017, The Authors, All Rights Reserved.
include_recipe 'kubeadm::common'

# Search the master server to assign the API IP address
master = search(:node, 'run_list:*kubeadm??master*')
node.normal['kubeadm']['api_ip_address'] = master[0]['ipaddress']

myIp = master[0]['ipaddress']
# This is the node IP address
node_ip = node['network']['interfaces'][node['kubeadm']['flannel_iface']]['addresses'].keys[1]
port = '6443'

directory '/etc/kubernetes/manifests/' do
  owner 'root'
  group 'root'
  mode '0755'
  action :create
end



execute 'kubeadm config pull' do
  command <<-EOF
    kubeadm config images pull
  EOF
  action :run
  not_if "grep 'https://#{node['kubeadm']['api_ip_address']}' /etc/kubernetes/kubelet.conf"
  # not_if "curl -k --max-time 10 https://#{node['kubeadm']['api_ip_address']}:6443/healthz | grep ^ok"
end

execute 'kubeadm init' do
  command <<-EOF
    kubeadm init \
    --token=#{node['kubeadm']['token']} \
    --pod-network-cidr=#{node['kubeadm']['pod_cidr']} \
    --service-cidr=#{node['kubeadm']['service_cidr']} \
    --service-dns-domain=#{node['kubeadm']['dns_domain']} \
    --apiserver-advertise-address=#{node['kubeadm']['api_ip_address']}
    --experimental-upload-certs
  EOF
  action :run
  not_if "grep 'https://#{node['kubeadm']['api_ip_address']}' /etc/kubernetes/kubelet.conf"
  # not_if "curl -k --max-time 10 https://#{node['kubeadm']['api_ip_address']}:6443/healthz | grep ^ok"
end





# Initialize master
#
#

#Extra args for kubernetes go here.
template '/etc/default/kubelet' do
  source 'kubelet.erb'
  owner 'root'
  group 'root'
  mode '0755'
  variables({
                :nodeIp => node_ip

            })
end

# Kube config for root
# todo: make this run with 'kubernetes user'
execute 'kube config' do
  command <<-EOF
  mkdir -p /root/.kube
  sudo cp -i /etc/kubernetes/admin.conf /root/.kube/config
  sudo chown $(id -u):$(id -g) /root/.kube/config
  EOF
  not_if 'test -f /root/.kube/config'
end

execute 'kube config for vagrant user' do
  command <<-EOF
  mkdir -p /home/vagrant/.kube
  sudo cp -i /etc/kubernetes/admin.conf /home/vagrant/.kube/config
  sudo chown vagrant:vagrant /home/vagrant.kube/config
  EOF
  not_if 'test -f $HOME/.kube/config'
end


# https://raw.githubusercontent.com/coreos/flannel/v0.9.0/Documentation/kube-flannel.yml
template '/tmp/kube-flannel.yml' do
  source 'kube-flannel.yml.erb'
  owner 'root'
  group 'root'
  mode '0644'
end


# flannel pod network
#

execute 'kubectl flannel' do
  command <<-EOF
  kubectl apply -f /tmp/kube-flannel.yml
  EOF
  action :run
  not_if 'kubectl get pods -n kube-system | grep flannel | grep Running'
  notifies :restart, 'service[docker restart]', :immediately
end


#execute 'create flannelApplied' do
#  command 'touch /tmp/flannelApplied'
#  action :nothing
# end


execute 'delay for flannel networking to start.' do
  command 'sleep 30'
  action :nothing
end


# systemd daemon reload after kubelet config file changed
execute 'systemd daemon reload' do
  command 'systemctl daemon-reload'
  action :nothing
  notifies :restart, 'service[restart kubelet]', :immediately
end

# restart kubelet
service 'restart kubelet' do
  service_name 'kubelet'
  supports status: true
  action [:nothing]
end




# single node cluster is true
if node['kubeadm']['single_node_cluster'] == true
  script 'allow pods in master' do
    user 'root'
    interpreter 'bash'
    command 'kubectl taint nodes --all node-role.kubernetes.io/master-'
    action :run
    retries 10
    not_if 'kubectl describe nodes | grep "Taints" | grep "<none>"'
  end
end

# restart docker
service 'docker restart' do
  service_name 'docker'
  supports status: true
  action :nothing
  # notifies :run, 'execute[delay]', :immediately
end

# # delay recipe after docker restart
# Chef::Log.info('Delaying recipe execution')
# execute 'delay' do
#   command 'sleep 15'
#   action :nothing
# end
