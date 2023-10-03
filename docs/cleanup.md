# Visual Inspection AI Edge Solution

# Cleaning up the Google Cloud Project

After testing the solution, you might want to clean up the cloud resources to avoid charges.

1. Using the Cloud Console, unregister the Anthos attached cluster in the Anthos console

2. Remove the rest of the cloud resorces, deployed for VIAI Edge

```bash
scripts/provisioning-terraform.sh -s "destroy"
```
