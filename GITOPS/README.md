# Install GitOps
<pre>
https://github.com/siamaksade/openshift-gitops-getting-started
</pre>

# Deploy argocd instance for lab-ossm-apim
<pre>
oc create -f ns.yml
oc create -f argocd.yml
# get admin password
oc extract secret/openshift-gitops-cluster  --to=- -n openshift-gitops
oc extract secret/argocd-cluster  --to=- -n gitops-lab-ossm-apim
</pre>

# Create project lab-ossm-apim
<pre>
oc apply -f project.yml
</pre>