---
title: Camera Integration Container
layout: default
nav_order: 5
parent: Troubleshooting
---
# Troubleshooting

## Troubleshooting camera integration container

<br>

To access the camera integration utility’s container, you can execute a container with a bash shell as the entry point.

This way you can access the container environment directly.

Run on Edge Server
{: .label .label-green}

```bash
kubectl exec -it viai-camera-integration -- /bin/bash
```

```text
Defaulted container "viai-genicam-sleep" out of: viai-genicam-sleep, viai-genicam (init)

    Mounts:
      /var/lib/viai/camera-config from viai-camera-config-volume (rw)
      /var/lib/viai/camera-data from viai-camera-data-volume (rw)
```

Note: Running the exit command brings you back to the host OS shell.
