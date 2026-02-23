set -e

DOMAIN_NAME="k3s.osc.eonerc.rwth-aachen.de"

filename=$(basename "$0")
PARENT=$(realpath "$0"|sed "s/$filename//g")
PARENT=${PARENT::-1}

envoy_dir=$PARENT/envoy
step_dir=$PARENT/smallstep

apps=$(helm list -A -o json | jq -r '.[].chart')
EXPOSE_TYPE="nginx"
GATEWAYS_EXISTS=$(echo $apps | grep gateways-helm || true)
NGINX_EXISTS=$(echo $apps | grep ingress-nginx || true)
STEP_CERTIFICATES_EXISTS=$(echo $apps | grep step-certificates || true)
STEP_ISSUER_EXISTS=$(echo $apps | grep step-issuer || true)
CERT_MANAGER_EXISTS=$(echo $apps | grep cert-manager || true)

if [[ -z "$CERT_MANAGER_EXISTS" ]]; then
    #-----------CERT-MANAGER-------------
    #This one should also apply CRD's directly
    echo "Installing cert-manager"
    helm upgrade --install cert-manager oci://quay.io/jetstack/charts/cert-manager \
        --namespace cert-manager --create-namespace --set crds.enabled=true --set featureGates="ExperimentalGatewayAPISupport=true"
fi

if [[ -z "$STEP_CERTIFICATES_EXISTS" ]]; then
    #--------------STEP-CA---------------
    #Add smallstep repo
    helm repo add smallstep https://smallstep.github.io/helm-charts/
    helm repo update
    export PARENT
    envsubst '${PARENT}' < $PARENT/gen-vals.yaml | kubectl apply -f -

    kubectl wait --for=condition=complete job/step-install --timeout=120s --namespace step-install

    #Install step-ca
    helm upgrade --install --create-namespace \
        --namespace step-certificates -f $step_dir/values.yml \
        step-certificates smallstep/step-certificates
    envsubst '${PARENT}' < $PARENT/gen-vals.yaml | kubectl delete -f -

fi

if [[ -z "$STEP_ISSUER_EXISTS" ]]; then
    #------------STEP-ISSUER-------------
    #Install step-issuer
    helm upgrade --install step-issuer smallstep/step-issuer --namespace step-issuer --create-namespace
    #Wait for step ca 
    kubectl wait --for=condition=Ready pod/step-certificates-0 -n step-certificates --timeout=300s
    #A precautionary sleep 5
    sleep 5
    #Get step ca root 
    export ROOT=$(kubectl exec step-certificates-0 -n step-certificates -- sh -c 'step ca root | step base64')
    #Get provisioner kid
    export KID=$(kubectl exec step-certificates-0 -n step-certificates -- sh -c 'step ca provisioner list' | jq -r '.[2].key.kid')
    #Substitute in issuer
    cat $step_dir/issuer.yml.tpl | envsubst | kubectl apply -f -
fi

if [[ "$EXPOSE_TYPE" == "envoy" ]]; then
    if [[ -z "$GATEWAYS_EXISTS" ]]; then
        #--------------ENVOY---------------
        #Install envoy-gateway-system
        helm upgrade --install eg oci://docker.io/envoyproxy/gateway-helm -n envoy-gateway-system --create-namespace
        #Create merge gateway class + envoy proxy
        kubectl apply -f $envoy_dir/gateway-class.yaml
        #Create default gateway
        export DOMAIN_NAME
        cat $envoy_dir/default-gateway.yml.tpl | envsubst | kubectl apply -f -
    fi
elif [[ "$EXPOSE_TYPE" == "nginx" ]]; then
    if [[ -z "$NGINX_EXISTS" ]]; then
        #-------------- NGINX INGRESS ---------------
        helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
        helm repo update

        # Install NGINX and tell it to use cert-manager for default SSL if needed
        helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx -n ingress-nginx --create-namespace
    fi
fi
