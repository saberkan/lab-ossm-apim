#!/usr/bin/env bash

#Environment variables
## Namespace for the 3scale API Managmenent Platform
API_MANAGER_NS="3scale-lab-ossm-amp"
## Namespace for the self-managed Red Hat 3Scale APICast gateways
APICAST_NS="3scale-lab-ossm-gw"

# Deploy the Prometheus datasource for 3scale AMP Grafana
# /!\ Make sure the access token is CORRECT
#     oc sa get-token grafana-serviceaccount -n $API_MANAGER_NS
oc apply -f ./MANIFESTS/3scale-apim_prometheus_grafanadatasource_cr.yaml -n $API_MANAGER_NS

# Deploy the Prometheus datasource for 3scale AMP Grafana
# /!\ Make sure the access token is CORRECT
#     oc sa get-token grafana-serviceaccount -n $APICAST_NS
oc apply -f ./MANIFESTS/3scale-gw_prometheus_grafanadatasource_cr.yaml -n $APICAST_NS

# Deploy Grafana dashboards for self-managed 3scale APIcasts
oc apply -f ./MANIFESTS/self-managed_apicast-mainapp_grafanadashboard_cr.yaml \
-f ./MANIFESTS/self-managed_apicast-services_grafanadashboard_cr.yaml \
-n $APICAST_NS

# Grant the grafa-serviceaccount the cluster-monitoring-view role to access the OpenShift cluster prometheus instance for
# user-workload monitoring
# Reference: https://www.redhat.com/en/blog/custom-grafana-dashboards-red-hat-openshift-container-platform-4
oc adm policy add-cluster-role-to-user cluster-monitoring-view -z grafana-serviceaccount -n $API_MANAGER_NS
oc adm policy add-cluster-role-to-user cluster-monitoring-view -z grafana-serviceaccount -n $APICAST_NS