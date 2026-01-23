apiVersion: certmanager.step.sm/v1beta1
kind: StepClusterIssuer
metadata:
 name: step-issuer
 namespace: step-issuer
spec:
 url: https://step-certificates.step-certificates.svc.cluster.local
 caBundle: ${ROOT}
 provisioner:
   name: admin
   kid: ${KID}
   passwordRef:
     namespace: step-certificates
     name: step-certificates-provisioner-password
     key: password
