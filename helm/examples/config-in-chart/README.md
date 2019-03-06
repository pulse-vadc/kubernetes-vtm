Pulse Secure Virtual Traffic Manager Helm Chart with Configuration Example
===

The following is an example of how to deploy a fully configured [Pulse Secure vTM](../../../) deployment into a Kubernetes cluster with a Helm chart. It is a variation on the [Basic Deployment example](../basic-deployment). You might wish to read the Basic Deployment example first, for the full sequence of installing vTM and using it to manage a service.

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
cd kubernetes-vtm/helm/examples/config-in-chart/
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


Steps
---
The following will deploy a traffic manager with the configuration defined in the [values.yaml](./values.yaml) file included with this example:

```
helm upgrade --install my-vtm-deployment --set eula=accept pulsesecure-vadc/vtm -f ./values.yaml
```

The traffic manager will be automatically configured to discover the application's endpoints from the headless service created above and a NodePort service will be created to receive traffic from outside the cluster.

Follow the instructions printed after the deployment has completed to access the service:
```sh
export NODE_IP=$(kubectl get nodes -o jsonpath="{.items[0].status.addresses[1].address}")
export SERVICE_PORT=$(kubectl get services -o jsonpath="{.spec.ports[0].nodePort}" my-vtm-deployment-data-my-application)

echo "Use $NODE_IP:$SERVICE_PORT to access the my-application service"
```

You should be able to see the extra header inserted by TrafficScript when fetching a page from the application:
```sh
$ curl -IXGET $NODE_IP:30080
HTTP/1.1 200 OK
Server: nginx/1.7.9
Content-Type: text/html
Accept-Ranges: bytes
ETag: "54999765-264"
Connection: keep-alive
Last-Modified: Tue, 23 Dec 2014 16:25:09 GMT
X-Powered-By: Pulse Secure vTM deployed by Helm
Content-Length: 612
```