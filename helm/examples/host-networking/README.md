Pulse Secure Virtual Traffic Manager Helm Chart Host Networking Example
===

The following is an example of how to use Helm to deploy a fully configured [Pulse Secure vTM](../../../) deployment into a Kubernetes cluster in host networking mode. It will serve a single application and will TLS-decrypt incoming traffic before proxying it to the application server. It is a variation on the [Basic Deployment example](../basic-deployment). You might wish to read the Basic Deployment example first, for the full sequence of installing vTM and using it to manage a service.

Prerequisites
---
The following example assumes you have already installed [Helm](https://helm.sh) and deployed its _tiller_ component into your Kubernetes cluster.

If you haven't already added the vTM Helm chart repository to your local Helm installation, do so now:

```sh
helm repo add pulsesecure-vadc/vtm https://pulse-vadc.github.io/kubernetes-vtm/charts/
```

You can also clone this repository to use the resources in the example:
```sh
git clone https://github.com/pulse-vadc/kubernetes-vtm.git
cd kubernetes-vtm/helm/examples/host-networking/
```

If you do not already have an application deployed in your Kubernetes cluster, you can deploy the sample application in the example directory:
```sh
kubectl apply -f ./example-application.yaml
```
If you do already have an application deployed, create a headless service to expose its endpoints to the traffic manager:
```yaml
apiVersion: v1
kind: Service
metadata:
  labels:
    app: my-application
  name: my-application-lb-service
spec:
  ports: # Adjust as necessary
  - name: http
    port: 80
    protocol: TCP
    targetPort: 80
  selector:
    # Replace with selector for your application
    app: my-application
  clusterIP: None
```

This example also uses credentials from a TLS Secret to decrypt the service. You can create a new self-signed certificate and store it in a secret for the purposes of this example as follows:
```sh
# Create credentials (prompts for information about the keys being created)
openssl req -newkey rsa:2048 -nodes -keyout my-application-key.pem -x509 -days 365 -out my-application-cert.pem
# Add the credentials to a TLS Secret
kubectl create secret tls my-application-secret --cert=my-application-cert.pem --key=my-application-key.pem
```

Steps
---
The following will deploy a traffic manager with the configuration defined in the ```values.yaml``` file included with this example, which includes a directive to deploy the traffic manager in host networking mode:

```
helm upgrade --install my-vtm-deployment --set eula=accept pulsesecure-vadc/vtm -f ./values.yaml
```

The traffic manager will be automatically configured to discover the application's endpoints from the headless service created above and a NodePort service will be created to receive traffic from outside the cluster.

The traffic manager will have been deployed on a specific node in the cluster - use the following to find out which one:
```sh
export NODE=$(kubectl get pod --selector=app.kubernetes.io/instance=my-vtm-deployment,app.kubernetes.io/name=vtm -o jsonpath="{.items[0].spec.nodeName}")
```

You should be able to see the extra header inserted by TrafficScript when fetching a page from the application:
```sh
$ curl -kIXGET https://$NODE
HTTP/2 200
server: nginx/1.7.9
content-type: text/html
accept-ranges: bytes
etag: "54999765-264"
last-modified: Tue, 23 Dec 2014 16:25:09 GMT
x-powered-by: Pulse Secure vTM
content-length: 612

```