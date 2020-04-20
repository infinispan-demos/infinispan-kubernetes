> These instructions are only valid for the Infinispan 9.4.x image which is no longer supported. The recommended way to consume Infinispan 10.x and beyond with Kubernetes is via the [Operator](https://github.com/infinispan/infinispan-operator). If direct use of the Infinispan image is required, instructions on how to form a cluster on Kubernetes are provided in the [image repository](https://github.com/infinispan/infinispan-images).

# Infinispan on Kubernetes

This repository demonstrates how to run Infinispan on a vanilla Kubernetes set up.

For quick local testing, [Minikube](https://kubernetes.io/docs/setup/minikube/) offers an easy way for running Kubernetes on your local environment.
This README file concentrates on showing how to run Infinispan on top of Minikube.


## Minikube

Firstly, install Minikube and `kubectl` as instructed [here](https://kubernetes.io/docs/tasks/tools/install-minikube/).

Once installed Minikube, you should create a profile before starting Minikube.
Profiles allow you to create and manage these isolated instances of Minikube.
Here's an example configuration with enough resources to run multiple applications and multiple Infinispan pods:

```bash
minikube config set profile infinispan-minikube
minikube config set cpus 4
minikube config set memory 8192
```

On top of this Minikube configuration, depending on your environment you'll need to set the correct `vm-driver`.

```bash
minikube config set vm-driver ...
```

You can verify the Minikube configuration by calling:

```bash
minikube config view
``` 

Next, start Minikube:

```bash
minikube start
```

Finally, add `kubectl` command line tool to the `PATH` of your shell.


## Infinispan

In this section you will learn how to spin a 3-node Infinispan Server cluster on Kubernetes.
You will also learn how to store and retrieve some data using the HTTP REST endpoint.

First, apply the Kubernetes descriptors provided in this repository:

```bash
kubectl apply -f .
```

Once all pods are ready, you should verify the 3-node cluster has formed correctly.
You can do so by looking at the logs of one of the Infinispan Server pods, or you can execute this:

```bash
kubectl exec -it infinispan-server-0 \
  -- /opt/jboss/infinispan-server/bin/ispn-cli.sh \
  --connect "/subsystem=datagrid-infinispan/cache-container=clustered:read-attribute(name=cluster-size)"
```

The operation should return the number of expected nodes in the cluster, which is 3.

Once the cluster has formed, let's run a test to store and retrieve some data via the HTTP REST endpoint.
By default Infinispan Sever endpoints are not accessible from outside Kubernetes.
External access can be enabled by setting up 
[Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/)
, but it's not mandatory to verify that Infinispan Server works as expected.
Instead, let's see how to store/retrieve data from inside Kubernetes:

Let's start by asking one of the nodes to store some data:

```bash
kubectl exec \
  -it infinispan-server-0 \
  -- curl -v -u test:changeme -H 'Content-type: text/plain' -d 'test' infinispan-server-http:8080/rest/default/stuff
```

Then, retrieve it via:

```bash
kubectl exec -it infinispan-server-0 \
  -- curl -v -u test:changeme infinispan-server-http:8080/rest/default/stuff
```

This concludes the short guide to running Infinispan on top of vanilla Kubernetes.
Please open an issue in this repository with any feedback or issues encountered. 


## Extras

This section contains extra information related this repository.


### Descriptor Files

In this section you'll find information about the Kubernetes files provided in this repository:


#### `rolebinding.yaml`

To form the cluster, Infinispan Server nodes query the Kubernetes API to find out about other nodes.
By default, this API is not accessible so before starting any clusters, access needs to be enabled.
This file gives the default user `view` role so that it can query the API.
Without this descriptor, each node would act independently and would not communicate with each other.

For reference, instead of applying this file, executing this command will have the same effect:

```bash
kubectl create rolebinding infinispan \
  --clusterrole=view \
  --user=default \
  --namespace=default \
  --group=system:serviceaccounts
```


#### `secret.yaml`

Sets up a secret that includes a username and password for accessing Infinispan via Hot Rod or HTTP REST endpoints.


#### `service-hotrod.yaml`

Exposes the Hot Rod port as a Kubernetes service.
This port enables data to be queried and stored using one of Infinispan's Hot Rod clients.
Client implementations are available in Java, C/C++, Node.js and others.


#### `service-http.yaml`

Exposes the HTTP REST port as a Kubernetes service.
This port enables data to be queried and stored the Infinispan's HTTP REST API.


#### `statefulset.yaml`

Wraps the Infinispan Server around a stateful set.
Amongst other details, it contains information such as:
number of replicas to start, container port mappings and liveness/readiness probe settings.


### Delete data

Individual key/value entries stored via the HTTP REST endpoint can easily be removed using:

```bash
kubectl exec -it infinispan-server-0 \
  -- curl -v -u test:changeme -X DELETE infinispan-server-http:8080/rest/default/stuff
``` 


### Delete Infinispan cluster

The cluster and role binding created above can be deleted by calling:

```bash
kubectl delete all -l application=infinispan-server
kubectl delete rolebinding --all
```


### Testing 

`test.sh` smoke test script is provided to quickly verify that the files provided in the repository work as expected.
