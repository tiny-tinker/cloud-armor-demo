# GLB Demo

For Cloud Armor and stuff. Derived from [here](https://alwaysupalwayson.com/posts/2021/04/cloud-armor/) and some from [here](https://medium.com/contino-engineering/configuring-ddos-protection-with-google-cloud-armor-for-your-gke-provisioned-istio-ingressgateway-a9e862dc1683)


Really helpful doc also:
https://www.padok.fr/en/blog/https-istio-kubernetes

Good reading on LoadBalancer vs Ingress vs NodePort [here](https://medium.com/google-cloud/kubernetes-nodeport-vs-loadbalancer-vs-ingress-when-should-i-use-what-922f010849e0)



# Set up

Update these valuese as needed
```bash

gcloud config set project MYPROJECTHERE
gcloud config set compute/region us-central1
gcloud config set compute/zone us-central1-b

```


```bash
export TF_VAR_project=`gcloud config get-value project`
export TF_VAR_zone=`gcloud config get-value compute/zone`
export TF_VAR_region=`gcloud config get-value compute/region`
export REGION=`gcloud config get-value compute/region`
export ZONE=`gcloud config get-value compute/zone`
# export PROJECT_ID=`gcloud config get-value project`

terraform init
terraform plan -out tf.plan 
terraform apply tf.plan

export CLUSTER_NAME=`terraform output -raw cluster_name`
export SEC_POLICY=`terraform output -raw sec_policy`
```

From here, choose your own adventure. Super small, "Hello, World" or full blown Bookinfo. 

## Hello, World
Super small deployment of hello world based on [this](https://cloud.google.com/kubernetes-engine/docs/how-to/load-balance-ingress#using-gcloud-config) doc page.

```bash
# Just in case the credentials haven't been set
gcloud container clusters get-credentials $CLUSTER_NAME --region $REGION

kubectl create namespace hello

sed "s/%%SEC_POLICY%%/$SEC_POLICY/g" hello-world-deployment.yaml | \
kubectl apply -n hello -f -
```

## Bookinfo

Then, deploy the bookinfo app to our cluster: (Details from [here](https://istio.io/latest/docs/examples/bookinfo/))

https://istio.io/latest/docs/examples/microservices-istio/istio-ingress-gateway/


```bash
gcloud container clusters get-credentials $CLUSTER_NAME --region $REGION


kubectl apply -n istio-system -f health-vsvc.yaml


sed "s/%%SEC_POLICY%%/$SEC_POLICY/g" backendconfig.yaml | \
kubectl apply -n istio-system -f -

kubectl patch svc istio-ingressgateway -n istio-system --patch-file patch-ingressgateway.yaml

kubectl get events --watch -n istio-system

kubectl apply -n istio-system -f istio-ingress.yaml






kubectl apply -n gke-system -f istio-ingress.yaml

kubectl get ingress my-ingress -n gke-system --watch



kubectl create namespace bookinfo
kubectl label namespace bookinfo istio-injection=enabled
kubectl apply -n bookinfo -f bookinfo-manifest.yaml
kubectl apply -n bookinfo -f bookinfo-gateway.yaml


```


kubectl label namespace default istio-injection=enabled

kubectl apply -f kiali.yaml
kubectl rollout status deployment/kiali -n istio-system
istioctl dashboard kiali



kubectl rollout restart deploy -n bookinfo
kubectl rollout restart deploy -n istio-system

```bash
export INGRESS_HOST=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
export INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="http2")].port}')
export GATEWAY_URL=$INGRESS_HOST:$INGRESS_PORT

echo $INGRESS_HOST
echo $GATEWAY_URL

```






# Junk





If you don't have `istioctl` installed, see [here](https://istio.io/latest/docs/setup/install/istioctl/) for details. For mac `brew install istioctl` works great.)

Install istio to the cluster with the `demo` [profile](https://istio.io/latest/docs/setup/additional-setup/config-profiles/).
```bash
istioctl install --set profile=demo -y -n bookinfo
```


...


```bash

cat <<EOF > /tmp/backend-config.yaml
apiVersion: cloud.google.com/v1
kind: BackendConfig
metadata:
  name: ingress-backendconfig
spec:
  healthCheck:
    requestPath: /healthz/ready
    port: 15021
    type: HTTP
  securityPolicy:
    name: $SEC_POLICY
EOF
kubectl apply -f /tmp/backend-config.yaml

```


