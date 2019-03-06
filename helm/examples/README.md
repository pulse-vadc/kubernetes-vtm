Pulse Secure Virtual Traffic Manager Helm Deployment Examples
===

The following examples show a few different ways of using Helm to deploy [Pulse Secure  vTM](../../) into a Kubernetes cluster and manage its configuration. The examples are intended to show how the Helm chart can support a variety of workflows and deployment scenarios.

It is recommended that you start with the Basic Deployment example for the full sequence of installing vTM and using it to manage a service. The later examples show variations that build upon it.

Basic Deployment
===
**Example:** [Basic Deployment](./basic-deployment)

**Overview:** Shows how to deploy vTM into Kubernetes, build up configuration for managing services and then persist the configuration either in ConfigMaps or in a values.yaml file that can be provided when deploying from the Helm chart.

Configuration in Chart
===
**Example:** [Configuration in Chart](./config-in-chart)

**Overview:** This example shows how to use some of the templating built into the chart to maintain service definitions in the values.yaml file used to deploy a traffic manager.

Host Networking
===
**Example:** [Host Networking](./host-networking)

**Overview:** Shows how to deploy a traffic manager in host networking mode so clients can access it directly without having to go through a Service resource. The example also illustrates how to configure TLS-decryption on a service, using credentials stored in a TLS Secret.