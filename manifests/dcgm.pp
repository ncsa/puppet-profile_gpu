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
    before  => File['/etc/telegraf/telegraf.d/dcgmd.conf'],
  }

  # Setup config for template
  # There is probably a better way to do this like a custom fact
  if find_file('/usr/bin/python3') {
    $exec_start = '/usr/bin/python3'
    $dcgm_telegraf_py_path = '/usr/local/dcgm/bindings/python3/dcgm_telegraf.py'
  } elsif find_file('/usr/bin/python') {
    $exec_start = '/usr/bin/python'
    $dcgm_telegraf_py_path = '/usr/local/dcgm/bindings/dcgm_telegraf.py'
  } else {
    fail('Unable to determine python version')
  }


  $dcgmd_telegraf_config = {
    'exec_start'            => $exec_start,
    'dcgm_telegraf_py_path' => $dcgm_telegraf_py_path,
  }

  # TMP fix in place for some bug in NVIDIA DCGM
  file_line { 'fix_dcgm_telegraf_py':
    path               => $dcgm_telegraf_py_path,
    match              => '        self\.m_sock.sendto\(payload, self\.m_dest\)',
    line               => '        self.m_sock.sendto(payload.encode(), self.m_dest)',
    append_on_no_match => 'false',
  }

  # First Modification so dcgmd-telegraf listens on a static port and only on localhost
  file_line { 'dcgm_telegraf_py_localhost_listen_only':
    path               => $dcgm_telegraf_py_path,
    after              => 'DEFAULT_TELEGRAF_PORT = 8094',
    # Cannot add them both in one go, line isn't smart enough to check multiple lines
    # So you instead end up added the two lines every time puppet runs
    #line               => "LISTEN_HOST = '127.0.0.1'\nLISTEN_PORT = 5556",
    line               => "LISTEN_HOST = '127.0.0.1'",
    append_on_no_match => 'false',
    before             => file_line['dcgm_telegraf_py_localhost_listen_only_part2'],
  }

  # Second Modification so dcgmd-telegraf listens on a static port and only on localhost
  file_line { 'dcgm_telegraf_py_localhost_listen_only_part2':
    path               => $dcgm_telegraf_py_path,
    after              => "LISTEN_HOST = '127.0.0.1'",
    line               => 'LISTEN_PORT = 5556',
    append_on_no_match => 'false',
  }

  # Third Modification so dcgmd-telegraf listens on a static port and only on localhost
  file_line { 'dcgm_telegraf_py_localhost_listen_only_part3':
    path               => $dcgm_telegraf_py_path,
    #after              => '        self.m_sock = socket(AF_INET, SOCK_DGRAM)',   # would add at EOF
    after              => '        self\.m_sock = socket\(AF_INET, SOCK_DGRAM\)',
    line               => '        self.m_sock.bind((LISTEN_HOST, LISTEN_PORT))',
    append_on_no_match => 'false',
  }

  systemd::unit_file { 'dcgmd-telegraf.service':
    content => epp( "${module_name}/dcgmd-telegraf.service.epp", $dcgmd_telegraf_config),
    enable  => $enable_dcgm,
    active  => $enable_dcgm,
    before  => File['/etc/telegraf/telegraf.d/dcgmd.conf'],
  }

  file { '/etc/telegraf/telegraf.d/dcgmd.conf':
    ensure => $ensure_parm,
    mode   => '0640',
    owner  => 'root',
    group  => 'telegraf',
    notify => Service['telegraf'],
  }


}
