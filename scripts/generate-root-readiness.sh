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
require_patch 'sukisu-v4.1.3-linux-4.19/0015-security-disable-unsafe-SELinux-policy-mutation-on-L.patch'

if grep -Eq '^CONFIG_(KSU_)?SUSFS=y$' "${config_file}" ||
   grep -Eiq '(^|/)susfs([^/]*)(/|$)' "${patches_file}"; then
  echo "Root-readiness audit found an unexpected SUSFS input" >&2
  exit 1
fi

cat > "${output_file}" <<EOF
image_compiled=yes
flashable_package=no
device_boot_test=no
root_functional_test=no
selinux_ksu_domain=absent
selinux_boot_rules=unsupported
dynamic_sepolicy=unsupported
selinux_hide=unsupported
kpm=disabled
susfs=absent
release_ready=no
kernel_release=${kernel_release}
evidence_config=CONFIG_KSU=y,CONFIG_KSU_MANUAL_SU=y,CONFIG_SECURITY_SELINUX=y,CONFIG_KPM=n
evidence_boot_rules=Linux_4.19_guard_returns_unsupported
evidence_dynamic_sepolicy=handle_sepolicy_returns_-EOPNOTSUPP
reason=u:r:ksu:s0 and u:object_r:ksu_file:s0 cannot be resolved by the current Android SELinux policy, so root in enforcing mode must not be claimed.
notice=This static status file prevents misclassification and does not replace device testing.
EOF

test -s "${output_file}"
