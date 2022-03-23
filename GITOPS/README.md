# Install GitOps
<pre>
https://github.com/siamaksade/openshift-gitops-getting-started
</pre>

# Install OSSM
<pre>
oc apply -f ossm_install_application.yml
</pre>

# Deploy argocd instance for lab-ossm-apim
<pre>
oc create -f ns.yml
oc create -f argocd.yml
# get admin password
oc extract secret/openshift-gitops-cluster  --to=-
</pre>

# Create project lab-ossm-apim
<pre>
oc apply -f projet.yml
</pre>