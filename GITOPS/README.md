# Install GitOps
<pre>
https://github.com/siamaksade/openshift-gitops-getting-started
</pre>

# Install OSSM with cluster argocd
<pre>
oc apply -f openshift_operators_redhat_ns.yml
oc apply -f openshift_operators_ns.yml
oc adm policy add-cluster-role-to-user cluster-admin -z openshift-gitops-argocd-application-controller -n openshift-gitops
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
oc apply -f project.yml
</pre>