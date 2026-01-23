#This script is required if the default host machine resolv conf
#Happens to include a domain that has the same ndots as the internal
#Kubernetes routing domain (<svc>.<ns>.svc.cluster.local & <prefix>.osc.eonerc.rwth-aachen.de) 
#Run for simplicity anyway

#Maybe take this value from /var/run/systemd/resolve/resolv.conf
#Which on ubuntu will contain at least one correct entry for a nameserver
# ( cat /var/run/systemd/resolve/resolv.conf | grep nameserver | grep -v '192\.\d{1,3}\.\d{1,3}\.\d{1,3}\.' to avoid dhcp dns)
NAMESERVER="134.130.48.18"

KUBECONFIG="/home/$USER/.kube/config"

echo "nameserver $NAMESERVER" | sudo tee /etc/k3s-resolv.conf
# append kubelet arg
echo 'kubelet-arg:' | sudo tee -a /etc/rancher/k3s/config.yaml
echo '- "resolv-conf=/etc/k3s-resolv.conf"' | sudo tee -a /etc/rancher/k3s/config.yaml

# check values
sudo cat /etc/rancher/k3s/config.yaml

# restart cluster 

# enable CoreDNS logging if not found
kubectl get cm -n kube-system coredns -o=json | grep -q log | kubectl get cm -n kube-system coredns -o=json | jq 'del(.metadata.resourceVersion,.metadata.uid,.metadata.selfLink,.metadata.creationTimestamp,.metadata.annotations,.metadata.generation,.metadata.ownerReferences,.status)' | sed 's#\.:53 {#\.:53 {\\n    log#' | kubectl replace -f -

# restart all CoreDNS pods
kubectl get pod -n kube-system -l k8s-app=kube-dns --no-headers | awk '{print $1}' | xargs -I{} kubectl delete pod -n kube-system {}

# wait to be available again
kubectl wait deployment -n kube-system coredns --for condition=Available=True --timeout=90s
