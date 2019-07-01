#@IgnoreInspection BashAddShebang
if [ -z ${CHEF_POLICYFILE+x} ]; then
  policy_name="base"
else
  policy_name=${CHEF_POLICYFILE}
fi

scaffold_policy_name="$policy_name"
pkg_name=config-baseline
pkg_origin=effortless
pkg_version="0.1.0"
pkg_maintainer="The Habitat Maintainers <humans@habitat.sh>"
pkg_description="The Chef $scaffold_policy_name Policy"
pkg_upstream_url="http://chef.io"
pkg_scaffolding="core/scaffolding-chef"
pkg_svc_user=("root")
pkg_exports=(
  [chef_client_ident]=chef_client_ident
)
