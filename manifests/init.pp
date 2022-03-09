# @summary GPU specific host configuration
#
# @example
#   include profile_gpu
class profile_gpu {

  include profile_gpu::dcgm::install
  include profile_gpu::dcgm::telegraf

}
