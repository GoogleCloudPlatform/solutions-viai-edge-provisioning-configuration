# Exporting the model to the edge server

<br>

After you export the model container, the next step is to deploy the model container to the edge server.

If this is the first time you use the solution, we suggest you to manually deploy the model container to get familiar with what technologies and components are behind the scenes.

There are other [automatic deployment options](./automaticdeployment.md) available, you can set up [Anthos Config Sync](./anthosconfigsync.md) or [Cloud Deploy](./clouddeploy.md).

<br>

__Manual Deploy__

1. In the _setup machine_ (your Linux or macOS), run the following commands to deploy the container with the model and an associated service.

You might have to declare again the `VIAI_PROVISION_FOLDER` enviroment variable, pointing at where the VIAI Edge repository was cloned.

Choose a name for your model, which will be used in the Kubernetes deployment and export it as `SERVICE NAME`.

```bash
cd ${VIAI_PROVISION_FOLDER}/kubernetes/viai-model
export SERVICE_NAME=<your model name>
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
        - image: viai-inference-module
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

* `MEMBERSHIP` was defined in the previous sections and contains the name of the ABM cluster where you want to deploy the model container. The default value is `anthos-server`.

The output should be similar to this:

```text
A new kubeconfig entry "connectgateway_project_id_global_anthos-server-xyz" has been generated and set as the current context.
```

4. Deploy the model

```bash
envsubst < ./viai-model.yaml.tmpl | kubectl apply -f -
```

5. Check that the deployment pods are being started in the edge server

If haven't done before, export the `NAMESPACE` variable (default value is `viai-edge`).

```bash
export NAMESPACE=<your namespace>

kubectl get pods -n $NAMESPACE
```

It might take a few minutes for the container to be pulled from the registry. When the deployment pod is ready, it will appear in the output like this:

```text
mledge-deployment-7bf7889c8f-bqxld                    1/1     Running     1 (1m ago)   2m
```

6. Check that all the deployments are ready

```bash
kubectl get deployments -n $NAMESPACE
```

The output should be similar to (the name of the deployment will be your `SERVICE_NAME`):

```text
NAME                    READY   UP-TO-DATE   AVAILABLE   AGE
mosquitto               1/1     1            1           45h
viai-model-deployment   1/1     1            1           40m
```

7. Check that the inference service is present

```bash
kubectl get service ${SERVICE_NAME} -n $NAMESPACE
```

The output should be similar to:

```text
NAME         TYPE           CLUSTER-IP       EXTERNAL-IP   PORT(S)          AGE
viai-model   ClusterIP      10.152.183.175   <none>        8602/TCP         38m
```

Where:

* `CLUSTER-IP` is the IP address at which the Pod is listening to.
* `PORT(S)`  is the main inference serving port

Take note of these values, since you'll need them later. This is the address where the ML model service is available.


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
