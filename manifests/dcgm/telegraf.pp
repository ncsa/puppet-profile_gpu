# @summary Configures telegraf reporting for DCGM
#
# @param enable
#   Enable or disable telegraf reporting for DCGM
#
# @example
#   include profile_gpu::dcgm::telegraf
class profile_gpu::dcgm::telegraf (
  Boolean $enable,
) {
  if ($enable) {
    $ensure_parm = 'present'
  } else {
    $ensure_parm = 'absent'
  }

  file { '/etc/telegraf/telegraf.d/dcgmd.conf':
    ensure  => $ensure_parm,
    content => file("${module_name}/dcgmd.conf"),
    mode    => '0640',
    owner   => 'root',
    group   => 'telegraf',
    notify  => Service['telegraf'],
  }

  file { '/etc/telegraf/scripts/dcgm':
    ensure => 'directory',
    mode   => '0650',
    owner  => 'root',
    group  => 'telegraf',
  }

  file { '/etc/telegraf/scripts/dcgm/dcgmi_stats.sh':
    ensure  => $ensure_parm,
    content => file("${module_name}/dcgmi_stats.sh" ),
    mode    => '0750',
    owner   => 'root',
    group   => 'telegraf',
    notify  => Service['telegraf'],
  }

  if $facts['nvdebugging'] != true {
    # Setup nvidia-dcgm systemd service
    #
    systemd::unit_file { 'nvidia-dcgm.service':
      content => file("${module_name}/nvidia-dcgm.service"),
      enable  => $enable,
      require => Package['datacenter-gpu-manager'],
      active  => $enable,
    }
  }
}
