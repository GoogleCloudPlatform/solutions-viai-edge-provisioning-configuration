# Connecting the cameras

## Connecting Thermal cameras

<br>

In addition to standard visual cameras, this solution supports natively infrared thermal cameras from e.g [Teledyne FLIR](https://www.flir.com/).

Thermal/IR cameras contain an infrared bolometer sensor array.

For example, the FLIR AX5 camera has 640 sensor elements horizontally, and 512 vertically, producing a 640x512 imager array output. Each ‘pixel’ in the raw data contains radiometric information.

The recommended way to use this client is to set the cameras in ‘temperature linear’ mode. With that mode enabled, it is possible to calculate the radiometric temperature value per pixel. The raw data can be acquired in 8 or 14 bits’ dynamic range. By default, 14 bits will be used in order to get the most accurate data. The 14-bits raw data can then be converted to Kelvin, Fahrenheit or Celsius values for each pixel. To summarize, the raw data produced by the FLIR AX5 camera, as an example, is a 1-dimensional array, with 327,680 elements (640 x 512), with each element containing a 14-bit value (0 to 16383) which can be converted to K, F or C with a simple formula, for example in [BigQuery](https://cloud.google.com/bigquery).

The VIAI Edge client application has three data acquisition modes, selectable with the `--mode` switch: `none`, `single` and `continuous`
* `none` do not acquire any data. Used primarily to read or write camera configurations
* `single` when executed, the client connects to the camera, acquires the IR sensor array data once, and optionally processes the data according to command-line switches detailed below
* `continuous` the client runs in an eternal loop, acquiring new data and processing it until the client exits

<br>

__Acquiring IR raw data to generate binary files__

The VIAI Edge client application supports writing the raw 14-bit IR sensor values to a binary file. The binary file format consists of the following python construct fields:

```python
p = Struct(
        'device_id' / PascalString(VarInt, "utf-8"),
        'ts' / PascalString(VarInt, "utf-8"),
        'temp_format' / PascalString(VarInt, "utf-8"),
        'temp_avg' / Half,
        'temp_min' / Half,
        'temp_max' / Half,
        'temp_array' / GreedyRange(Short))
```

The file naming convention consists of the `device_id`, plus a datetime stamp (milliseconds since epoch) so that the camera, and the creation time of the file can be easily detected.

Each row in the binary file consists of one complete IR sensor temperature linear dump, with metadata such as the camera ID, timestamp, and pre-calculated avg, min and max temperature values in the desired format (C|F|K). This data can be then streamed via [Cloud Pub/Sub](https://cloud.google.com/pubsub) to other Google Cloud services (for example [BigQuery](https://cloud.google.com/bigquery)) for analysis or additional ML model training.

The client contains a python encoder function that can write the raw IR data to the binary file format and a python decoder that can be used to read the binary files and store the IR array raw data back in Python numpy arrays.

1. In the edge server, open a shell to the camera utility container

```bash
kubectl exec -it viai-camera-integration -- /bin/bash
```

2. To acquire one IR sensor array dump and write it to a binary file in the `/var/lib/viai/camera-data/` output folder, run:

```bash
python3 camera_client.py --protocol genicam --gentl /var/lib/viai/camera-config/<your-camera-gentl-file> \
    --cfg_write --cfg_write_file <your-camera-required-settings>.cfg --device_id <camera-id> --raw_write \
    --mode single --raw_write_path /var/lib/viai/camera-data/
```

3. Alternatively, to start continuous writing of sensor data to disk, execute the client in continuous mode, without any delay between the loops:

```bash
python3 camera_client.py --protocol genicam --gentl /var/lib/viai/camera-config/<your-camera-gentl-file> \
    --cfg_write --cfg_write_file <your-camera-required-settings>.cfg --device_id <camera-id> --raw_write \
    --raw_write_path /var/lib/viai/camera-data/ --mode continuous --sleep 0
```

You can change the destination directory with the `--raw_write_path` parameter.

<br>

__Acquiring IR raw data to generate image files__

The VIAI Edge client also supports generating images from the IR raw sensor array data.

You can output both raw binary files and images at the same time, if you enable both of the respective command-line switches.

IR images do not have any color. They contain a temperature brightness value for each pixel. Technically the most accurate way to represent this as an image is to turn the raw data into grayscale images, with the available temperature range mapped to the image’s dynamic range.

Such as this example:

![IR image example](./images/irimageexample.png)

To acquire a constant stream of data, and write it to 10 PNG files and then exit, run the following command:

```bash
python3 camera_client.py --protocol genicam --gentl /var/lib/viai/camera-config/<your-camera-gentl-file> \
    --cfg_write --cfg_write_file <your-camera-required-settings>.cfg --device_id <camera-id> --img_write \
    --img_write_path /var/lib/viai/camera-data/ --mode continuous --sleep 0 --count 10
```

With the IR camera set up, you can start to [Collect images for training](./collectimages.md) in the next section.

</br>

___

<table width="100%">
<tr><td><a href="./connectingcameras.md">^^^ Connecting cameras</td><td><a href="./collectimages.md">Collect images for training >>></td></tr>
</table>




