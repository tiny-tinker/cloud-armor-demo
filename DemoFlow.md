# Demo Flow

## Pre-requisites

1. Set the `my-security-policy` to Preview. [Here](https://console.cloud.google.com/net-security/securitypolicies/details/my-security-policy)
2. Delete the rules in `my-security-policy` except the "Deny access to IPs in xx.xx.xx.xx/32" and default rule.


## Runtime

### Bad Actor VM

1. Show the app on the LB url.
2. Show the LB, serverless NEG and appengine pieces.
2. In a terminal run this to show the "bad-actor" VM can successfully make calls

```shell

export BAD_VM=`terraform output -raw bad_actor_vm`
export BAD_ZONE=`terraform output -raw bad_zone`
export NUM_REQUESTS=1000

gcloud compute ssh $BAD_VM --zone $BAD_ZONE << EOF
for i in {1..$NUM_REQUESTS}
do 
    curl -s -o /dev/null -w "%{http_code}" $APP_URL
    echo
    sleep 1 
done
EOF
```

3. Show the logs with the logged entries. Look for `previewSecurityPolicy`
4. Set the rule to disable preview... and move on. Keep the terminal running in the background


# Preconfigured Rules

1. Show the list of pre-configured rules: https://cloud.google.com/armor/docs/waf-rules
2. Show again via command line and then add a new one.
```bash

gcloud compute security-policies list-preconfigured-expression-sets


gcloud compute security-policies rules create 9003 \
    --security-policy my-security-policy  \
    --description "block protocol attacks" \
     --expression "evaluatePreconfiguredExpr('protocolattack-stable')" \
    --action deny-403

```


3. Back in the `my-security-policy`, add a new rule and walk through the fields. Show this page for reference: https://cloud.google.com/armor/docs/rules-language-reference



