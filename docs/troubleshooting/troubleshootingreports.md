---
title: Generate inspection reports
layout: default
nav_order: 1
parent: Troubleshooting
---
# Troubleshooting

## Generating inspection reports

<br>

To help you troubleshoot issues, you can generate inspection reports populated with details about the VIAI server.

You may be asked to generate such reports when asking for support.

On the edge server:

1. Generate the VIAI inspection report:

    ```bash
    cd /var/lib/viai
    scripts/generate-report.sh
    ```

2. Attach the `terraform/terraform.tfvars` file.

3. Attach relevant output from the command that failed.

4. If asked, attach both reports to the support request you created.
