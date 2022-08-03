# fruits-legumes-api Project

This project leverages **Red Hat build of Quarkus 2.7.x**, the Supersonic Subatomic Java Framework. More specifically, the project is implemented using [**Red Hat Camel Extensions for Quarkus 2.7.x**](https://access.redhat.com/documentation/en-us/red_hat_integration/2022.q3/html/getting_started_with_camel_extensions_for_quarkus/index).

## Prerequisites

- Maven 3.8.1+
- JDK 17 installed with `JAVA_HOME` configured appropriately
- A running [_Red Hat OpenShift_](https://access.redhat.com/documentation/en-us/openshift_container_platform) cluster
- Eventually, a running [_Red Hat 3scale API Management_](https://access.redhat.com/documentation/en-us/red_hat_3scale_api_management) platform


## Build and Deployment

### 1. Generate Java Keystores

#### Client key pair for upstream MTLS
```zsh
# Generate a self-signed key pair for APICAST MTLS
openssl req -newkey rsa:4096 -x509 -nodes -days 3650 \
-keyout ./tls-keys/apicast.key -out ./tls-keys/apicast.crt \
-subj "/CN=apicast.svc"

# Generate a self-signed key pair for API consumer
openssl req -newkey rsa:4096 -x509 -nodes -days 3650 \
-keyout ./tls-keys/apiconsumer.key -out ./tls-keys/apiconsumer.crt \
-subj "/CN=apiconsumer.svc"
```

#### Keystore with auto-signed key pair (private/public keys)
```zsh
#  Generating fruits-legumes-api client auto-signed key pair (private and public) keystore
keytool -genkey -keypass 'P@ssw0rd' -storepass 'P@ssw0rd' -alias fruits-legumes-api -keyalg RSA \
-dname 'CN=fruits-legumes-api' \
-validity 3600 -keystore ./tls-keys/keystore.p12 -v \
-ext san=DNS:fruits-legumes-api.svc,DNS:fruits-legumes-api.svc.cluster.local,DNS:fruits-legumes-api.camel-quarkus.svc,DNS:fruits-legumes-api.camel-quarkus.svc.cluster.local
# Exporting fruits-legumes-api public auto-signed certificate (api_cert)
keytool -export -alias fruits-legumes-api -keystore ./tls-keys/keystore.p12 -file ./tls-keys/fruits-legumes-api_cert -storepass 'P@ssw0rd' -v
```

#### Truststore

```zsh
# Use the Java cacerts as the basis for the truststore
cp /usr/local/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home/lib/security/cacerts ./tls-keys/truststore.p12
keytool -storepasswd -keystore ./tls-keys/truststore.p12 -storepass changeit -new 'P@ssw0rd'
# Importing the client public certificate (client_cert) into the fruits-legumes-api truststore
keytool -importcert -keystore ./tls-keys/truststore.p12 -storepass 'P@ssw0rd' -file ./tls-keys/apicast.crt -trustcacerts -noprompt
# Importing the staging APIcast gateway public certificate into the fruits-legumes-api truststore
keytool -importcert -keystore ./tls-keys/truststore.p12 -storepass 'P@ssw0rd' -alias apicast-staging -file ./tls-keys/apicast-staging.crt -trustcacerts -noprompt
# Importing the production APIcast gateway public certificate into the fruits-legumes-api truststore
keytool -importcert -keystore ./tls-keys/truststore.p12 -storepass 'P@ssw0rd' -alias apicast-production -file ./tls-keys/apicast-production.crt -trustcacerts -noprompt
```

> :bulb: **Example on how to obtain the APIcast gateways public certificates:**
```zsh
# staging APIcast gateway public certificate
openssl s_client -showcerts -servername fruits-legumes-api-tls-staging.<OCP APPLICATIONS DOMAIN> -connect fruits-legumes-api-tls-staging.<OCP APPLICATIONS DOMAIN>:443
# production APIcast gateway public certificate
openssl s_client -showcerts -servername fruits-legumes-api-tls.<OCP APPLICATIONS DOMAIN> -connect fruits-legumes-api-tls.<OCP APPLICATIONS DOMAIN>:443
```
with `<OCP APPLICATIONS DOMAIN>`: OCP applications domain. E.g.: `apps.cluster-l5mt5.l5mt5.sandbox1873.opentlc.com`

### 2. Running the application in dev mode

You can run your application in dev mode that enables live coding using:
```shell script
./mvnw quarkus:dev
```

> **_NOTE:_**  Quarkus now ships with a Dev UI, which is available in dev mode only at http://localhost:8080/q/dev/.

### 3. Packaging and running the application

The application can be packaged using:
```shell script
./mvnw package
```
It produces the `quarkus-run.jar` file in the `target/quarkus-app/` directory.
Be aware that it’s not an _über-jar_ as the dependencies are copied into the `target/quarkus-app/lib/` directory.

The application is now runnable using `java -jar target/quarkus-app/quarkus-run.jar`.

If you want to build an _über-jar_, execute the following command:
```shell script
./mvnw package -Dquarkus.package.type=uber-jar
```

The application, packaged as an _über-jar_, is now runnable using `java -jar target/*-runner.jar`.

### 4. Creating a native executable

You can create a native executable using: 
```shell script
./mvnw package -Pnative
```

Or, if you don't have GraalVM installed, you can run the native executable build in a container using: 
```shell script
./mvnw package -Pnative -Dquarkus.native.container-build=true
```

You can then execute your native executable with: `./target/fruits-legumes-api-1.0.0-runner`

If you want to learn more about building native executables, please consult https://quarkus.io/guides/maven-tooling.

### 5. Running Jaeger locally

[**Jaeger**](https://www.jaegertracing.io/), a distributed tracing system for observability ([_open tracing_](https://opentracing.io/)). :bulb: A simple way of starting a Jaeger tracing server is with `docker` or `podman`:
1. Start the Jaeger tracing server:
    ```
    podman run --rm -e COLLECTOR_ZIPKIN_HTTP_PORT=9411 \
    -p 5775:5775/udp -p 6831:6831/udp -p 6832:6832/udp \
    -p 5778:5778 -p 16686:16686 -p 14268:14268 -p 9411:9411 \
    quay.io/jaegertracing/all-in-one:latest
    ```
2. While the server is running, browse to http://localhost:16686 to view tracing events.

### 6. Test locally

```zsh
curl -k -vvv --cert ./tls-keys/apicast.crt --key ./tls-keys/apicast.key https://localhost:8443/fruits
```

## Deploy to OpenShift

1. Login to the OpenShift cluster
    ```zsh
    oc login ...
    ```

2. Create an OpenShift project to host the service
    ```zsh
    oc new-project ceq-services-jvm --display-name="Red Hat Camel Extensions for Quarkus Apps - JVM Mode"
    ```

3. Create secret containing the keystore

    ```zsh
    oc create secret generic keystore-secret \
    --from-file=keystore.p12=./tls-keys/keystore.p12
    ```

4. Create secret containing the truststore

    ```zsh
    oc create secret generic truststore-secret \
    --from-file=truststore.p12=./tls-keys/truststore.p12
    ```

5. Deploy the CEQ service
    ```zsh
    ./mvnw clean package -Dquarkus.kubernetes.deploy=true
    ```

6. **OPTIONAL** - In order to test the service directly (without going through the _APICast gateway_), create a _passthrough_ OpenShift route:
    ```shell script
    oc apply -f - <<EOF
    apiVersion: route.openshift.io/v1
    kind: Route
    metadata:
        labels:
            app.kubernetes.io/name: fruits-legumes-api
            app.kubernetes.io/version: 1.0.0
            app.openshift.io/runtime: quarkus
        name: fruits-legumes-api-direct
    spec:
        host: fruits-legumes-api-direct.apps.cluster-l5mt5.l5mt5.sandbox1873.opentlc.com
        port:
            targetPort: https
        tls:
            insecureEdgeTerminationPolicy: Redirect
            termination: passthrough
        to:
            kind: Service
            name: fruits-legumes-api
            weight: 100
        wildcardPolicy: None
    EOF
    ```

### OpenTelemetry with Jaeger

1. If not already installed, install the Red Hat OpenShift distributed tracing platform (Jaeger) operator with an AllNamespaces scope.
_**:warning: cluster-admin privileges are required**_
    ```
    oc apply -f - <<EOF
    apiVersion: operators.coreos.com/v1alpha1
    kind: Subscription
    metadata:
        name: jaeger-product
        namespace: openshift-operators
    spec:
        channel: stable
        installPlanApproval: Automatic
        name: jaeger-product
        source: redhat-operators
        sourceNamespace: openshift-marketplace
    EOF
    ```

2. Verify the successful installation of the Red Hat OpenShift distributed tracing platform operator
    ```zsh
    watch oc get sub,csv
    ```

3. Create the allInOne Jaeger instance in the dsna-pilot OpenShift project
    ```zsh
    oc apply -f - <<EOF
    apiVersion: jaegertracing.io/v1
    kind: Jaeger
    metadata:
        name: jaeger-all-in-one-inmemory
    spec:
        allInOne:
            options:
            log-level: info
        strategy: allInOne
    EOF
    ```

## Related Guides

- OpenShift ([guide](https://quarkus.io/guides/deploying-to-openshift)): Generate OpenShift resources from annotations
- Camel Platform HTTP ([guide](https://access.redhat.com/documentation/en-us/red_hat_integration/2.latest/html/camel_extensions_for_quarkus_reference/extensions-platform-http)): Expose HTTP endpoints using the HTTP server available in the current platform
- Camel MicroProfile Health ([guide](https://access.redhat.com/documentation/en-us/red_hat_integration/2.latest/html/camel_extensions_for_quarkus_reference/extensions-microprofile-health)): Expose Camel health checks via MicroProfile Health
- Camel MicroProfile Metrics ([guide](https://access.redhat.com/documentation/en-us/red_hat_integration/2.latest/html/camel_extensions_for_quarkus_reference/extensions-microprofile-metrics)): Expose metrics from Camel routes
- Camel Direct ([guide](https://access.redhat.com/documentation/en-us/red_hat_integration/2.latest/html/camel_extensions_for_quarkus_reference/extensions-direct)): Call another endpoint from the same Camel Context synchronously
- Camel Jackson ([guide](https://access.redhat.com/documentation/en-us/red_hat_integration/2.latest/html/camel_extensions_for_quarkus_reference/extensions-jackson)): Marshal POJOs to JSON and back using Jackson
- YAML Configuration ([guide](https://quarkus.io/guides/config#yaml)): Use YAML to configure your Quarkus application
- RESTEasy JAX-RS ([guide](https://quarkus.io/guides/rest-json)): REST endpoint framework implementing JAX-RS and more
- Kubernetes Config ([guide](https://quarkus.io/guides/kubernetes-config)): Read runtime configuration from Kubernetes ConfigMaps and Secrets
- Camel OpenTracing ([guide](https://camel.apache.org/camel-quarkus/latest/reference/extensions/opentracing.html)): Distributed tracing using OpenTracing
- Camel Rest ([guide](https://access.redhat.com/documentation/en-us/red_hat_integration/2.latest/html/camel_extensions_for_quarkus_reference/extensions-rest)): Expose REST services and their OpenAPI Specification or call external REST services

## Provided Code

### YAML Config

Configure your application with YAML

[Related guide section...](https://quarkus.io/guides/config-reference#configuration-examples)

The Quarkus application configuration is located in `src/main/resources/application.yml`.

### RESTEasy JAX-RS

Easily start your RESTful Web Services

[Related guide section...](https://quarkus.io/guides/getting-started#the-jax-rs-resources)