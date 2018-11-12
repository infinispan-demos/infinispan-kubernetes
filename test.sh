#!/usr/bin/env bash

set -e

kubectl delete all -l application=infinispan-server
kubectl delete rolebinding --all

# Give view access so that nodes find each other to form a cluster
kubectl create rolebinding infinispan \
  --clusterrole=view \
  --user=default \
  --namespace=default \
  --group=system:serviceaccounts


kubectl apply -f .


EXPECTED_CLUSTER_SIZE=3
CLUSTER_SIZE_CMD="kubectl exec -it infinispan-server-0 -- /opt/jboss/infinispan-server/bin/ispn-cli.sh --connect"
CLUSTER_SIZE_MAIN="/subsystem=datagrid-infinispan/cache-container=clustered:read-attribute(name=cluster-size)"

function waitForClusterToForm()
{
  MEMBERS_MAIN=''
  while [ "$MEMBERS_MAIN" != \"$EXPECTED_CLUSTER_SIZE\" ];
  do
    MEMBERS_MAIN=$($CLUSTER_SIZE_CMD $CLUSTER_SIZE_MAIN | grep result | tr -d '\r' | awk '{print $3}')
    echo "Waiting for clusters to form (main: $MEMBERS_MAIN)"
    sleep 10
  done
}

waitForClusterToForm


printf "\n--> Store a key/value pair\n"
kubectl exec -it infinispan-server-0 \
  -- curl -v -u test:changeme -H 'Content-type: text/plain' -d 'test' infinispan-server-http:8080/rest/default/stuff


printf "\n--> Retrieve key\n"
kubectl exec -it infinispan-server-0 \
  -- curl -v -u test:changeme infinispan-server-http:8080/rest/default/stuff
