---
title: Train VIAI model
layout: default
nav_order: 2
parent: Model Preparation
---
# Training the ML model in VIAI

<br>

Once you have uploaded the `defect` and `normal` example images in GCS, you can
import them as a new Dataset in VIAI using the VIAI service console.

Please refer to the product documentation on how to create a dataset, import the images, train and evaluate new models:

* [Creating image anomaly detection models](https://cloud.google.com/visual-inspection-ai/docs/creating-image-anomaly-detection-models)
* [Creating assembly inspection models](https://cloud.google.com/visual-inspection-ai/docs/creating-assembly-inspection-models)
* [Creating cosmetic inspection models](https://cloud.google.com/visual-inspection-ai/docs/creating-cosmetic-inspection-models)

Optionally you can also [create an Import file](https://cloud.google.com/visual-inspection-ai/docs/import-file-format), to enable programmatic imports of new training images.

Once the ML model is ready, you can continue to the next section to [deploy your ML model to a registry]({% link preparing-model/exportmodel.md %})
