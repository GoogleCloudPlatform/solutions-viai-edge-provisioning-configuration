# Troubleshooting

## Troubleshooting cloud resources provisioning

<br>

Error: `Error creating Trigger: googleapi: Error 400: Invalid resource state for "": Permission denied while using the Eventarc Service Agent.`

If you recently started to use Eventarc, it may take a few minutes before all necessary permissions are propagated to the Service Agent. Otherwise, verify that it has an Eventarc Service Agent role.

You might see this error when creating the Model Deployment Pipeline.
This is a temporary error message, please try creating the deployment pipeline again later.

---

Error: `Provider produced inconsistent result after apply`

When applying changes to google_project_iam_member.anthos-bare-metal-serviceAccountUser["roles/bigquery.dataEditor"], provider "provider[\"registry.terraform.io/hashicorp/google\"]" produced an unexpected new value: Root resource was present, but now absent.

This is a known issue with the Terraform provider, which should be reported in the provider's own issue tracker.

[Provider produced inconsistent results](https://support.hashicorp.com/hc/en-us/articles/1500006254562-Provider-Produced-Inconsistent-Results)
[GitHub issue](https://github.com/hashicorp/terraform-provider-google/issues/10193), [issue](https://github.com/hashicorp/terraform-provider-google/issues/10128)

If you see this error, please run the provisioning script again. The resources should be provisioned correctly.

---

Error: `The terraform.tfvars file already exists. Delete it before generating a new one. Terminating…`

If you specify the -g flag when running `provision-terraform.sh`, it will check if the `terraform.tfvars` file exists, and re-generate the `terraform.tfvars` file if it does not exist.. If this file exists, the script repost this error.

Delete the `terraform.tfvars` file and run the provisioning script again

---


Error: `Error when reading or editing Dataset: googleapi: Error 400: Dataset kalschi-20221101-001:viai_edge is still in use`

If you re-run the `provision-terraform.sh` script you may see this error. This error indicates that the BigQuery dataset already exists and there are tables in the dataset. Hence it’s unable to re-create the BigQuery dataset.

This is intentional to avoid accidentally deleting the BigQuery dataset that may contain critical data.

If you want to delete the BigQuery dataset everytime when run the `provision-terraform.sh`, add an option `delete_contents_on_destroy`  to the `bigquery.tf` file. Or delete the BigQuery dataset before running the Terraform script.



<br>
___

<table width="100%">
<tr><td><a href="./useviai.md">^^^ Using Visual Inspection AI Edge</td><td><a href="./troubleshootingabm.md">Troubleshooting Anthos Baremetal installation >>></td></tr>
</table>
