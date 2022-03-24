1. Install Service mesh

Follow README.md in GITOPS

2. Instanciate control planes (smcp)
<pre>
//TODO
</pre>

3. Deploy application

3.1. prequisite

If needed, build bookinfo app following steps : 
https://github.com/maistra/istio/tree/maistra-2.1/samples/bookinfo

Remarque : in our case, we just used the existing public resources.

3.2. Deploy bookinfo application in bookinfo-lab-ossm-apim namespace
<pre>
oc new-project bookinfo-lab-ossm-apim
oc label ns/bookinfo-lab-ossm-apim argocd.argoproj.io/managed-by=gitops-lab-ossm-apim
oc apply -f GITOPS/bookinfo_application.yml
</pre>

