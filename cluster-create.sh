#Host dependencies
filename=$(basename "$0")
parent=$(realpath "$0"|sed "s/$filename//g")
parent=${parent::-1}

apt-get update -y

set -e

curl_exists=$(which curl)
jq_exists=$(which jq)
helm_exists=$(which helm)
kubectl_exists=$(which kubectl)
envsubst_exists=$(which envsubst)

if [[ -z "$curl_exists" ]]; then
    apt-get install -y curl
fi

if [[ -z "$jq_exists" ]]; then
    apt-get install -y jq
fi

if [[ -z "$envsubst_exists" ]]; then
    apt-get install -y envsubst
fi

if [[ -z "$kubectl_exists" ]]; then
    kwd_dir="$parent/kwd"
    mkdir $kwd_dir
    curl -L -o $kwd_dir/kubectl "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    curl -L -o  $kwd_dir/kubectl.sha256 "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl.sha256"
    echo "$(cat $kwd_dir/kubectl.sha256)  $kwd_dir/kubectl" | sha256sum --check
    sudo install -o root -g root -m 0755 $kwd_dir/kubectl /usr/local/bin/kubectl
    rm -rf $kwd_dir
fi

if [[ -z "$helm_exists" ]]; then
    #Install helm
    curl -fsSL -o $parent/get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-4
    chmod 700 $parent/get_helm.sh
    . $parent/get_helm.sh
fi
