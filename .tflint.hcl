# A general tflint configuration file for https://github.com/terraform-linters/tflint
# Symlink this file to ~/.tflint.hcl to use this configuration when inside terraform dir

config {
  plugin_dir = "~/.tflint.d/plugins"
}

plugin "terraform" {
  enabled = true
  preset = "all"
}

rule "terraform_standard_module_structure" {
  enabled = false
}
