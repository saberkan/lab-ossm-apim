#!/usr/bin/env bash

#Environment variables
## Namespace for the self-managed PostgreSQL DB and Redis
API_MANAGER_DB_NS="3scale-lab-ossm-databases"

# Create the`3scale-lab-ossm-databases` _OpenShift namespace_
oc new-project $API_MANAGER_DB_NS \
  --display-name="3scale API Manager Databases (self-managed)" \
  --description=$API_MANAGER_DB_NS

# Spin-up a persistent PostgreSQL instance for the 3scale system component
oc new-app postgresql-persistent --name="threescale-system-postgresql" \
-p MEMORY_LIMIT="512Mi" \
-p DATABASE_SERVICE_NAME="threescale-system-postgresql" \
-p POSTGRESQL_USER="threescale-system" \
-p POSTGRESQL_PASSWORD="P!ssw0rd" \
-p POSTGRESQL_DATABASE="threescaledb" \
-p VOLUME_CAPACITY="10Gi" \
-p POSTGRESQL_VERSION="12-el8"

# Import the redis 6 image
oc -n openshift import-image redis:6 --from=registry.redhat.io/rhel8/redis-6 --confirm

# Spin-up a persistent Redis instance for the 3scale system
oc new-app redis-persistent --name="threescale-system-redis" \
-p MEMORY_LIMIT="4Gi" \
-p DATABASE_SERVICE_NAME="threescale-system-redis" \
-p REDIS_PASSWORD="P!ssw0rd" \
-p VOLUME_CAPACITY="10Gi" \
-p REDIS_VERSION="6"

# Spin-up a persistent Redis instance for the 3scale backend
oc new-app redis-persistent --name="threescale-backend-redis" \
-p MEMORY_LIMIT="4Gi" \
-p DATABASE_SERVICE_NAME="threescale-backend-redis" \
-p REDIS_PASSWORD="P!ssw0rd" \
-p VOLUME_CAPACITY="10Gi" \
-p REDIS_VERSION="6"

watch oc get po