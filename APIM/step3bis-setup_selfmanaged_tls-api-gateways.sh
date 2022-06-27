#!/usr/bin/env bash

#Environment variables
## Namespace for the self-managed Red Hat 3Scale APICast gateways
APICAST_NS="3scale-lab-ossm-gw"
## RHPDS OpenShift domain suffix
OCP_DOMAIN="cluster-8wk5n.8wk5n.sandbox1235.opentlc.com"
## RHPDS OpenShift routes domain suffix
OCP_WILDCARD_DOMAIN="apps.${OCP_DOMAIN}"
## Tenant API access token (apim-demo)
API_TENANT_ACCESS_TOKEN="88fb895da81b95270d3bc196b86edc211fa570fdec3d8f80581fa7fce4015512"
## Name of the target tenant
TENANT_NAME="apim-demo"
# The tenant APICast uses the tenant route to communicate with the Red Hat 3scale AMP
API_TENANT_THREESCALE_PORTAL_ENDPOINT="https://${API_TENANT_ACCESS_TOKEN}@${TENANT_NAME}-admin.${OCP_WILDCARD_DOMAIN}"

# Create the`3scale-lab-ossm-gw` _OpenShift namespace_
oc new-project $APICAST_NS \
  --display-name="3Scale APICast Gateways" \
  --description=$APICAST_NS

# Install 3scale APIcast operator using the OLM
## Create the namespace OperatorGroup (the apicast-operator is singleNamespace-scoped)
oc apply -f ./INSTALL/3scale-gw-operatorgroup.yaml

## The _Red Hat Integration - 3scale APIcast gateway operator_ 
oc apply -f ./INSTALL/apicast-operator-subscription.yaml

## The _Grafana Operator (Community)_
oc apply -f ./INSTALL/3scale-gw-grafana-operator-subscription.yaml

# Wait for Operators to be installed
watch oc get sub,csv,installPlan

# Create a Grafana instance
oc apply -f ./MANIFESTS/grafana_cr.yaml -n $APICAST_NS

# Jaeger configuration secret fot the self-managed APIcast
# Reference: https://github.com/3scale/apicast-operator/blob/3scale-2.11-stable/doc/apicast-crd-reference.md#TracingConfigSecret
oc create secret generic selfmanaged-tls-production-jaeger-secret \
  --from-file=config=./MANIFESTS/selfmanaged-tls-apicast-production_jaeger_config.json \
  -n $APICAST_NS
oc create secret generic selfmanaged-tls-staging-jaeger-secret \
  --from-file=config=./MANIFESTS/selfmanaged-tls-apicast-staging_jaeger_config.json \
  -n $APICAST_NS

# Create secrets that allows APIcasts to communicate with 3scale. 
## Secrets that contain 3scale System Admin Portal endpoint information for the ${TENANT_NAME}
### Used by the self-managed Staging APIcast
oc create secret generic ${TENANT_NAME}-tls-staging-3scaleportal-secret \
  --from-literal=AdminPortalURL="${API_TENANT_THREESCALE_PORTAL_ENDPOINT}" \
  -n $APICAST_NS

### Used by the self-managed Production APIcast
oc create secret generic ${TENANT_NAME}-tls-production-3scaleportal-secret \
  --from-literal=AdminPortalURL="${API_TENANT_THREESCALE_PORTAL_ENDPOINT}" \
  -n $APICAST_NS

# Create self-signed key pairs and secrets for TLS
## Generate a self-signed key pair for staging
openssl req -newkey rsa:4096 -x509 -nodes -days 3650 \
-keyout /tmp/apicast-staging.key -out /tmp/apicast-staging.crt \
-subj "/CN=apicast-apim-demo-tls-staging.svc" \
-extensions san \
-config <( \
  echo '[req]'; \
  echo 'distinguished_name=req'; \
  echo '[san]'; \
  echo 'subjectAltName=DNS:apicast-apim-demo-tls-staging.svc,DNS:*.apps.cluster-8wk5n.8wk5n.sandbox1235.opentlc.com')

## Generate a self-signed key pair for production
openssl req -newkey rsa:4096 -x509 -nodes -days 3650 \
-keyout /tmp/apicast-production.key -out /tmp/apicast-production.crt \
-subj "/CN=apicast-apim-demo-tls-production.svc" \
-extensions san \
-config <( \
  echo '[req]'; \
  echo 'distinguished_name=req'; \
  echo '[san]'; \
  echo 'subjectAltName=DNS:apicast-apim-demo-tls-production.svc,DNS:*.apps.cluster-8wk5n.8wk5n.sandbox1235.opentlc.com')

## Create certificate secrets for TLS
### Used by the self-managed Staging APIcast
oc create secret tls ${TENANT_NAME}-staging-tls-secret \
  --cert=/tmp/apicast-staging.crt \
  --key=/tmp/apicast-staging.key \
  -n $APICAST_NS

### Used by the self-managed Production APIcast
oc create secret tls ${TENANT_NAME}-production-tls-secret \
  --cert=/tmp/apicast-production.crt \
  --key=/tmp/apicast-production.key \
  -n $APICAST_NS

# Create API gateway staging related resources in OpenShift for the ${TENANT_NAME}
oc apply -f ./MANIFESTS/apim-demo-tenant-tls-apicast-staging_cr.yaml -n $APICAST_NS

# Create API gateway production related resources in OpenShift for the ${TENANT_NAME}
oc apply -f ./MANIFESTS/apim-demo-tenant-tls-apicast-prod_cr.yaml -n $APICAST_NS

# Install PodMonitor to scrap prometheus metrics from the apicast pods
oc apply -n $APICAST_NS -f - <<EOF
---
apiVersion: monitoring.coreos.com/v1
kind: PodMonitor
metadata:
  labels:
    deployment: apicast-apim-demo-tls-staging
  name: apicast-apim-demo-tls-staging
spec:
  namespaceSelector: {}
  podMetricsEndpoints:
  - path: /metrics
    port: metrics
    scheme: http
  selector:
    matchLabels:
      deployment: apicast-apim-demo-tls-staging
---
apiVersion: monitoring.coreos.com/v1
kind: PodMonitor
metadata:
  labels:
    deployment: apicast-apim-demo-tls-production
  name: apicast-apim-demo-tls-production
spec:
  namespaceSelector: {}
  podMetricsEndpoints:
  - path: /metrics
    port: metrics
    scheme: http
  selector:
    matchLabels:
      deployment: apicast-apim-demo-tls-production
EOF

## Creating passthrough routes for the ${TENANT_NAME} self-managed APIcast gateways
# oc create route passthrough <product-name>-${TENANT_NAME}-tls-staging-apicast \
#      --service=apicast-${TENANT_NAME}-tls-staging \
#      --hostname=<product-name>-${TENANT_NAME}-tls-staging.${OCP_WILDCARD_DOMAIN} \
#      --port=httpsproxy \
#      -n $APICAST_NS

# oc create route passthrough <product-name>-${TENANT_NAME}-tls-production \
#      --service=apicast-${TENANT_NAME}-tls-production \
#      --hostname=<product-name>-${TENANT_NAME}-tls.${OCP_WILDCARD_DOMAIN} \
#      --port=httpsproxy \
#      -n $APICAST_NS