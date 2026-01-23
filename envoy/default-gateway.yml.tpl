apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: eg
  namespace: envoy-gateway-system
  annotations:
    cert-manager.io/issuer: step-issuer
    cert-manager.io/issuer-group: certmanager.step.sm
    cert-manager.io/issuer-kind: StepClusterIssuer
spec:
  gatewayClassName: eg
  listeners:
  - allowedRoutes:
      namespaces:
        from: All
    name: https
    hostname: "*.${DOMAIN_NAME}"
    port: 443
    protocol: HTTPS
    tls:
      certificateRefs:
      - group: ""
        kind: Secret
        name: tls-https-secret
      mode: Terminate
  - allowedRoutes:
      namespaces:
        from: All
    name: http
    hostname: "*.${DOMAIN_NAME}"
    port: 80
    protocol: HTTP
