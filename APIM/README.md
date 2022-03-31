1.  Install 3scale
<pre>
oc new-project 3scale-lab-ossm-apim
oc label ns/3scale-lab-ossm-apim argocd.argoproj.io/managed-by=gitops-lab-ossm-apim
</pre>

```
cat <<EOF | oc apply -f -
apiVersion: operators.coreos.com/v1
kind: OperatorGroup
metadata:
  name: 3scale-lab-ossm-apim
  namespace: 3scale-lab-ossm-apim 
spec:
    targetNamespaces:
    - 3scale-lab-ossm-apim
EOF
```

<pre>
oc apply -f GITOPS/apim_install_application.yml
</pre>

2. Deploy APIM

2.1 Deploy APIM instance in GitOps
<pre>
oc apply -f GITOPS/apim_application.yml
</pre>

2.2 Get admin secrets
<pre>
oc get secret system-seed -o json | jq -r .data.ADMIN_USER | base64 -d
oc get secret system-seed -o json | jq -r .data.ADMIN_PASSWORD | base64 -d
</pre>

