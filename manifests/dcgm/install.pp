# @summary Installs the NVIDIA DCGM (Data Center GPU Manager)
#
# @param bind_mount_install
#   Boolean to set if this install requires a bind mount
#
#   There is no completely safe default value for this, so
#   no values is set and must be set individually wherever
#   this is used
#
#   Only set this to true if DCGM install files would
#   clobber a shared filesystem. Commonly needed on systems
#   where /usr/local is mounted as a shared filesystem. In which
#   case you'd set this to true. If the DCGM install would not
#   clobber any shared filesystems, then set this to false
#
# @param bind_dst_path
#   Destination location for bind mount to install DCGM into
#
#   Only needed on systems where DCGM install files would
#   clobber a shared filesystem. Commonly needed on systems
#   where /usr/local is mounted as a shared filesystem. In which
#   case you'd most likely set this to /usr/local/dcgm
#
# @param bind_mnt_options
#   Bind mount options to use
#
#   Only needed on systems where DCGM install files would
#   clobber a shared filesystem. Commonly needed on systems
#   where /usr/local is mounted as a shared filesystem.
#
# @param bind_parent_dst_mount
#   The parent mount which bind_dst_path depends on
#
#   Only needed on systems where DCGM install files would
#   clobber a shared filesystem. Commonly needed on systems
#   where /usr/local is mounted as a shared filesystem. In which
#   case you'd most likely set this to /usr/local
#
# @param bind_src_path
#   Source path for bind mount
#
#   Only needed on systems where DCGM install files would
#   clobber a shared filesystem. Commonly needed on systems
#   where /usr/local is mounted as a shared filesystem. This path
#   can be set to any path that's local to the node (ie not a shared
#   mount). Commonly you can use /var/log/dcgm
#
# @param dcgm_version
#   Specify what version of DCGM to install
#
#   This is important because we have made modifications to the
#   scripts (to allow it to listen on localhost) which are likely
#   to break in new versions. See version in data/common.yaml
#   for versions known to work
#
# @param install_dcgm
#   Whether to install NVIDIA DCGM
#
# @param packages
#   Required packages for Nvidia DCGM
#
# @example
#   include profile_gpu::dcgm::install
class profile_gpu::dcgm::install (
  Boolean       $bind_mount_install,
  String        $bind_dst_path,
  String        $bind_mnt_options,
  String        $bind_parent_dst_mount,
  String        $bind_src_path,
  Boolean       $install_dcgm,
  Array[String] $packages,
  String        $dcgm_version,
) {

  if ($install_dcgm) {

    if ($bind_mount_install) {
      # We need to setup bind mounts for DCGM to install into

      # Set defaults for directories
      File {
        ensure => directory,
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
        before => Mount[ $bind_dst_path ],

      }

      # Mark sure dst mount point exists
      file { $bind_dst_path:
      }

      # Make sure src mount point exists
      file { $bind_src_path:
      }

      # Setup the actual mount
      mount { $bind_dst_path:
        ensure  => 'mounted',
        fstype  => 'none',
        device  => $bind_src_path,
        options => $bind_mnt_options,
        require => [
          Mount[ $bind_parent_dst_mount ],
        ]
      }

      $install_options = {
        'ensure'  => $dcgm_version,
        'require' => Mount[ $bind_dst_path ],
      }

    } else {

      $install_options = {
        'ensure' => $dcgm_version,
      }
    }

    ensure_packages( $packages , $install_options)
  }
}
