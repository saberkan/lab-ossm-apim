1. Install Service mesh

Follow README.md in GITOPS

2. Instanciate control planes smcp 1
<pre>
oc new-project smcp-1-lab-ossm-apim
oc label ns/smcp-1-lab-ossm-apim argocd.argoproj.io/managed-by=gitops-lab-ossm-apim
oc apply -f GITOPS/smcp_1_application.yml
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

3.3 Deploy mysql DB
<pre>
oc new-project external-lab-ossm-apim
oc label ns/external-lab-ossm-apim argocd.argoproj.io/managed-by=gitops-lab-ossm-apim
oc apply -f GITOPS/external_mysql_application.yml 
</pre>

3.4 Deploy ratings with DB
<pre>
oc new-project bookinfo-db-lab-ossm-apim
oc label ns/bookinfo-db-lab-ossm-apim argocd.argoproj.io/managed-by=gitops-lab-ossm-apim
oc apply -f GITOPS/bookinfo_db_application.yml
</pre>