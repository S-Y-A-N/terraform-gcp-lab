terraform {
  backend "gcs" {
    bucket = "acai-2026-tfstate"
    prefix = "tf-lab/state"
  }
}