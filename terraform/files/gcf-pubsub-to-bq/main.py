# Copyright 2022 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the 'License');
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an 'AS IS' BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import base64
import json
import os

from google.cloud import bigquery


def pubsub_bigquery_inference_results(event, context):
    """Triggered from a message on a Cloud Pub/Sub topic.
    Args:
        event (dict): Event payload.
        context (google.cloud.functions.Context): Metadata for the event.
    """
    project_id = os.environ.get("GCP_PROJECT")
    bigquery_dataset = os.environ.get("BIGQUERY_DATASET")
    bigquery_table = os.environ.get("BIGQUERY_TABLE")
    if not project_id or not bigquery_dataset or not bigquery_table:
        print("Error reading Function environment variables")
        return
    client = bigquery.Client(project=project_id)
    table_ref = client.dataset(bigquery_dataset).table(bigquery_table)
    table = client.get_table(table_ref)
    pubsub_data = base64.b64decode(event["data"]).decode("utf-8")
    print("Data JSON: {}".format(pubsub_data))
    d = json.loads(pubsub_data)
    rows_to_insert = [
        (
            d.get("device_id"),
            d.get("ts"),
            d.get("file_id"),
            json.dumps(d.get("results")),
        )
    ]
    print("BQ Row: {}".format(rows_to_insert))
    errors = client.insert_rows(table, rows_to_insert)
    try:
        assert errors == []
    except AssertionError:
        print("BigQuery insert_rows error: {}".format(errors))
    return
