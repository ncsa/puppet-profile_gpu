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

  # Setup config for template
  if find_file('/usr/bin/python3') {
    notify{'there is a python3':}
  } else {
    notify{'No python3':}
  }

  $dcgmd_telegraf_config = {
    'execStart' => 'TODO',
  }


  systemd::unit_file { 'dcgmd-telegraf.service':
    content => epp( "${module_name}/dcgmd-telegraf.service.epp", $dcgmd_telegraf_config),
    enable  => $enable_dcgm,
    active  => $enable_dcgm,
  }



}
