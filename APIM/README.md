# :bulb: Scripted 3scale APIM install - TO BE AUTOMATED

1. Replace the `<OCP DOMAIN>` and `<OCP APPLICATIONS DOMAIN>` occurrences with your environment values:
    - `<OCP DOMAIN>`: OCP domain. E.g.: `cluster-tjldv.tjldv.sandbox661.opentlc.com`
    - `<OCP APPLICATIONS DOMAIN>`: OCP applications domain. E.g.: `apps.cluster-tjldv.tjldv.sandbox661.opentlc.com`

2. Run the provided scripts:

```zsh
./step1-setup_3scale_externaldbs.sh
./step2-setup_api-manager_s3_externaldbs.sh
./step3-setup_selfmanaged_api-gateways.sh
./step3bis-setup_selfmanaged_tls-api-gateways.sh
./step4-setup_grafana_prometheus-datasource.sh
```

# :warning: OLD INSTALL - TO BE REMOVED

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

