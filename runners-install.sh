set -e

filename=$(basename "$0")
PARENT=$(realpath "$0"|sed "s/$filename//g")
PARENT=${PARENT::-1}

runner_dir=$PARENT/runners

GITHUB_PAT=""
OWNER=""
REPO=""

GITLAB_PAT=""
GITLAB_URL=""

if [[ -n "$GITHUB_PAT" && -n "$OWNER" && -n "$REPO_NAME" ]]; then
    #-----------GITHUB-ARC-------------
    #controller
    helm install arc --namespace "arc-systems" --create-namespace oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set-controller
    LABEL=$OWNER-$REPO_NAME
    LABEL="${LABEL,,}"
    
    #pat secret
    kubectl create secret generic $LABEL-secret \
      --namespace arc-systems \
      --from-literal=github_token=$GITHUB_PAT
    
    #runner
    helm install $LABEL-runner \
        --namespace arc-systems \
        oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set \
        --set githubConfigUrl="https://github.com/$OWNER/$REPO_NAME" \
        --set githubConfigSecret="$LABEL-secret" \
        --set containerMode.type="dind" \

fi

if [[ -n "$GITLAB_PAT" ]]; then
    helm repo add gitlab https://charts.gitlab.io
    helm repo update gitlab
    export GITLAB_PAT GITLAB_URL
    envsubst '${GITLAB_PAT}${GITLAB_URL}'< $runner_dir/gitlab-runner.yaml.tpl | helm upgrade --install -n gitlab-runner-controller gitlab/gitlab-runner -f - 
fi