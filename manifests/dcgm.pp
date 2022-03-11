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

    # TMP fix in place for some bug in NVIDIA DCGM
    file_line { 'fix_dcgm_telegraf_py':
      path               => '/usr/local/dcgm/bindings/python3/dcgm_telegraf.py',
      line               => '        self.m_sock.sendto(payload.encode(), self.m_dest)',
      match              => '        self\.m_sock.sendto\(payload, self\.m_dest\)',
      append_on_no_match => 'false',
    }


    # TODO patch /usr/local/dcgm/bindings/python3/dcgm_telegraf.py again
    # this time for:
    # sed -i "/^DEFAULT_TELEGRAF_PORT = 8094$/a LISTEN_HOST = '127.0.0.1'\nLISTEN_PORT = 5556"
    # sed -i "/self.m_sock = socket(AF_INET, SOCK_DGRAM)/a\ self.m_sock.bind((LISTEN_HOST, LISTEN_PORT))"

  } elsif find_file('/usr/bin/python') {
    $exec_start = '/usr/bin/python'
    $dcgm_telegraf_py_path = '/usr/local/dcgm/bindings/dcgm_telegraf.py'


    # TODO patch /usr/local/dcgm/bindings/dcgm_telegraf.py again
    # this time for:
    # sed -i "/^DEFAULT_TELEGRAF_PORT = 8094$/a LISTEN_HOST = '127.0.0.1'\nLISTEN_PORT = 5556"
    # sed -i "/self.m_sock = socket(AF_INET, SOCK_DGRAM)/a\ self.m_sock.bind((LISTEN_HOST, LISTEN_PORT))"


  } else {
    fail('Unable to determine python version')
  }

  $dcgmd_telegraf_config = {
    'exec_start'            => $exec_start,
    'dcgm_telegraf_py_path' => $dcgm_telegraf_py_path,
  }

  systemd::unit_file { 'dcgmd-telegraf.service':
    content => epp( "${module_name}/dcgmd-telegraf.service.epp", $dcgmd_telegraf_config),
    enable  => $enable_dcgm,
    active  => $enable_dcgm,
    before  => File['/etc/telegraf/telegraf.d/dcgmd.conf'],
  }


  # TODO add something that puts in place dcgmd.conf and restarts telegraf
  file { '/etc/telegraf/telegraf.d/dcgmd.conf':
    ensure => $ensure_parm,
    mode   => '0640',
    owner  => 'root',
    group  => 'telegraf',
    notify => Service['telegraf'],
  }


}
