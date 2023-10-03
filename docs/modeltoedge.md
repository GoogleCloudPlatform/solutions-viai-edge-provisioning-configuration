# Visual Inspection AI Edge Solution

# Exporting the model to the edge server

<br>

After you export the model container, the next step is to deploy the model container to the edge server.

If this is the first time you use the solution, we suggest you to manually deploy the model container to get you familiar with what technologies and components are behind the scenes.

There are other [automatic deployment options](./automaticdeployment.md) available, you can set up [Anthos Config Sync](./anthosconfigsync.md) or [Cloud Deploy](./clouddeploy.md).

<br>

__Manual Deploy__

1. Clone this repo and switch to the working folder

```bash
cd ${VIAI_PROVISION_FOLDER}/setup/kubernetes/viai-model
```

2. Update `kubernetes/viai-model/viai-model.yaml.tmpl` with the model container URI from the [previous section](./exportmodel.md)

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
    name: ${SERVICE_NAME}-deployment
    namespace: viai-edge
    labels:
        gcp-managed-by: ${SERVICE_NAME}
    annotations:
        mledge-deployment: ${SERVICE_NAME}
spec:
    selector:
        matchLabels:
        app: ${SERVICE_NAME}
    template:
        metadata:
        labels:
            app: ${SERVICE_NAME}
        spec:
        imagePullSecrets:
            - name: regcred
        containers:
        - image: <your-model-container-uri>
            imagePullPolicy: Always
            name: viai-inference-module
            ports:
            - containerPort: 8602
---
...
```

Where:

* `viai-inference-module` should be replaced with the model container URI
* `SERVICE_NAME` is the name of your VIAI ML model

3. Connect to the Anthos Bare Metal cluster

```bash
gcloud container hub memberships get-credentials ${MEMBERSHIP}
```

Where:

* `MEMBERSHIP` was defined in the previous sections and contains the name of the ABM cluster where you want to deploy the model container.

The output should be similar to this:

```
A new kubeconfig entry "connectgateway_project_id_global_anthos-server-xyz" has been generated and set as the current context.
```

4. Deploy the model 

```bash
kubectl apply -f ./viai-model.yaml
```

5. Check that the deployment pods are being started in the edge server

If haven't done before, export the namespace (default is `viai-edge`)
```bash
export NAMESPACE=<your namespace>

kubectl get pods -n $NAMESPACE
```

When the deployment pod is being deployed, it will appear in the output like this:

```
mledge-deployment-7bf7889c8f-bqxld                    1/1     Running     1 (1m ago)   2m
```

6. Check that all the deployments are ready

```bash
kubectl get deployments -n $NAMESPACE
```

The output should be similar to:

```
NAME                    READY   UP-TO-DATE   AVAILABLE   AGE
mosquitto               1/1     1            1           45h
viai-model-deployment   1/1     1            1           40m
```

7. Check that the inference service is present

```bash
kubectl get service viai-model -n $NAMESPACE
```

The output should be similar to:

```
NAME         TYPE           CLUSTER-IP       EXTERNAL-IP   PORT(S)          AGE
viai-model   ClusterIP      10.152.183.175   <none>        8602/TCP         38m
```

Where:

* `CLUSTER-IP` is the IP address at which the Pod is listening to.
* `PORT(S)`  is the main inference serving port

Take note of these values, since you'll need them later. This is the address where the ML model service is available.

8. Export the inference URL to an environment variabla

```bash
export INFERENCE_URL="http://$(kubectl get services viai-model -n $NAMESPACE -o jsonpath='{.spec.clusterIP}'):8602/v1/visualInspection:predict"
```

9. Test the model by sending one of your training images taken with earlier to the service.

Replace `image.png` with the full path to a test image

```bash
curl $INFERENCE_URL -X POST -d "{\"image_bytes\": \"$(base64 -w0 image.png)\"}"
```

If successful, the model should return a JSON output similar to the following.

```
{"predictionResult":{"annotationsGroups":[{"annotationSet":{"name":"projects/199334883686/locations/us-central1/datasets/1648497783524556800/annotationSets/5668840060254945280","displayName":"Predicted Classification Labels","classificationLabel":{},"createTime":"2022-02-04T16:23:34.994263Z","updateTime":"2022-02-04T16:23:35.058343Z"},"annotations":[{"name":"localAnnotations/0","annotationSpecId":"1583825059334586368","annotationSetId":"5668840060254945280","classificationLabel":{"confidenceScore":0.0598243},"source":{"type":"MACHINE_PRODUCED","sourceModel":"projects/199334883686/locations/us-central1/solutions/5917483619760209920/modules/463272627293650944/models/8522710451077775360"}}]}]},"predictionLatency":"0.125581514s"}
```

This inference result is for an Anomaly classification model, with a ‘faulty/abnormal object’ score of 0.06 for the image sent to the model. The inference latency was 0.13ms.

<br>

__Congratulations!!__

You have successfuly deployed your ML model and the VIAI Edge solution is ready to use.


<br>

At this point the ML model has been deployed successfuly to the edge server. You can continue to the next section to check [different ways to use the VIAI Edge solution](./useviai.md)



<br>

___

<table width="100%">
<tr><td><a href="./useviai.md">Use the VIAI Edge solution >>></td></tr>
</table>




