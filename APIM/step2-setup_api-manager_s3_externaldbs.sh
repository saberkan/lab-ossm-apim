#!/usr/bin/env bash

#Environment variables
## Namespace for the Red Hat 3Scale API Management Platform
API_MANAGER_NS="3scale-lab-ossm-amp"
## Password for the master admin account (master)
API_MASTER_PASSWORD="P!ssw0rd"
## OpenShift domain suffix
OCP_DOMAIN="<OCP DOMAIN>"
## OpenShift routes domain suffix
OCP_WILDCARD_DOMAIN="apps.${OCP_DOMAIN}"
## Master API access token
API_MASTER_ACCESS_TOKEN="<3SCALE MASTER ACCESS TOKEN>"
## Tenant API access token
API_TENANT_ACCESS_TOKEN="<3SCALE TENANT ACCESS TOKEN>"
## Name of the initial tenant
TENANT_NAME="apim-demo"
## Password for the initial tenant admin account (admin)
TENANT_ADMIN_PASSWD="P!ssw0rd"

# Create the`3scale-lab-ossm-amp` _OpenShift namespace_
oc new-project $API_MANAGER_NS \
  --display-name="3scale API Manager" \
  --description=$API_MANAGER_NS

# Install Operators using the OLM
## Create the namespace OperatorGroup (all operators to be installed are singleNamespace-scoped)
oc apply -f ./INSTALL/3scale-amp-operatorgroup.yaml

## The _Red Hat Integration - 3scale operator_ 
oc apply -f ./INSTALL/3scale-operator-subscription.yaml

## The _Grafana Operator (Community)_
oc apply -f ./INSTALL/3scale-apim-grafana-operator-subscription.yaml

# Wait for Operators to be installed
watch oc get sub,csv,installPlan

# Create a Grafana instance
oc apply -f ./MANIFESTS/grafana_cr.yaml -n $API_MANAGER_NS

# Create the 'system-seed' secret to customize the indicated parameters for the Red Hat 3scale API Management Platform
oc create secret generic system-seed \
  --from-literal=MASTER_USER=master \
  --from-literal=MASTER_PASSWORD="${API_MASTER_PASSWORD}" \
  --from-literal=MASTER_ACCESS_TOKEN="${API_MASTER_ACCESS_TOKEN}" \
  --from-literal=MASTER_DOMAIN=master \
  --from-literal=ADMIN_USER=admin \
  --from-literal=ADMIN_PASSWORD="${TENANT_ADMIN_PASSWD}" \
  --from-literal=ADMIN_EMAIL="admin@acme.com" \
  --from-literal=ADMIN_ACCESS_TOKEN="${API_TENANT_ACCESS_TOKEN}" \
  --from-literal=TENANT_NAME="${TENANT_NAME}" \
  -n $API_MANAGER_NS

# Create the 'system-smtp' to customize the parameters for the SMTP server
# oc create secret generic system-smtp \
#   --from-literal=authentication="plain" \
#   --from-literal=address="<SMTP HOST>" \
#   --from-literal=domain="" \
#   --from-literal=openssl.verify.mode="none" \
#   --from-literal=port="<SMTP PORT>" \
#   --from-literal=username="<SMTP USERNAME>" \
#   --from-literal=password="<SMTP PASSWORD>" \
#   -n $API_MANAGER_NS

# Create the 'system-recaptcha' to set the Google reCAPTHCA v2 keys
# Reference: https://access.redhat.com/documentation/en-us/red_hat_3scale_api_management/2.11/html/operating_3scale/configuring-recaptcha-for-threescale 
# When configured in Audience -> Developer Portal -> Spam Protection
# - Always -> reCAPTCHA will always appear when a form is presented to a user who is not logged in.
# - Suspicious only -> reCAPTCHA is only shown if the automated checks detect a possible spammer.
# - Never -> turns off Spam protection.
## => When the 3scale APIM is already deployed:
#     1. Patch the system-recaptcha secret (Note: The CLI reCAPTCHA option does not require base64 format encoding):
#        oc patch secret/system-recaptcha \
#        -p '{"stringData": {"PUBLIC_KEY": "<PUBLIC KEY>", "PRIVATE_KEY": "<PRIVATE KEY>"}}' \
#        -n $API_MANAGER_NS  
#     2. Redeploy the system pod after you have completed one of the above options:
#        oc rollout latest dc/system-app -n $API_MANAGER_NS
# oc create secret generic system-recaptcha \
#   --from-literal=PUBLIC_KEY="<PUBLIC KEY>" \
#   --from-literal=PRIVATE_KEY="<PRIVATE KEY>" \
#   -n $API_MANAGER_NS

# Jaeger configuration secrets fot the managed APIcast
# Reference: https://github.com/3scale/3scale-operator/blob/3scale-2.12.0-GA/doc/apimanager-reference.md#APIcastTracingConfigSecret
oc create secret generic threescale-production-jaeger-conf-secret \
  --from-file=config=./MANIFESTS/threescale-apicast-production_jaeger_config.json \
  -n $API_MANAGER_NS
oc create secret generic threescale-staging-jaeger-conf-secret \
  --from-file=config=./MANIFESTS/threescale-apicast-staging_jaeger_config.json \
  -n $API_MANAGER_NS

# Deploy the all-in-one-memory Jaeger
oc apply \
  -f ./MANIFESTS/jaeger-all-in-one-memory_cr.yaml \
  -n $API_MANAGER_NS

# Create the '3scale-aws-s3-auth-secret' secret
# References: 
# - https://github.com/3scale/3scale-operator/blob/3scale-2.12.0-GA/doc/apimanager-reference.md#fileStorage-S3-credentials-secret
# - https://access.redhat.com/documentation/en-us/red_hat_3scale_api_management/2.10/html/installing_3scale/install-threescale-on-openshift-guide#amazon_simple_storage_service_3scale_emphasis_filestorage_emphasis_installation
oc create secret generic 3scale-aws-s3-auth-secret \
  --from-literal=AWS_ACCESS_KEY_ID="<AWS_ACCESS_KEY_ID>" \
  --from-literal=AWS_SECRET_ACCESS_KEY="<AWS_SECRET_ACCESS_KEY>" \
  --from-literal=AWS_BUCKET="3scale-bucket" \
  --from-literal=AWS_REGION="<AWS_REGION>" \
  -n $API_MANAGER_NS

## For external databases connections
## Reference: https://access.redhat.com/documentation/en-us/red_hat_3scale_api_management/2.11/html/installing_3scale/install-threescale-on-openshift-guide#external_databases_installation
# Create the 'backend-redis' secret
# Reference: https://github.com/3scale/3scale-operator/blob/3scale-2.12.0-GA/doc/apimanager-reference.md#backend-redis
oc create secret generic backend-redis \
  --from-literal=REDIS_STORAGE_URL="redis://:P!ssw0rd@threescale-backend-redis.3scale-databases.svc:6379/0" \
  --from-literal=REDIS_QUEUES_URL="redis://:P!ssw0rd@threescale-backend-redis.3scale-databases.svc:6379/1" \
  -n $API_MANAGER_NS

# Create the 'system-redis' secret
# Reference: https://github.com/3scale/3scale-operator/blob/3scale-2.12.0-GA/doc/apimanager-reference.md#system-redis
oc create secret generic system-redis \
  --from-literal=URL="redis://:P!ssw0rd@threescale-system-redis.3scale-databases.svc:6379/1" \
  -n $API_MANAGER_NS

# Create the 'system-database' secret (PostgreSQL DB)
# Reference: https://github.com/3scale/3scale-operator/blob/3scale-2.12.0-GA/doc/apimanager-reference.md#system-database
oc create secret generic system-database \
  --from-literal=URL="postgresql://threescale-system:P!ssw0rd@threescale-system-postgresql.3scale-databases.svc:5432/threescaledb" \
  -n $API_MANAGER_NS

# Create the 'zync' secret (PostgreSQL DB)
# Reference: https://github.com/3scale/3scale-operator/blob/3scale-2.12.0-GA/doc/apimanager-reference.md#zync
oc create secret generic zync \
  --from-literal=DATABASE_URL="postgresql://threescale-zync:P!ssw0rd@threescale-zync-postgresql.3scale-databases.svc:5432/zync_production" \
  --from-literal=ZYNC_DATABASE_PASSWORD="P!ssw0rd" \
  -n $API_MANAGER_NS

# Deploy the Red Hat 3scale API Management Platform
oc apply \
  -f ./MANIFESTS/apimanager_aws-s3_externaldbs_cr.yaml \
  -n $API_MANAGER_NS

# Watch the pods being created
watch oc get po -n $API_MANAGER_NS

# Setup Service Discovery
# Cf. https://access.redhat.com/documentation/en-us/red_hat_3scale_api_management/2.11/html/admin_portal_guide/service_discovery_from_openshift_to_3scale
# Configuring without RH SSO
# To configure the 3scale Service Discovery without SSO, you can use 3scale Single Service Account 
# to authenticate to OpenShift API service. 3scale Single Service Account provides a seamless 
# authentication to the cluster for the Service Discovery without an authorization layer at the user level. 
# All 3scale tenant administration users have the same access level to the cluster while discovering API 
# services through 3scale.
# ===> Grant the 3scale deployment amp service account with view cluster level permission.
oc adm policy add-cluster-role-to-user view system:serviceaccount:${API_MANAGER_NS}:amp