# Deployment

## Provisioning the Google Cloud backend
<br>

__Creating a Google Cloud project__
<br>
1. [Create a Google Cloud project](https://cloud.google.com/resource-manager/docs/creating-managing-projects#creating_a_project) to provision the necessary resources into.
2. [Enable billing](https://cloud.google.com/billing/docs/how-to/modify-project#enable_billing_for_a_project) for the Google Cloud project.
3. Request access to the Visual Inspection AI service through your Google Cloud sales channels

<br>

__Provisioning resources in the Google Cloud project__
<br>

Before you provision cloud resources, you must take into account the Google Cloud resources locations.
At the time of writing this document, Visual Inspection AI is only available in us-central and
europe-west4 regions.

If you enable the `-x` flag, the script will provision a GCE
instance with T4 GPU, which is [not available in every GCP region](https://cloud.google.com/compute/docs/gpus/gpu-regions-zones).

Execute the following tasks:

1. Clone the VIAI Edge cloud project and switch to the source folder:

```bash
git clone https://github.com/GoogleCloudPlatform/solutions-viai-edge-provisioning-configuration
cd solutions-viai-edge-provisioning-configuration
mkdir tmp
export VIAI_PROVISIONING_FOLDER=$(pwd)
```

2. Initialize the environment variables

```bash
export DEFAULT_PROJECT=<your-project-id>
export DEFAULT_REGION=us-central1
export DEFAULT_ZONE=us-central1-a
export VIAI_STORAGE_BUCKET_LOCATION=US
export GOOGLE_CLOUD_DEFAULT_USER_EMAIL=<Your GCP Anthos Administrator email>
```

Where:
* `DEFAULT_PROJECT`: the ID of the Google Cloud project to provision the resources to deploy the solution.
* `DEFAULT_REGION`: the default region where to provision resources. Please see the [Supported Cloud Regions](./prerequisites.md#supported-cloud-regions-and-services) section for recommendations.
* `DEFAULT_ZONE`: the default [zone](https://cloud.google.com/compute/docs/regions-zones) where to provision the optional sandbox VM. A value for the zone has to be provided but the zone will only be used for the optional sandbox VM.
* `VIAI_STORAGE_BUCKET_LOCATION`: the location where to create the Cloud Storage buckets.
* `GOOGLE_CLOUD_DEFAULT_USER_EMAIL`: the user email of Anthos administrator. This user will be assigned required roles to configure the Anthos.

3. Ensure that you have the Docker daemon running

```bash
docker run hello-world
```

If the command finishes successfully, you can proceed with the next step. Otherwise, make sure you troubleshoot Docker before continuing.

4. Provision Google Cloud resources in your project.

```bash
scripts/provisioning-terraform.sh \
-a \
-g \
-l "${VIAI_STORAGE_BUCKET_LOCATION}" \
-p "${DEFAULT_PROJECT}" \
-r "${DEFAULT_REGION}" \
-z "${DEFAULT_ZONE}" \
-m "${GOOGLE_CLOUD_DEFAULT_USER_EMAIL}"
```

When prompted by Terraform, review the proposed changes and confirm by answering `yes`.

_Note:_ If you are demoing/testing the solution and you don't have physical servers where you will deploy the edge components, you can launch the script with the `-x` flag. The scrpit will create a sandbox VM on GCE with a T4 GPU attached that you will be able to use to demo/test the solution:

```bash
scripts/provisioning-terraform.sh \
-a \
-g \
-l "${VIAI_STORAGE_BUCKET_LOCATION}" \
-p "${DEFAULT_PROJECT}" \
-r "${DEFAULT_REGION}" \
-z "${DEFAULT_ZONE}" \
-m "${GOOGLE_CLOUD_DEFAULT_USER_EMAIL}"
-x
```

You can check the different flags used in the script by running

```bash
scripts/provisioning-terraform.sh -h
```

The `-g` flag  instructs the script to generate the `terraform.tfvars` file. You can optionally choose not to use the `-g` flag and create the file manually instead of letting the script generate it for you. The file should be in the following format:

```text
google_default_region = "${DEFAULT_REGION}"
google_default_zone = "${DEFAULT_ZONE}"
google_viai_project_id = "${DEFAILT_PROJECT}"
viai_storage_buckets_location = "EU | US | ASIA"
google_cloud_console_user_email = "someone@somedomain.com"
cloud_function_source_path = "<CLOUD FUNCTION SOURCE ZIP PATH>"
anthos_target_cluster_membership = [“ANTHOS MEMBERSHIP NAME 1", “ANTHOS MEMBERSHIP NAME 2"]
create_sandbox = "true | false"
```

Where:
* `google_default_region`: the default region where to provision resources
* `google_default_zone`: the default zone where to provision resources.
* `google_viai_project_id`: the ID of the Google Cloud project to provision the resources.
* `viai_storage_buckets_location`: the location where to create the Cloud Storage buckets.
* `google_cloud_console_user_email`: the user email of Anthos administrator. This user will be assigned required roles to configure the Anthos
* `cloud_function_source_path`: path to the zipped file with the Cloud Function source code.
    The source code can be found at `ssh://<your-email-address>@source.developers.google.com:2022/p/cloud-ce-shared-csr/r/MARKKU-viai-edge-camera-integration` branch: `main` by default. Cloud Function codes are in the `cf` folder.
* `anthos_target_cluster_membership`:
  * Anthos membership names, an array of strings. For example: `[“member1", “member2"]`. The membership names are names that will be registered to Anthos to identify your edge servers.
  * This variable can be set to `[]` if this is your first time running `provision-terraform.sh` and you only want to provision cloud resources and do not want to configure any edge servers related services at the moment.
* `create_sandbox`: `true` if you want to provision GCE VMs, otherwise `false`.

<br>

The Terraform script performs the following:

* Provisions cloud resources in the specified Google Cloud project, including:
  * Google Cloud resources [listed earlier](./prerequisites.md#supported-cloud-regions-and-services)
  * A GCE instance attached to a T4 GPU and VPC network if you choose to create a sandbox with the `-x` flag
  * Create and download two service account key files into the `${VIAI_PROVISIONING_FOLDER}/tmp` folder. They will be used in following configuration steps.

At this point the required Google Cloud services are provisioned and ready to use.

There are some optional customizations that you can do in your environment. You should be able to continue the instalation without any changes, but they are [documented here](./customizingapp.md) for your reference.


</br>

___

<table width="100%">
<tr><td><a href="./deployment.md">^^^ Deployment of the solution</td><td><a href="./createviai.md">Creating VIAI Assets >>></td></tr>
</table>


