# Disable swap
# disable firewalld
#
apt_package 'apt-transport-https' do
  :install
end
package  'ca-certificates' do
  :install
end
apt_package  'curl' do
  :install
end
apt_package 'software-properties-common' do
  :install
end

service 'firewalld' do
  supports status: true
  action [:disable, :stop]
end



apt_repository 'docker' do
  uri        "https://download.docker.com/linux/ubuntu/"
  distribution "bionic stable"
  key "https://download.docker.com/linux/ubuntu/gpg"
end

apt_package 'wget' do
  action :install
end
#execute 'selinux' do
#  command 'setenforce 0'
#  action :run
#  not_if 'getenforce | grep Permissive'
#end

apt_package 'docker-ce' do
  :install
end
#TODO: move this to a file and use chef to create it.
#script 'setup docker service to use systemd' do
#  interpreter 'bash'
#  code <<-EOH
#     cat > /etc/docker/daemon.json <<EOF
#      {
#        "exec-opts": ["native.cgroupdriver=systemd"],
#        "log-driver": "json-file",
#        "log-opts": {
#          "max-size": "100m"
#        },
#        "storage-driver": "overlay2"
#      }
#     EOF
#     mkdir -p /etc/systemd/system/docker.service.d
#     # Restart docker.
#     systemctl daemon-reload
#     systemctl restart docker
#   EOH
#  action :run
#  not_if {::File.exist?('/etc/systemd/system/docker.service.d')}
#end


execute 'docker memory accounting' do
  command 'systemctl set-property docker.service MemoryAccounting=yes'
  action :run
  not_if 'systemctl show docker.service | grep MemoryAccounting=yes'
end

# Enable docker CPU accounting
execute 'docker memory accounting' do
  command 'systemctl set-property docker.service CPUAccounting=yes'
  action :run
  not_if 'systemctl show docker.service | grep CPUAccounting=yes'
end

apt_repository 'kubernetes' do
  uri        'https://apt.kubernetes.io/'
  distribution "kubernetes-xenial"
  components ['main']
  key "https://packages.cloud.google.com/apt/doc/apt-key.gpg"

end

execute 'disable swap' do
  command 'swapoff -a'
  action :run
  not_if 'swapon -s | wc -l | grep 0'
end



apt_package 'kubeadm' do
  action :install
end
apt_package 'kubectl' do
  action :install
end
apt_package 'kubernetes-cni' do
  action :install
end

service 'start kubelet' do
  service_name 'kubelet'
  action [:enable, :start]
end

execute 'kernel bridged traffic' do
  command <<-EOF
    echo 'net.bridge.bridge-nf-call-iptables=1' >> /etc/sysctl.conf
    echo 'net.bridge.bridge-nf-call-ip6tables=1' >> /etc/sysctl.conf
    sysctl -p
  EOF
  action :run
  not_if 'sysctl -n net.bridge.bridge-nf-call-iptables | grep 1'
end


