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


Bookinfo uses a VirtualService and a Gateway behind the Istio IngressGateway, so we have to do a few things to prep the environment. 
```bash
gcloud container clusters get-credentials $CLUSTER_NAME --region $REGION

# Deploy a service to acknowledge the health check request from Google
kubectl apply -n istio-system -f health-vsvc.yaml

# Associate the security policy deployed from TF with the BackendConfig
sed "s/%%SEC_POLICY%%/$SEC_POLICY/g" backendconfig.yaml | \
kubectl apply -n istio-system -f -

# The istio ingressgateway is a `LoadBalancer`, but we need it to be a `NodePort`, and we need to associate it to the BackendConfig above so that Cloud Armor gets roped into the picture.
# Don't be alarmed, this will remove the current Load Balancer (Frontend) in the GCP Console and we'll then deploy an Ingress later
kubectl patch svc istio-ingressgateway -n istio-system --patch-file patch-ingressgateway.yaml

# The patch will take a moment, so watch here for a bit.
kubectl get events --watch -n istio-system


# Now deploy an Ingress operator to build the Frontend and pass requests to the ingressgateway service. This will take some time too.
kubectl apply -n istio-system -f istio-ingress.yaml

# Deploy bookinfo into a new namespace
kubectl create namespace bookinfo
kubectl label namespace bookinfo istio-injection=enabled
kubectl apply -n bookinfo -f bookinfo-manifest.yaml
kubectl apply -n bookinfo -f bookinfo-gateway.yaml

# Get the external IP:
 kubectl get ingress -n istio-system


```



