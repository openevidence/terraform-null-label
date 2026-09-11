# `id` is join(delimiter, component *values* in label_order) and never contains
# component *names*, so renaming a component cannot change it. These hardcoded
# strings are the bytes v0.26.0 produced for the same values under the old
# `environment`/`location` names; any drift here is an id-assembly regression.

run "default_label_order" {
  variables {
    namespace    = "oe"
    stage        = "stg"
    short_region = "uc1"
    name         = "redis"
  }

  assert {
    condition     = output.id == "oe-stg-uc1-redis"
    error_message = "id changed: got ${output.id}, want oe-stg-uc1-redis"
  }

  assert {
    condition     = output.label_order == ["namespace", "stage", "short_region", "name", "attributes"]
    error_message = "default label_order changed: got ${join(",", output.label_order)}"
  }
}

run "prod_with_attributes" {
  variables {
    namespace    = "oe"
    stage        = "prod"
    short_region = "uc1"
    name         = "api"
    attributes   = ["blue"]
  }

  assert {
    condition     = output.id == "oe-prod-uc1-api-blue"
    error_message = "id changed: got ${output.id}, want oe-prod-uc1-api-blue"
  }
}

run "global_short_region" {
  variables {
    namespace    = "oe"
    stage        = "prod"
    short_region = "glb"
    name         = "dns"
  }

  assert {
    condition     = output.id == "oe-prod-glb-dns"
    error_message = "id changed: got ${output.id}, want oe-prod-glb-dns"
  }
}

# Shape used for GCP service account naming; a wrong id here renames live accounts.
run "custom_label_order" {
  variables {
    stage       = "prod"
    name        = "iac"
    attributes  = ["cd"]
    label_order = ["stage", "name", "attributes"]
  }

  assert {
    condition     = output.id == "prod-iac-cd"
    error_message = "id changed: got ${output.id}, want prod-iac-cd"
  }
}

run "lower_case_normalization" {
  variables {
    namespace        = "OE"
    stage            = "PROD"
    short_region     = "UC1"
    name             = "Redis"
    label_key_case   = "lower"
    label_value_case = "lower"
  }

  assert {
    condition     = output.id == "oe-prod-uc1-redis"
    error_message = "id changed: got ${output.id}, want oe-prod-uc1-redis"
  }

  # Tag keys derive from component names, so unlike `id` they DO change with the rename.
  assert {
    condition     = output.tags["stage"] == "prod" && output.tags["short_region"] == "uc1"
    error_message = "renamed components missing from generated tags"
  }
}

run "components_surface_under_new_names" {
  variables {
    namespace    = "oe"
    stage        = "stg"
    short_region = "uc1"
    name         = "redis"
  }

  assert {
    condition     = output.stage == "stg" && output.short_region == "uc1"
    error_message = "renamed outputs do not echo their inputs"
  }

  assert {
    condition     = output.context.stage == "stg" && output.context.short_region == "uc1"
    error_message = "context output does not carry the renamed keys"
  }

  assert {
    condition     = output.normalized_context.stage == "stg" && output.normalized_context.short_region == "uc1"
    error_message = "normalized_context does not carry the renamed keys"
  }
}
