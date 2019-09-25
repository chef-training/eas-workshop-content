pkg_name=audit-baseline
pkg_version=0.1.0
pkg_origin=eas-workshop
pkg_maintainer="The Habitat Maintainers <humans@habitat.sh>"
pkg_license=("Apache-2.0")
pkg_description="Effortless Linux Audit Example"
pkg_scaffolding="chef/scaffolding-chef-inspec"

do_setup_environment() {
 set_runtime_env CHEF_LICENSE "accept-no-persist"
}