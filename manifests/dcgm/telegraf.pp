# @summary Configures telegraf reporting for DCGM
#
# @param dcgm_telegraf_port
#   Port that telegraf socket will listen on, defaults to 8094
#
# @param dcgm_telegraf_py_port
#   Port that DCGM python process will listen on, defaults to 5556
#
# @param enable
#   Enable or disable telegraf reporting for DCGM
#
# @example
#   include profile_gpu::dcgm::telegraf
class profile_gpu::dcgm::telegraf (
  Integer $dcgm_telegraf_port,
  Integer $dcgm_telegraf_py_port,
  Boolean $enable,
) {

  if ($enable) {
    $ensure_parm = 'present'
  } else {
    $ensure_parm = 'absent'
  }

  #
  # Setup nvidia-dcgm systemd service
  #
  systemd::unit_file { 'nvidia-dcgm.service':
    content => file("${module_name}/nvidia-dcgm.service"),
    enable  => $enable,
    active  => $enable,
    before  => Systemd::Unit_File['dcgmd-telegraf.service'],
    require => Package['datacenter-gpu-manager'],
  }

  #
  # Setup dcgmd-telegraf
  #

  # Setup variables
  if find_file('/usr/bin/python3') {
    $exec_start = '/usr/bin/python3'
    $dcgm_telegraf_py_path = '/usr/local/dcgm/bindings/python3/dcgm_telegraf.py'
  } elsif find_file('/usr/bin/python') {
    $exec_start = '/usr/bin/python'
    $dcgm_telegraf_py_path = '/usr/local/dcgm/bindings/dcgm_telegraf.py'
  } else {
    fail('Unable to determine python version')
  }

  # TMP fix in place for some bug in NVIDIA DCGM
  file_line { 'fix_dcgm_telegraf_py':
    path               => $dcgm_telegraf_py_path,
    match              => '        self\.m_sock.sendto\(payload, self\.m_dest\)',
    line               => '        self.m_sock.sendto(payload.encode(), self.m_dest)',
    append_on_no_match => 'false',
    require            => Package['datacenter-gpu-manager'],
    notify             => Service['dcgmd-telegraf.service'],
  }

  # First Modification so dcgmd-telegraf listens on a static port and only on localhost
  file_line { 'dcgm_telegraf_py_localhost_listen_only':
    path               => $dcgm_telegraf_py_path,
    after              => '^DEFAULT_TELEGRAF_PORT = .*',
    line               => "LISTEN_HOST = '127.0.0.1'",
    append_on_no_match => 'false',
    require            => Package['datacenter-gpu-manager'],
    notify             => Service['dcgmd-telegraf.service'],
  }

  # Second Modification so dcgmd-telegraf listens on a static port and only on localhost
  file_line { 'dcgm_telegraf_py_localhost_listen_only_part2':
    path    => $dcgm_telegraf_py_path,
    after   => "LISTEN_HOST = '127.0.0.1'",
    match   => '^LISTEN_PORT = .*',
    line    => "LISTEN_PORT = ${dcgm_telegraf_py_port}",
    require => [ Package['datacenter-gpu-manager'], File_Line['dcgm_telegraf_py_localhost_listen_only'] ],
    notify  => Service['dcgmd-telegraf.service'],
  }

  # Third Modification so dcgmd-telegraf listens on a static port and only on localhost
  file_line { 'dcgm_telegraf_py_localhost_listen_only_part3':
    path               => $dcgm_telegraf_py_path,
    after              => '        self\.m_sock = socket\(AF_INET, SOCK_DGRAM\)',
    line               => '        self.m_sock.bind((LISTEN_HOST, LISTEN_PORT))',
    append_on_no_match => 'false',
    require            => Package['datacenter-gpu-manager'],
    notify             => Service['dcgmd-telegraf.service'],
  }

  # Modification to set custom DEFAULT_TELEGRAF_PORT
  file_line { 'dcgm_telegraf_py_set_DEFAULT_TELEGRAF_PORT':
    path               => $dcgm_telegraf_py_path,
    match              => '^DEFAULT_TELEGRAF_PORT = .*',
    line               => "DEFAULT_TELEGRAF_PORT = ${dcgm_telegraf_port}",
    append_on_no_match => 'false',
    require            => Package['datacenter-gpu-manager'],
    notify             => Service['dcgmd-telegraf.service'],
  }

  # Setup config hash
  $dcgmd_telegraf_config = {
    'exec_start'            => $exec_start,
    'dcgm_telegraf_py_path' => $dcgm_telegraf_py_path,
  }

  # Setup dcgmd-telegraf systemd service
  systemd::unit_file { 'dcgmd-telegraf.service':
    content => epp( "${module_name}/dcgmd-telegraf.service.epp", $dcgmd_telegraf_config),
    enable  => $enable,
    active  => $enable,
    before  => File['/etc/telegraf/telegraf.d/dcgmd.conf'],
  }

  #
  # Setup dcgmd telegraf config
  #
  $dcgm_conf = { dcgm_telegraf_port => $dcgm_telegraf_port, }
  file { '/etc/telegraf/telegraf.d/dcgmd.conf':
    ensure  => $ensure_parm,
    content => epp( "${module_name}/dcgmd.conf.epp", $dcgm_conf ),
    mode    => '0640',
    owner   => 'root',
    group   => 'telegraf',
    notify  => Service['telegraf'],
  }

}
