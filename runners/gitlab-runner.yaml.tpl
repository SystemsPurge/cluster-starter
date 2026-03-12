gitlabUrl: ${GITLAB_URL}
runnerToken: ${GITLAB_PAT}
rbac:
  create: true
serviceAccount:
  create: true

runners:
  jobNamespace: gitlab-runner-controller
  config: |
    [[runners]]
      [runners.kubernetes]
        image = "docker:26-cli"
        privileged = true
        [[runners.kubernetes.volumes.empty_dir]]
          name = "dind-socket"
          mount_path = "/var/run"
          medium = "Memory"
        [[runners.kubernetes.services]]
          name = "docker:26-dind"
          alias = "docker-dind"
          command = ["dockerd-entrypoint.sh", "--mtu=1400"]
  tags: "self-hosted"
