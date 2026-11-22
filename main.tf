# Robot identity Cloud Run can run as to restrict access.
resource "google_service_account" "app" {
  account_id   = "${var.service_name}-sa"
  display_name = "Runtime identity for ${var.service_name}"
}

# Secret container for "app-api-key"
# & Google chooses where copies are stored
resource "google_secret_manager_secret" "app" {
  secret_id = "app-api-key"

  replication {
    auto {}
  }
}

# Placeholder so Cloud Run has a version to point at.
# The real value is added outside Terraform (Step 5)
# Why? To not store secret_data as plaintext in the state file
resource "google_secret_manager_secret_version" "placeholder" {
  secret      = google_secret_manager_secret.app.id
  secret_data = "placeholder-replace-out-of-band"

  lifecycle {
    ignore_changes = [secret_data]
  }
}

# Restrict access of the identity created before.
# By giving it only the role of secretAccessor
resource "google_secret_manager_secret_iam_member" "app_access" {
  secret_id = google_secret_manager_secret.app.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.app.email}"
}

# Cloud Run service
resource "google_cloud_run_v2_service" "app" {
  name                = var.service_name
  location            = var.region
  deletion_protection = false

  template {
    service_account = google_service_account.app.email

    scaling {
      min_instance_count = 0
      max_instance_count = 3
    }

    containers {
      image = var.image

      env {
        name = "API_KEY"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.app.secret_id
            version = "latest"
          }
        }
      }
    }
  }

  depends_on = [
    google_secret_manager_secret_version.placeholder,
    google_secret_manager_secret_iam_member.app_access,
  ]

  # Cloud Run reports a service-level scaling block back with zeros.
  # Ignoring it keeps `terraform plan` clean.
  lifecycle {
    ignore_changes = [scaling]
  }
}

# Demo only: makes the URL publicly reachable.
# In production, don't use allUsers, put behind auth, load balabcer, api gateway
resource "google_cloud_run_v2_service_iam_member" "public" {
  name     = google_cloud_run_v2_service.app.name
  location = google_cloud_run_v2_service.app.location
  role     = "roles/run.invoker"
  member   = "allUsers"
}


resource "google_secret_manager_secret" "manual" {
  secret_id = "manual-secret"

  replication {
    auto {}
  }
}