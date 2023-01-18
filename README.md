# Cloud Armor Demo

This repo builds out an environment to demo Cloud Armor by deploying a GLB in front of a simple AppEngine service. 


# Set up

Update these valuese as needed
```bash

gcloud config set project MYPROJECTHERE
gcloud config set compute/region us-central1
gcloud config set compute/zone us-central1-b

```

Set some vars and apply the TF, then grab a couple output variables.

```bash
export TF_VAR_project=`gcloud config get-value project`
export TF_VAR_zone=`gcloud config get-value compute/zone`
export TF_VAR_region=`gcloud config get-value compute/region`
export REGION=`gcloud config get-value compute/region`
export ZONE=`gcloud config get-value compute/zone`
# export PROJECT_ID=`gcloud config get-value project`


# First, deploy the appengine service to make sure there is a service. 
# Could probably do in TF, but headaches. 

cd ./app/hello_world
gcloud app deploy
# Hit yes when it's done thinking


terraform init
terraform plan -out tf.plan 
terraform apply tf.plan


export SEC_POLICY=`terraform output -raw sec_policy`
export BAD_VM=`terraform output -raw bad_actor_vm`
export BAD_ZONE=`terraform output -raw bad_zone`
export APP_URL=`terraform output -raw app_url`
```



#TODO


# Generate Normal Traffic

Use the [global-loadgen](https://github.com/sadasystems/global-loadgen) repo to deploy CloudRun environments. 


# DDoS Yourself
These commands will ssh into the bad-actor vm and fire off a handful of requests. Since the external IP of this VM is in the Cloud Armor block list, these will result in `403`s returned.

```bash

#export APP_URL=INSERT_MY_URL_HERE

export BAD_VM=`terraform output -raw bad_actor_vm`
export BAD_ZONE=`terraform output -raw bad_zone`
export NUM_REQUESTS=1000

gcloud compute ssh $BAD_VM --zone $BAD_ZONE << EOF
for i in {1..$NUM_REQUESTS}
do 
    curl -o /dev/null -w "%{http_code}" $APP_URL
    echo
    sleep 1 
done
EOF

```



# Apply a Preconfigured Rule

```bash
# https://cloud.google.com/armor/docs/rules-language-reference


# Retrieve the pre-configured rules
# Some details: 
# https://cloud.google.com/armor/docs/rule-tuning

gcloud compute security-policies list-preconfigured-expression-sets


gcloud compute security-policies rules create 9003 \
    --security-policy my-security-policy  \
    --description "block protocol attacks" \
     --expression "evaluatePreconfiguredExpr('protocolattack-stable')" \
    --action deny-403

```



# Update the App Code

After making updates, zip the `hello_world` directory. 
(untested)
```bash

cd app/hello_world
rm hello_world.zip
zip -r hello_world.zip ./*

```

# Clean Up

```bash
terraform destroy

```

There is also a network endpoint group leakage. TODO: Add removal statement here. 
