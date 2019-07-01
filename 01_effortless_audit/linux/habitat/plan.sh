pkg_name=audit-baseline
pkg_version=0.1.0
pkg_origin=effortless
pkg_deps=(chef/inspec)
pkg_build_deps=(chef/inspec core/jq-static)
pkg_svc_user=root
pkg_license=Apache-2.0

do_before() {
  # Exit with error if not in the directory with 'inspec.yml'.
  # This can happen if someone does 'hab studio enter' from within the
  # 'habitat/' directory.
  if [ ! -f "$PLAN_CONTEXT/../inspec.yml" ]; then
    message="ERROR: Cannot find inspec.yml."
    message="$message Please build from the profile root"
    build_line "$message"

    return 1
  fi

  # Execute an 'inspec compliance login' if a profile needs to be fetched from
  # the Automate server
  if [ "$(grep "compliance: " "$PLAN_CONTEXT/../inspec.yml")" ]; then
    _do_compliance_login;
  fi
}

do_setup_environment() {
  set_buildtime_env PROFILE_CACHE_DIR "$HAB_CACHE_SRC_PATH/$pkg_dirname"
  set_buildtime_env ARCHIVE_NAME "$pkg_name-$pkg_version.tar.gz"

  # InSpec loads `pry` which tries to expand `~`. This fails if HOME isn't set.
  set_runtime_env HOME "$pkg_svc_var_path"

  # InSpec will create a `.inspec` directory in the user's home directory.
  # This overrides that to write to a place within the running service's path.
  # NOTE: Setting HOME does the same currently. This is here to be explicit.
  set_runtime_env INSPEC_CONFIG_DIR  "$pkg_svc_var_path"
}

do_unpack() {
  # Change directory to where the profile files are
  pushd "$PLAN_CONTEXT/../" > /dev/null

  # Get a list of all files in the profile except those that are Habitat related
  profile_files=($(ls -I habitat -I results -I "*.hart"))

  mkdir -p "$PROFILE_CACHE_DIR" > /dev/null

  # Copy just the profile files to the profile cache directory
  cp -r ${profile_files[@]} "$PROFILE_CACHE_DIR"
}

do_build() {
  inspec archive "$PROFILE_CACHE_DIR" \
                 --overwrite \
                 -o "$PROFILE_CACHE_DIR/$ARCHIVE_NAME" \
                 --chef-license "$CHEF_LICENSE"
}

do_install() {
  cp "$PROFILE_CACHE_DIR/$ARCHIVE_NAME" "$pkg_prefix"
}

_do_compliance_login() {
  if [ -z $COMPLIANCE_CREDS ]; then
    message="ERROR: Please perform an 'inspec compliance login' and set"
    message="$message \$HAB_STUDIO_SECRET_COMPLIANCE_CREDS to the contents of"
    message="$message '~/.inspec/compliance/config.json'"
    build_line "$message"
    return 1
  fi

  user=$(echo $COMPLIANCE_CREDS | jq .user | sed 's/"//g')
  token=$(echo $COMPLIANCE_CREDS | jq .token | sed 's/"//g')
  automate_server=$(echo $COMPLIANCE_CREDS | \
                    jq .server | \
                    sed 's/\/api\/v0//' | \
                    sed 's/"//g'
                   )
  insecure=$(echo $COMPLIANCE_CREDS | jq .insecure)
  inspec compliance login --insecure $insecure \
                          --user $user \
                          --token $token \
                          --chef-license "$CHEF_LICENSE" \
                          $automate_server
                          
}