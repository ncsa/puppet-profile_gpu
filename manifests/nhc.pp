# @summary Enables management of GPU related NHC (Node Health Check) scripts
#
# @param manage_default_scripts
#   If true, install general scripts that are considered appropriate for all clusters
#
# @param custom_scripts
#   Allow the addition of custom scripts beyond the scope of default scripts 
# 
# @example
#   include profile_gpu::nhc
class profile_gpu::nhc (

  Boolean $manage_default_scripts,
  Hash    $custom_scripts,

) {
  if ( $manage_default_scripts ) {
    # NVIDIA script that enables check_nvsmi_healthmon(). Manually created as it is not managed by the current NHC module (v1.4.3)
    file { '/etc/nhc/scripts/csc_nvidia_smi.nhc':
      ensure  => 'file',
      mode    => '0700',
      owner   => 'root',
      group   => 'root',
      content => file("${module_name}/csc_nvidia_smi.nhc"),
    }
  }

  # Add any custom scripts
  $custom_scripts.each | $k, $v | {
    file { $k: * => $v }
  }
}
