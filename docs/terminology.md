# Terminology

The following terms are important for understanding how to design and implement a migration
plan for a Cloud IoT Core-based environment:

* __Edge server.__ A server that you deploy at the [edges of your environment](https://www.lfedge.org/2020/08/18/breaking-down-the-edge-continuum/) that is running the Visual Inspection AI Camera applications to capture photos, invoke machine learning
models, fetch inference results and send results to the backend.

* __Cloud Resources.__ Services that run in the Google Cloud platform to receive inference
results, storing results, developing machine learning models and deploy the
containerized models to the edge server.

* __Visual Inspection AI edge applications.__ Applications that are running on the edge
server, this includes the camera application that connects to the camera, captures
photos and gets machine learning model inference results from a machine learning
model. And the Visual Inspection AI machine learning models which are packed as a
container image and running on the edge server.

* [__Visual Inspection AI Service.__](https://cloud.google.com/solutions/visual-inspection-ai) A Google Cloud service hosted, managed and operated
by Google Cloud Platform. You use the service to train your Visual Inspection AI models.

* __Target edge environment.__ The physical location where your edge server will be
deployed.

</br>

___


<table width="100%">
<tr><td><a href="./README.md">^^^ Home </td><td><a href="./prerequisites.md">Pre-requisites >>></td></tr>
</table>
