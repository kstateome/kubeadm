#
# Cookbook:: .
# Recipe:: heapster
#
# Copyright:: 2017, The Authors, All Rights Reserved.

execute 'install helm and add coreos repo and install prometheous/grafana/ es.' do
  command <<-EOF
    sudo snap install helm --classic
    helm init
    helm repo add coreos https://s3-eu-west-1.amazonaws.com/coreos-charts/stable/
    helm repo update
    #setup account for tiller to use.
    #wait for tiller pod to be created
    kubectl create serviceaccount --namespace kube-system tiller
    kubectl create clusterrolebinding tiller-cluster-rule --clusterrole=cluster-admin --serviceaccount=kube-system:tiller
    kubectl patch deploy --namespace kube-system tiller-deploy -p '{"spec":{"template":{"spec":{"serviceAccount":"tiller"}}}}'
    
    #install prometheous/graphana.
    helm install coreos/prometheus-operator --namespace monitoring
    helm install coreos/kube-prometheus --name kube-prometheus --set global.rbacEnable=true --namespace monitoring
  EOF
  action :run
  not_if /home/vagrant/.helm
end
