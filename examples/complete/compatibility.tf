####
# These tests ensure that a context emitted by one instance of null-label is
# consumed by another instance without altering the resulting id or tags.
#
# This fork renames upstream's ID elements, so its `context` object is not
# interchangeable with upstream `cloudposse/label/null` contexts; only
# fork-to-fork round trips are tested here.
#
# Characters matching regex_replace_chars are removed from ID elements, so a
# delimiter that itself matches would be stripped out of the attributes portion
# of the id. These tests allow the delimiter in the labels to avoid that.

module "source_full" {
  source = "../.."

  enabled      = true
  namespace    = "CloudPosse"
  short_region = "UAT"
  stage        = "build"
  name         = "Winston Churchroom"
  delimiter    = "+"
  attributes   = ["fire", "water"]

  tags = {
    City        = "Dublin"
    Environment = "Private"
  }
  additional_tag_map = {
    propagate = true
  }
  label_order         = ["name", "short_region", "stage", "attributes"]
  regex_replace_chars = "/[^a-tv-zA-Z0-9+]/" # Eliminate "u" just to verify this is taking effect
  id_length_limit     = 28
}

module "source_recased" {
  source              = "../.."
  regex_replace_chars = "/[^a-tv-zA-Z0-9]/" # Eliminate "u" just to verify this is taking effect

  label_key_case   = "lower"
  label_value_case = "upper"

  context = module.source_full.context
}

module "source_empty" {
  source = "../.."

  stage = "STAGE"
}

module "roundtrip_full" {
  source  = "../.."
  context = module.source_full.context
}

module "roundtrip_recased" {
  source  = "../.."
  context = module.source_recased.context
}

module "roundtrip_empty" {
  source  = "../.."
  context = module.source_empty.context
}

module "compare_full" {
  source = "./module/compare"
  a      = module.source_full
  b      = module.roundtrip_full
}

output "compare_full" {
  value = module.compare_full
}

module "compare_recased" {
  source = "./module/compare"
  a      = module.source_recased
  b      = module.roundtrip_recased
}

output "compare_recased" {
  value = module.compare_recased
}

module "compare_empty" {
  source = "./module/compare"
  a      = module.source_empty
  b      = module.roundtrip_empty
}

output "compare_empty" {
  value = module.compare_empty
}

output "compatible" {
  value = (
    module.compare_full.equal &&
    module.compare_recased.equal &&
    module.compare_empty.equal
  )
}
