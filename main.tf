# resource "google_storage_bucket" "data_bucket" {
#   name          = var.bucket_name
#   location      = var.region
#   project       = var.project_id
#   force_destroy = true
#
#   uniform_bucket_level_access = true
#
#   lifecycle_rule {
#     condition {
#       age = 30
#     }
#     action {
#       type = "Delete"
#     }
#   }
# }


resource "google_pubsub_topic" "topic" {
  name = var.topic_name
  project = var.project_id
}

resource "google_pubsub_topic" "dead_letter_topic" {
  name = "orders-dead-letter-topic"
  project = var.project_id
}

data "google_project" "project" {
  project_id = "project-e85d8801-bd70-4ddd-8bc"
}

resource "google_pubsub_topic_iam_member" "dead_letter_publisher" {
  topic = google_pubsub_topic.dead_letter_topic.name
  role  = "roles/pubsub.publisher"
  project = var.project_id

  member = "serviceAccount:service-${data.google_project.project.number}@gcp-sa-pubsub.iam.gserviceaccount.com"
}

resource "google_pubsub_subscription" "subscription" {
  name  = var.subscription_name
  topic = google_pubsub_topic.topic.name
  project = var.project_id

  ack_deadline_seconds = 20

  message_retention_duration = "604800s" # 7 days

  retain_acked_messages = true

  dead_letter_policy {
    dead_letter_topic     = google_pubsub_topic.dead_letter_topic.id
    max_delivery_attempts = 5
  }

  retry_policy {
    minimum_backoff = "10s"
    maximum_backoff = "600s"
  }
}

## the below sub
resource "google_pubsub_subscription" "main_subscription" {
  name  = "orders-subscription"
  topic = google_pubsub_topic.topic.name
  project = var.project_id

  ack_deadline_seconds = 20

  message_retention_duration = "604800s"

  dead_letter_policy {
    dead_letter_topic     = google_pubsub_topic.dead_letter_topic.id
    max_delivery_attempts = 5
  }

  retry_policy {
    minimum_backoff = "10s"
    maximum_backoff = "600s"
  }
}
# resource "google_dataflow_flex_template_job" "dataflow_job" {
#   provider = google-beta   # 👈 IMPORTANT
#   project  = var.project_id
#
#   name                    = "pubsub-to-gcs-job"
#   region                  = var.region
#   container_spec_gcs_path = "gs://dataflow-templates/latest/flex/Cloud_PubSub_to_GCS_Text"
#
#   parameters = {
#     inputSubscription = google_pubsub_subscription.subscription.id
#     outputDirectory   = "gs://${google_storage_bucket.data_bucket.name}/output"
#   }
#
#   on_delete = "cancel"
# }

# resource "google_dataflow_job" "dataflow_job" {
#   provider = google-beta   # 👈 IMPORTANT
#   project  = var.project_id
#   max_workers = 1
#   region = "us-central1"
#   name              = "pubsub-to-gcs-job"
#   template_gcs_path = "gs://dataflow-templates/latest/Cloud_PubSub_to_GCS_Text"
#
#   temp_gcs_location = "gs://${google_storage_bucket.data_bucket.name}/temp"
#
#   parameters = {
#     inputTopic           = google_pubsub_topic.topic.id
#     outputFilenamePrefix = "gs://${google_storage_bucket.data_bucket.name}/output"
#     outputDirectory      = "gs://${google_storage_bucket.data_bucket.name}/output"
#   }
# }