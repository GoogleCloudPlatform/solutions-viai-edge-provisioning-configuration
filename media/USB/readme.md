Add new installation media type
===

1. Create a new folder with media type name under `media` folder, for example, `FTP`.


2. Create a folder of Kubernetes runtime under the newly created folder.


3. Create `generate-media-file.sh` under media folder.

    Below is a sample folder structure.

        media
        |
        └───FTP
            │
            └───generate-media-file.sh
            |
            └───Anthos
            │   └───file1.txt
            │   └───file2.txt
            └──microk8s
                └───file1.txt
                └───file2.txt

- `generate-media-file.sh`

    This script set up required installation media files. For example, if the media type is `USB`, the script copy `user-data.yaml` and `meta-data.yaml` to output folder and create an `.ISO` file.

    It takes the following arguments.

|  Argument   | Description  |
|  ----  | ----  |
| edge-config-directory-path  | Path that contains installation assets. |
| k8s-runtime | Kubernetes runtime, can be `anthos` or `microk8s`. |
