1. Install Service mesh

<pre>
# Follow README.md in GITOPS to prepare GITOPS first !
# then install : 
oc apply -f openshift_operators_redhat_ns.yml
oc apply -f openshift_operators_ns.yml
oc adm policy add-cluster-role-to-user cluster-admin -z openshift-gitops-argocd-application-controller -n openshift-gitops
oc apply -f ossm_install_application.yml
</pre>

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

4. Deploy Mesh 2
<pre>
oc new-project smcp-2-lab-ossm-apim
oc label ns/smcp-2-lab-ossm-apim argocd.argoproj.io/managed-by=gitops-lab-ossm-apim
oc apply -f GITOPS/smcp_2_application.yml
</pre>

5. Deploy federation between smcp 1 and smcp 2 - manual

5.0 Init vars
<pre>
MESH1_DISCOVERY_PORT="8188"
MESH1_SERVICE_PORT="15443"
MESH2_DISCOVERY_PORT="8188"
MESH2_SERVICE_PORT="15443"
</pre>

5.1 Get root certificate
<pre>
MESH1_CERT=$(oc get configmap -n smcp-1-lab-ossm-apim istio-ca-root-cert -o jsonpath='{.data.root-cert\.pem}' | sed ':a;N;$!ba;s/\n/\\\n    /g')
MESH2_CERT=$(oc get configmap -n smcp-2-lab-ossm-apim istio-ca-root-cert -o jsonpath='{.data.root-cert\.pem}' | sed ':a;N;$!ba;s/\n/\\\n    /g')
</pre>

5.2 Get ingress router 
<pre>
MESH1_ADDRESS=mesh2-ingress.smcp-1-lab-ossm-apim.svc.cluster.local
MESH2_ADDRESS=mesh1-ingress.smcp-2-lab-ossm-apim.svc.cluster.local
</pre>

5.3 Enable federation
<pre>
oc apply -f CONFIGS/FEDERATION/mesh-1-smcp.yml 

oc apply -f CONFIGS/FEDERATION/mesh-2-smcp.yml 

sed "s:{{MESH2_CERT}}:$MESH2_CERT:g" CONFIGS/FEDERATION/configmap-export-template.yml | oc apply -f -

sed "s:{{MESH1_CERT}}:$MESH1_CERT:g" CONFIGS/FEDERATION/configmap-import-template.yml | oc apply -f -

sed -e "s:{{MESH2_ADDRESS}}:$MESH2_ADDRESS:g" -e "s:{{MESH2_DISCOVERY_PORT}}:$MESH2_DISCOVERY_PORT:g" -e "s:{{MESH2_SERVICE_PORT}}:$MESH2_SERVICE_PORT:g" CONFIGS/FEDERATION/servicemeshpeer-import-template.yml | oc apply -f -

sed -e "s:{{MESH1_ADDRESS}}:$MESH1_ADDRESS:g" -e "s:{{MESH1_DISCOVERY_PORT}}:$MESH1_DISCOVERY_PORT:g" -e "s:{{MESH1_SERVICE_PORT}}:$MESH1_SERVICE_PORT:g" CONFIGS/FEDERATION/servicemeshpeer-export-template.yml  | oc apply -f -

oc apply -f CONFIGS/FEDERATION/exportedserviceset.yml 

oc apply -f CONFIGS/FEDERATION/importedserviceset.yml 
</pre>

6. Split traffic ratings between mesh 1 and mesh 2 - manual
<pre>
oc apply -f CONFIGS/FEDERATION/ratings-split-virtualservice.yml

oc apply -f CONFIGS/FEDERATION/ratings-mtls-strict-pa.yml

# You might need to delete all pods to avoid certificat uknown issues
</pre>
