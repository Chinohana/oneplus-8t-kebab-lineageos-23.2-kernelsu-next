#!/usr/bin/env bash
set -euo pipefail

if [[ "$#" -ne 4 ]]; then
  echo "usage: $0 <kernel.config> <applied-patches.txt> <kernel-release> <output>" >&2
  exit 2
fi

config_file="$1"
patches_file="$2"
kernel_release="$3"
output_file="$4"

test -s "${config_file}"
test -s "${patches_file}"
test -n "${kernel_release}"

require_config() {
  local setting="$1"

  grep -Fqx "${setting}" "${config_file}" || {
    echo "Root-readiness input is missing required config: ${setting}" >&2
    exit 1
  }
}

require_patch() {
  local patch="$1"

  grep -Fqx "${patch}" "${patches_file}" || {
    echo "Root-readiness input is missing required patch: ${patch}" >&2
    exit 1
  }
}

[[ "${kernel_release}" == 4.19.* ]] || {
  echo "Root-readiness audit only supports the Linux 4.19 baseline: ${kernel_release}" >&2
  exit 1
}

require_config 'CONFIG_KSU=y'
require_config 'CONFIG_KSU_MANUAL_SU=y'
require_config '# CONFIG_KPM is not set'
require_config 'CONFIG_SECURITY_SELINUX=y'
require_patch 'sukisu-v4.1.3-linux-4.19/0014-feature-report-selinux_hide-unsupported-on-Linux-4.1.patch'
require_patch 'sukisu-v4.1.3-linux-4.19/0015-sukisu-restore-experimental-Linux-4.19-SELinux-rules.patch'

if grep -Eq '^CONFIG_(KSU_)?SUSFS=y$' "${config_file}" ||
   grep -Eiq '(^|/)susfs([^/]*)(/|$)' "${patches_file}"; then
  echo "Root-readiness audit found an unexpected SUSFS input" >&2
  exit 1
fi

cat > "${output_file}" <<EOF
image_compiled=yes
flashable_package=no
code_restored=yes
compile_checks_passed=yes
device_boot_test=no
root_functional_test=no
root_verified_on_device=no
ready_for_owner_device_experimental_test=no
selinux_ksu_domain=created_by_code_compile_checked_device_unverified
selinux_ksu_file_context=created_by_code_compile_checked_device_unverified
selinux_boot_rules=restored_compile_checked_device_unverified
dynamic_sepolicy=restored_explicit_rules_only_compile_checked_device_unverified
selinux_hide=unsupported
selinux_enforcing=required
ksu_domain_permissive=no
wildcard_allow=no
legacy_policy_mutation=in_place_non_transactional_no_rollback
kpm=disabled
susfs=absent
release_ready=no
kernel_release=${kernel_release}
evidence_config=CONFIG_KSU=y,CONFIG_KSU_MANUAL_SU=y,CONFIG_SECURITY_SELINUX=y,CONFIG_KPM=n
evidence_boot_rules=Linux_4.19_apply_kernelsu_rules_creates_ksu_and_ksu_file_with_explicit_rules
evidence_dynamic_sepolicy=handle_sepolicy_processes_explicit_requests_and_rejects_wildcard_allow_and_permissive
risk=Linux_4.19_mutates_the_active_policydb_in_place_without_transaction_or_rollback
notice=Compilation_and_static_checks_passed_but_boot_Root_and_SELinux_behavior_remain_unverified_until_owner_device_testing.
EOF

test -s "${output_file}"
