Add new Kubernetes runtime
===

1. Create a new folder with Kubernetes runtime name under `edge-server` folder, for example, `k3s`.


2. Create at least four `.sh` files in the newly created folder.


- `generate-script.sh`

    This script updates `node-setup.sh.tmpl` and copy updated template files to the output folder and renames it to .sh, and generate scripts to invoke `attach-cluster.sh`

- attach-cluster.sh

This script attaches the Kubernetes cluster to Anthos and assigned required Kubernetes roles to service accounts and user accounts.

- `deploy-app.sh`

This script deploys Visual Inspection AI edge applications to the Kuberbetes cluster.

- `node-set.tmpl`

A template script file to set up the edge server, including install dependencies. If the Kubernetes runtime is `anthos`, this script create Anthos Bare Metal cluster.

It does not takes any arguments.
