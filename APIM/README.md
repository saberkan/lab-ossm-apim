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

