---
title: Deploy to Sandbox
layout: default
parent: Deploy to Server
grand_parent: Deployment
nav_order: 3
---
# Deployment

## Deploy the solution to a GCE sandbox machine

<br>

If you used the `-x` flag when you run the `provision-terraform.sh` script in the [previous step]({% link deployment/provisiongcp.md %}), Terraform will create a GCE virtual machine called `gce-server-anthos` with a T4 GPU attached to it, to be used as sandbox. This is useful for demos, where a physical server is not available.

You still need to manually setup Antos and install the Visual Inspection AI applications.

<br>

__Deploy Visual Inspection AI Edge solution to the GCE sandbox__

1. Prepare the files generated in the [previous step]({% link deployment/createviai.md %}).

    In the same machine where you run the `./scripts/0-generate-viai-application-assets.sh` script, run:

    ```bash
    cd ${OUTPUT_FOLDER}
    zip -r /tmp/viai.zip .
    cd -
    ```

2. SSH to the GCE instance using the Google Cloud Console

    ![ssh from cloud console]({% link images/sshscreenshot.png %})

3. Upload the ZIP file generated in step 1, use the top right button in the SSH window.

    ![ssh upload file]({% link images/sshuploadfile.png %})

4. On the SSH window connecte to the sandbox VM, run:

    ```bash
    sudo mkdir -p /var/lib/viai
    sudo cp -rf ${HOME}/viai.zip /var/lib/viai
    sudo su
    cd /var/lib/viai

    apt-get install unzip
    unzip viai.zip
    ```

5. Install Anthos Baremetal in the sandbox VM:

    ```bash
    bash edge-server/node-setup.sh
    ```

6. Install the required packages in the sandbox VM:

    ```bash
    bash scripts/0-setup-machine.sh
    ```

7. Deploy the Visual Inspection AI Edge application in the sandbox VM:

    ```bash
    bash scripts/1-deploy-app.sh
    ```

At this point the sandbox is ready, you can continue in the [Connecting the cameras]({% link connecting-cameras/connectingcameras.md %}) section.
