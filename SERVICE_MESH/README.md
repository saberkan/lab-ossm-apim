1. Install Service mesh
<pre>
$ oc apply -f INSTALL/ # not tested
</pre>

2. Instanciate control planes (smcp)
<pre>
$ oc new-project mesh-1-smcp
$ oc apply -f MANIFESTS/mesh-1-smcp.yml
</pre>

3. Deploy application

3.1. prequisite
If needed, build bookinfo app following steps : 
https://github.com/maistra/istio/tree/maistra-2.1/samples/bookinfo

Remarque : in our case, we just used the existing public resources.

3.2.
<pre>
oc new-projet bookinfo-zone-1-region-1
oc apply -f APPLICATION/
</pre>

