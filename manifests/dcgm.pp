# @summary Installs and configures the NVIDIA DCGM (Data Center GPU Manager)
#
# @param enable_dcgm
#   Whether to install and configure NVIDIA DCGM
#
# @param packages
#   Required packages for Nvidia DCGM
#
# @example
#   include profile_gpu::dcgm
class profile_gpu::dcgm (
  Boolean $enable_dcgm,
  Array[String] $packages,
) {

  if ($enable_dcgm) {
    $ensure_parm = 'present'

    ensure_packages( $packages )

  } else {
    $ensure_parm = 'absent'
  }

  systemd::unit_file { 'nvidia-dcgm.service':
    content => file("${module_name}/nvidia-dcgm.service"),
    enable  => $enable_dcgm,
    active  => $enable_dcgm,
  }


}
