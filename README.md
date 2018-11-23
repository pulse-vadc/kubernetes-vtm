Pulse Secure Virtual Traffic Manager Kubernetes Manifests
===

This repository contains an example Kubernetes manifest file that will deploy Pulse Secure Virtual Traffic Manager into a Kubernetes cluster, along with some additional example manifests for deploying a simple back-end application, configuring the running traffic manager to load-balance that application and exposing the application through the traffic manager as a NodePort Service.

<a name="quickstart" id="quickstart"></a>Quickstart
---
* Download all the files from the ```deploy/``` folder of this repository
* If necessary, edit the 'image' field of the Deployment in ```vtm-kubernetes-foundation.yaml``` to point to a copy of the traffic manager stored in a private registry
* Run `kubectl apply -f vtm-kubernetes-foundation.yaml` to deploy the traffic manager
* Run `kubectl apply -f example-application.yaml` to deploy a simple back-end application
* Run `kubectl apply -f vtm-example-service.yaml` to deploy the traffic manager configuration to load-balance that application and deploy a NodePort service to access the application

The following commands will print the endpoint at which the application can be accessed (assuming use of the default namespace and the user having appropriate permissions):
```
export NODE_PORT=$(kubectl get -o jsonpath="{.spec.ports[0].nodePort}" services vtm-services)
export NODE_IP=$(kubectl get nodes -o jsonpath="{.items[0].status.addresses[0].address}")
echo http://$NODE_IP:$NODE_PORT
```

Documentation
===

Deploying a Traffic Manager
---
The ```vtm-kubernetes-foundation.yaml``` file contains a set of manifests for deploying a traffic manager into a Kubernetes cluster. Its component pieces are:

### Empty ConfigMaps for Configuration
Two empty ConfigMap objects are defined: ```vtm-config``` and ```vtm-extra-data```. These are placeholders for storing configuration documents and reference data respectively.

You can edit these placeholder ConfigMaps inline in your copy of the ```vtm-kubernetes-foundation.yaml``` manifest, or write separate manifest files that update the content of these ConfigMaps as shown in the ```vtm-example-service.yaml``` example.

Additional configuration documents and data can be mounted into the traffic manager pod when it is deployed. See [Configuring the Traffic Manager](#configuring) for more details.

### ConfigMaps for Base Kubernetes Configuration
Some base configuration for running the traffic manager in a Kubernetes cluster is supplied as part of the foundation YAML file. This configuration disables some functionality, such as front-end health checks, that isn't typically required in Kubernetes deployments. The base configuration can be augmented or removed as required to support the deployment environment.

### Service for Administrative Interfaces
A NodePort Service definition exposes the traffic manager's Administration GUI and REST API outside the cluster. See [Accessing the Administration GUI](#gui) for more details.

### Deployment for the Traffic Manager
The final manifest in the foundation YAML file is a Deployment for the traffic manager itself. The deployment manifest exposes the administrative ports, sets some environment variables for performing the initial configuration of the traffic manager and mounts configuration for the traffic manager through a set of projected volumes.

Additional ConfigMap or Secret objects can be added to the projected volumes here if necessary, for example to store certificates or passwords.

See [Configuring the Traffic Manager](#configuring) for more details on how to provide the traffic manager with service configuration.

The deployment defines a single replica for the traffic manager, which can be increased to deploy multiple copies of the traffic manager that all share the same configuration.

**Note:** Traffic manager replicas are *not* joined together as part of a cluster, and so will not share state information such as session persistence records.


<a name="configuring" id="configuring"></a>Configuring the Traffic Manager
---

### Using Configuration Documents and the Configuration Importer
In the ```vtm-kubernetes-foundation.yaml``` manifest, traffic manager configuration is controlled through **configuration documents**.  

Configuration documents express traffic manager configuration in either JSON or YAML format, and their structure is based upon the traffic manager's REST API schema. They are processed by the Configuration Importer tool, which is included with the traffic manager from 18.3 onwards.

For full information on the structure of configuration documents, and guidance on how to construct and use them, see the [Pulse Secure Virtual Traffic Manager Configuration Importer Guide](https://www.pulsesecure.net/techpubs/Pulse-vADC-Solutions/Pulse-Virtual-Traffic-Manager/18.3).

### Placing Configuration into ConfigMaps and Secrets
Configuration documents are placed into Kubernetes ConfigMaps (and, optionally, Secrets), and those objects are then mapped into the Traffic Manager container's filesystem so that the Configuration Importer tool can read them.

The ```vtm-example-service.yaml``` manifest file defines two ConfigMap objects: 'vtm-config' and 'vtm-extra-data'. Because these ConfigMap objects are mapped into the traffic manager container, the traffic manager will automatically update its configuration to reflect any changes to them.

In the 'vtm-config' ConfigMap, each map-value represents a traffic manager configuration document. 

The 'vtm-extra-data' ConfigMap contains additional map-values with arbitrarily formatted data. Configuration documents in the 'vtm-config' ConfigMap can fetch and include data from this ConfigMap by using a 'valueFrom' reference. See [Object References](#object-references) for more detail.

Additional ConfigMap and Secret objects can be created and mapped into the traffic manager containers and their content referenced in the configuration documents.

### Load-balancing Over Pods
The traffic manager can automatically discover and load-balance across the Endpoints for a *headless service* using the 'BuiltIn-DNS_Stateless' Service Discovery plugin.

To create a headless service for your application, create a Service object for it that has the ```.spec.clusterIP``` parameter set to ```None```.

The example application defined in ```example-application.yaml``` deploys a basic nginx web-server fronted by a headless service. The example configuration defined in ```vtm-example-service.yaml``` load-balances over this application by configuring a pool that uses the BuiltIn-DNS_Stateless Service Discovery plugin to discover the application's Endpoints.

To swap the example application for your own, edit the ```vtm-example-service.yaml``` file and, in the value for the 'plugin_args' key, replace ```example-application-backend-service``` with the name of a headless Service object that matches your own application.

The configuration can be deployed by running `kubectl apply -f vtm-example-service.yaml` - this will update the empty ConfigMaps defined in ```vtm-kubernetes-foundation.yaml``` with the configuration specified in the file being deployed. The configuration files will appear on the traffic manager's filesystem and the traffic manager will automatically apply the new configuration.

**Note:** Configuration changes can take up to a minute to propagate from the ConfigMap to the traffic manager containers.

### Checking the Configuration was Imported Successfully
To check whether the configuration was imported successfully, look at the log output of the traffic manager pod:

```
$ kubectl logs pod/$(kubectl get pods -l "app=vtm" -o jsonpath="{.items[0].metadata.name}")

...
Creating /usr/local/zeus/zxtm/conf_A/rules/internal_healthcheck
Creating /usr/local/zeus/zxtm/conf_A/vservers/healthcheck
Creating /usr/local/zeus/zxtm/conf_A/pools/example-pool
Creating /usr/local/zeus/zxtm/conf_A/rules/Response-Headers
Creating /usr/local/zeus/zxtm/conf_A/vservers/example-service
Set 'conf_A' as the active configuration
```

If there are syntax errors in the configuration document, the importer will detect them and report an error in the container logs without changing the traffic manager's configuration.

Otherwise the importer will apply the configuration changes to the traffic manager. If the configuration contains logical, semantic, or situational errors that the traffic manager detects, these are reported to the container logs and are also visible through the traffic manager's Administration GUI or REST API.

<a name="object-references" id="object-references"></a>

### Object References
The ```vtm-example-service.yaml``` manifest file shows an example configuration document that fetches and includes values from another source. A TrafficScript rule named 'simple-rule' is created in the 'vtm-extra-data' ConfigMap, which is then referenced in the 'rules' section of the configuration document in the 'vtm-config' ConfigMap.

This approach of storing values as plain data and fetching and including them upon import can be useful when:
* The values need to be handled differently to the rest of the configuration, and only combined at import time. For example, passwords can be stored in a separate system and then pulled into the configuration at import time so they do not need to be stored as literals in your configuration documents.
* The values are dynamic, or have an external source - placing a static copy of the value into a configuration document might not be functional or appropriate. For example, a list of e-mail addresses to which alerts should be sent could be maintained in a separate ConfigMap value.

Another common use of object references is to pull TLS certificates and private keys stored in Secret objects into the traffic manager's configuration. To do so, first mount the Secret object into the container by creating a volume from the Secret and then mapping it into the traffic manager container under the ```/import``` directory:
```
volumes:
- name: example-service-tls
  secret:
    secretName: example-service-tls-secret
```
```
volumeMounts:
- name: example-service-tls
  mountPath: /import/tls/example-service
```
Kubernetes will mount the key and certificate as tls.key and tls.crt, which can then be referenced in the configuration document as follows:
```
virtual_servers:
- name: example-service
  properties:
    basic:
      enabled: true
      port: 443
      protocol: http
      pool: example-pool
      ssl_decrypt: true
    ssl:
      server_cert_default: example-service-cert

ssl:
  server_keys:
  - name: example-service-cert
    properties:
      basic:
        public:
          valueFrom:
            fileRef:
              name: tls/example-service/tls.crt
        private:
          valueFrom:
            fileRef:
              name: tls/example-service/tls.key
```


<a name="service" id="service"></a>Exposing the Service
---

The traffic manager configuration in ```vtm-example-service.yaml``` creates a virtual server that listens on port 80 and load-balances over the endpoints for the application's headless service. There are a few different mechanisms that can be employed to expose that service to clients connecting from outside the Kubernetes cluster.

### NodePort Service
The ```vtm-example-service.yaml``` manifest defines a NodePort service named ```vtm-services``` that maps a port on the host machine to the virtual server hosted by the traffic manager.

To find out the port on which the service is listening on the host machine, run `kubectl get services` and look for the port mapping for port 80 in the ```vtm-services``` service. You can access the application through that port on any Kubernetes node.

### LoadBalancer Service
If your Kubernetes host provides a load-balancing service then a Service of type LoadBalancer can be created to provide access to the traffic managers from outside the cluster. For on-premises (or 'bare-metal') deployments, a tool such as MetalLB can be deployed to provide the load-balancing service.

### Host Networking
Alternatively, the traffic manager can listen on the host machine itself and receive incoming traffic directly, rather than through a Service. See [Deploying in Host Networking Mode](#host) for more detail.

<a name="gui" id="gui"></a>Accessing the Administration GUI
---
The ```vtm-kubernetes-foundation.yaml``` manifest creates a service that exposes the Administration GUI and the REST API through a NodePort. Run `kubectl get services` and look for the port mapping for port 9090 in the ```vtm-admin-services``` service to find the port on which you can access the Administration GUI.

If you have set the number of replicas to be greater than 1 then the service will apply IP-based persistence to ensure that you consistently communicate with the same traffic manager instance.

The admin password for the traffic manager is automatically generated when the pod starts up, and can be viewed through the container logs:
```
$ kubectl logs pod/$(kubectl get pods -l "app=vtm" -o jsonpath="{.items[0].metadata.name}") | grep password

INFO: Generated random password for vTM: <password>
```
To set a pre-defined password when deploying a pod, add the ZEUS_PASS environment variable to the pod specification. If necessary, the password can be retrieved from a Secret object as follows:
```
env:
- name: ZEUS_PASS
  valueFrom:
    secretKeyRef:
      name: vtm-admin-login-credentials
      key: vtm-admin-password
```

Note that configuration changes made through the Administration GUI or the REST API will be applied only to the local traffic manager instance and will not automatically propagate to other replicas. To have configuration applied to all traffic managers in the set, changes should be made through the ConfigMap objects.

Deploying a Traffic Manager with Configuration
---
The quickstart section above showed how to deploy the traffic manager using the ```vtm-kubernetes-foundation.yaml``` file and then deploy its configuration separately using the ```vtm-example-service.yaml``` file. To deploy the configuration at the same time as the traffic manager, the ConfigMap objects at the top of the ```vtm-kubernetes-foundation.yaml``` file can be replaced with those defined in the ```vtm-example-service.yaml``` file and the traffic manager will pick up the configuration as soon as it starts.

<a name="host" id="host"></a>Deploying in Host Networking Mode
---
The ```vtm-kubernetes-foundation.yaml``` manifest deploys a traffic manager as a standard Kubernetes pod on the Kubernetes overlay network. Any services hosted by the traffic manager must be exposed outside the cluster using a Service, as described in [Exposing the Service](#service).

An alternative deployment model is to provide the traffic manager pod with host network privileges so it can listen on the host node's IP addresses and raise and lower its own IP addresses. When deployed this way, Traffic IP addresses can be configured and clients can access virtual servers hosted by the traffic manager directly, without needing to go through a NodePort service.

This deployment model is useful for on-premises clusters that don't have an established ingress mechanism.

A host networking deployment manifest for the traffic manager is provided in ```vtm-kubernetes-foundation-host-networking.yaml```. The example configuration in ```vtm-example-service.yaml``` can be applied to host the example back-end application; users can then access the application through the kubernetes node hosting the traffic manager directly on port 80. The Service object defined in ```vtm-example-service.yaml``` is no longer required.
