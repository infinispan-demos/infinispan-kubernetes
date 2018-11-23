# Helm Chart Preview

```bash
$ minikube config set profile infinispan-minikube
...

$ minikube start
$ helm init --upgrade

$ helm install --debug ./infinispan --set application.user=test --set application.password=changeme
```

Follow instructions shown to test.

```bash
$ helm list
...
$ helm delete <release_name>
```
