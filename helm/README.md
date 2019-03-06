Pulse Secure Virtual Traffic Manager Helm Chart
===

Pulse Secure Virtual Traffic Manager is an advanced Application Delivery Controller that can be deployed in a wide variety of environments, including Kubernetes clusters, to improve performance, security and reliability of applications deployed behind it.


About the Chart
===

The vTM Helm Chart allows you to manage deployments of, and, optionally, configuration for Pulse Secure Virtual Traffic Manager instances in Kubernetes using the [Helm](https://helm.sh) package manager.

The chart will:
* Deploy a scalable set of traffic manager instances as a Kubernetes Deployment
* Supply the deployed traffic manager instances with configuration that is maintained as part of the Helm Chart
* Create Service definitions to expose any virtual servers defined by the Helm Chart
* Create an empty ConfigMap into which traffic manager configuration managed outside the Helm Chart can be placed
* Expose Administration GUI and API endpoints as NodePort Services for diagnostic purposes
* Optionally deploy traffic manager instances in Host Networking mode so any services configured on it are accessible directly from the host node


Installing the Chart
===
These instructions assume you have installed the helm binary, and that Helm's 'tiller' component is running in your Kubernetes cluster.

It is recommended that you take a copy of the default [values.yaml](charts/vtm/values.yaml) file for the chart and use it as the basis for creating a values file for your own deployments.

```
helm repo add pulsesecure-vadc https://pulse-vadc.github.io/kubernetes-vtm/charts/
helm upgrade --install my-vtm-deployment --set eula=accept --wait -f my-values.yaml pulsesecure-vadc/vtm
```

Examples
===
The [examples](examples) folder contains some sample deployment scenarios that use the vTM Helm Chart.


Configuration Options
===

The [values.yaml](charts/vtm/values.yaml) file shows all the configuration options available for the chart, and describes their use.

Some select options are described in more detail below:

eula
--
You must accept the terms of Pulse Secure's End User License Agreement (EULA) to use the vTM software. To accept the EULA, set the `eula` parameter to `accept`. This can be set either from the commandline, by adding `--set eula=accept` to the `helm` command, or by adding it in a values file supplied when deploying from the chart.

The EULA can be viewed on the [Pulse Secure website](https://www.pulsesecure.net/support/eula).


staticServices
---
The ```staticServices``` option provides a convenient way of creating and exposing virtual servers when deploying the Helm Chart.

>The name of each `staticServices` entry is used as the name in the corresponding Service resource that is created, and is therefore restricted to the characters permitted in a DNS hostname. It must consist of lower case alphanumeric characters or '-', start with an alphabetic character, and end with an alphanumeric character and be no more than 15 characters.

`staticServices` is a set of key-value pairs mapping the name of the service to a set of parameters that define its basic properties and how it should be exposed:

| Property | Description |
| -------- | ----------- |
| virtualServerProtocol | The protocol of the virtual server. Valid values include: http, https, ftp, imaps, imapv2, imapv3, imapv4, pop3, pop3s, smtp, ldap, ldaps, telnet, sslforwarding, udpstreaming, udp, dns, genericserverfirst, genericclientfirst, dnstcp, sipudp, siptcp, rtsp, and stream
| tlsSecretName | To enable TLS-decryption on the virtual server, specify the name of a TLS Secret containing the certificate and private key to use for decrypting incoming traffic. |
| port | When running in Host Networking mode, specifies the port on which the service will listen. When not in Host Networking mode, the port can be omitted and the Helm Chart will automatically assign a container port that links the virtual server with the Service that exposes it. Such ports will be chosen based on the top-level ```basePort``` parameter. |
| frontend.* | Specifies the details of the Service port that should be used to expose the virtual server. Not applicable when running in Host Networking mode. |
| frontend.type | The type of the Service that exposes the virtual server. Defaults to NodePort if not specified. |
| backend | Specifies the name of the default pool for the virtual server, which can be defined in the 'pools' section of the values.yaml file, or `discard` if reverse-proxy functionality is not required. |

Additional configuration for the virtual servers created this way can be defined in configuration documents.

pools
---
The `pools` option provides a convenient way of creating traffic manager Pool objects that load-balance over applications deployed both inside and outside the Kubernetes cluster. Pools defined here will use the traffic manager's Service Discovery feature to discover the endpoints of the application.

The application endpoints can be discovered using one of two mechanisms:
* From a *headless service* resource deployed in the cluster (see [Load-balancing Over Application Pods](../README.md#lb) for more detail). To discover endpoints this way, specify the `serviceName`, `serviceNamespace`, `portName` and `portProtocol` parameters to the pool, as defined below. When configured this way, vTM will request a DNS SRV record for the service from the Kubernetes DNS server to discover the application endpoints.
* From a standard DNS A-record query that returns one or more IP addresses, combined with an explicit port number. To discover endpoints this way, use the `serviceName` and `port` parameters to the pool, as defined below. This service discovery mechanism can be necessary if your Kubernetes DNS server does not support SRV records, if the service exists outside the cluster, or if the name of the port is not known.

`pools` is a set of key-value pairs mapping the name of a pool to its properties:

| Property | Description |
| -------- | ----------- |
| serviceName | The name of the Kubernetes headless service that identifies the pods over which the traffic manager should load-balance. Or, used in conjunction with the `port` parameter, the hostname of the service supplied to the DNS A-record query used to discover its IP addresses. |
| serviceNamespace | The namespace in which the headless service is deployed. |
| portName | The name of the port, defined in the headless service, to which traffic should be sent. |
| portProtocol | The protocol of the port to which traffic should be sent. Defaults to 'tcp'. |
| port | If `port` is specified, nodes will be discovered using a standard DNS A-record query for the serviceName parameter and will use the specified port. |
| tls | Specifies whether traffic sent by the traffic manager should be encrypted. |
| monitors | A list of health monitors that should be used to actively assess the health of the pods. A number of health montiors are supplied with the traffic manager, and additional monitors can be specified in configuration documents. |



vtmConfig
---
The ```vtmConfig``` parameter can be used to provide any additional configuration for the traffic manager when it is deployed.

The parameter takes a vTM configuration document as a string. For full information on the structure of configuration documents, and guidance on how to construct them, see the [Pulse Secure Virtual Traffic Manager Configuration Importer Guide](https://www.pulsesecure.net/techpubs/Pulse-vADC-Solutions/Pulse-Virtual-Traffic-Manager).

Additional configuration for services defined in the staticServices and pools values can be supplied here.


serviceConfigMounts and serviceDataMounts
---
Additional configuration defined in pre-existing ConfigMaps and Secrets can be supplied to the deployed instances using the ```serviceConfigMounts``` and ```serviceDataMounts``` parameters.

Both of these parameters take list items with the following properties:

| Property | Description |
| -------- | ----------- |
| name | The name of the ConfigMap or Secret resource to mount into the traffic manager pods. |
| type | One of 'configMap' or 'secret', as appropriate. |
| items | Where only some fields from the resource should be mounted, specify these in the ```items``` property as a list of ```key``` and ```path``` properties. |

Fields in the ```serviceConfigMounts``` resources should contain traffic manager configuration documents. These can use 'valueFrom' references to reference data from the resources specified in ```serviceDataMounts```.

See the [basic deployment using ConfigMaps](examples/basic-deployment#configmaps) example for more detail.

Version Control
===
Helm chart values lend themselves to being maintained in version control systems. Cluster administrators can take the latest configuration parameters out of the version control system and use Helm to manage upgrades and rollbacks of the appropriate deployments.

There are other ways to use Helm for managing deployments, however. Rather than using Helm to deploy and configure traffic managers, it can be used just to generate the manifest files, which can be stored in a version control system and deployed directly into the Kubernetes cluster.

Alternatively, tools such as [Flux](https://github.com/weaveworks/flux) can be used to automatically deploy Helm charts with an associated set of values into Kubernetes clusters directly from a version control system.