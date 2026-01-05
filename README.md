# profile_gpu

![pdk-validate](https://github.com/ncsa/puppet-profile_gpu/workflows/pdk-validate/badge.svg)
![yamllint](https://github.com/ncsa/puppet-profile_gpu/workflows/yamllint/badge.svg)

NCSA Configuration specific to Hosts with GPUs.

## Table of Contents

1. [Description](#description)
1. [Setup - The basics of getting started with profile_gpu](#setup)
1. [Usage - Configuration options and additional functionality](#usage)
1. [Dependencies](#dependencies)
1. [Limitations - OS compatibility, etc.](#limitations)
1. [Development - Guide for contributing to the module](#development)

## Description

This puppet profile handles configuration specific to Hosts with GPUs

Currently DCGM Metrics collection is enabled by default but DCGM is specific to NVIDIA GPUs. See Usage Section

## Setup

Include profile_gpu in a puppet profile file:
```
include ::profile_gpu
```

## Usage

### DCGM Telegraf Metrics

Note : DCGM telegraf Metrics is specific to NVIDIA GPUs, if you have a node with GPUs but not NVIDIA you should
set these hiera variables (we have a TODO to make this use a custom fact):

- `profile_gpu::dcgm::install::install_dcgm: false`
- `profile_gpu::dcgm::telegraf::enable: false`

To collect telegraf metrics for NVIDIA GPUs you should set the hiera value `profile_gpu::dcgm::install::bind_mount_install`.

- This is set to no value in data/common.yaml and must be defined in your project control-repo.
- The reason for this parameter is that DCGM v3 installs files in /usr/local/, which may be located in a shared filesystem on some NCSA clusters.
- DCGM v4 does NOT install anything into /usr/local/, and setting this to 'false' when installing v4 is generally going to be OK.
- See [REFERENCE.md](REFERENCE.md) for details

Telegraf metrics for NVIDIA GPUs depend on the installation of DCGM. This module now defaults to installing DCGM v4 with compatibility for CUDA 12.

If you would like to install compatibility for a different major version of CUDA, or additional major versions of CUDA, make sure the relevant `-cuda**` package(s) are available and set data like the following in your control repo, including the relevant `-cudaXX` package for each version of CUDA you would like to support. Similarly, if you are using the proprietary/legacy NVIDIA driver instead of the newer, "open" driver, you'll need to include the `-proprietary` RPM. E.g., to install DCGM on a system with older GPUs, including support for both CUDA 12 and CUDA 13, specify the following in Hiera:
```yaml
profile_gpu::dcgm::install::packages:
  - "datacenter-gpu-manager-4-cuda12"
  - "datacenter-gpu-manager-4-cuda13"
  - "datacenter-gpu-manager-4-proprietary"
```

If all you want to do is run `dcgmi dmon`, e.g., via telegraf, it should not be necessary to install the corresponding `datacenter-gpu-manager-4-cuda**` package(s), and since they are rather large you may want to omit them. You can include the "*-core" RPM instead. E.g., to install the bare minimum for monitoring GPUs on a system with "open" GPU drivers, set this:
```yaml
profile_gpu::dcgm::install::packages:
  - "datacenter-gpu-manager-4-core"
```
Note that you must include the appropriate `-cudaXX` package in order to run `dcgmi diag`. And there are likely other use cases where it is necessary, so if space is not a concern it should probably be installed (hence the default for this profile).

On the other hand, it does not seem necessary to install the corresponding `datacenter-gpu-manager-4-proprietary-cuda**` package(s) in ANY case, and they are also rather large, so it is suggested to omit those (which is the default for this profile).

If any undesired RPMs are pulled down as "weak dependencies" you may want to uninstall them (or prevent them from being installed in the first place).

If you would like to install v3, set the following in your control repo:
```yaml
profile_gpu::dcgm::install::packages:
  - "datacenter-gpu-manager"
```

This profile is not designed to upgrade a v3 installation to v4. To do that you should update your control repo, as necessary, and:
```bash
systemctl stop puppet telegraf nvidia-dcgm
yum -y remove 'datacenter-gpu-manager*'
# optionally remove the local bindmount for v3
puppet agent -t
```

Before adding/removing `-cudaXX` support packages you may want to perform a similar operation (or at least stop services).

In order to enable Nvidia performance counters on Ampere and older cards (Hopper may not require this work around), DCGM must not be running and collecting data. Disabling DCGM and Telegraf can be done via a Slurm prolog/epilog (an example is listed below. To make this profile not restart the services, a fact has been created to look for a file. This file is hardcoded to look at '/var/spool/slurmd/nvperfenabled'. If this file is found, DCGM and Telegraf will not be restarted.

Prolog:

```
#!/bin/bash

touch /var/spool/slurmd/nvperfenabled

IFS=',' read -ra features <<< "$SLURM_JOB_CONSTRAINTS"

for feature in "${features[@]}"; do
   echo $feature
   if [ "$feature" = "nvperf" ]; then
      /usr/bin/systemctl stop nvidia-dcgm.service
      /usr/bin/systemctl stop nvidia-persistenced.service
      /usr/sbin/modprobe -rf nvidia_uvm nvidia_drm nvidia_modeset nvidia
      /usr/sbin/modprobe nvidia NVreg_RestrictProfilingToAdminUsers=0
      /usr/bin/modprobe nvidia_uvm nvidia_drm nvidia_modeset
      /usr/bin/systemctl start nvidia-persistenced.service
   fi
done
```

Epilog:

```
#!/bin/bash

rm -f /var/spool/slurmd/nvperfenabled

IFS=',' read -ra features <<< "$SLURM_JOB_CONSTRAINTS"

for feature in "${features[@]}"; do
   if [ "$feature" = "nvperf" ]; then
      /usr/bin/systemctl stop nvidia-dcgm.service
      /usr/bin/systemctl stop nvidia-persistenced.service
      /usr/sbin/modprobe -rf nvidia_uvm nvidia_drm nvidia_modeset nvidia
      /usr/sbin/modprobe nvidia
      /usr/sbin/modprobe nvidia_uvm nvidia_drm nvidia_modeset
      /usr/bin/systemctl start nvidia-persistenced.service
   fi
done
```

## Dependencies

- [puppet/systemd](https://forge.puppet.com/modules/puppet/systemd)

If collecting DCGM telegraf metrics, telegraf must be installed (no dependency on a particular telegraf module, only that telegraf is installed and working)

## Reference

See: [REFERENCE.md](REFERENCE.md)

## Limitations

n/a

## Development

This Common Puppet Profile is managed by NCSA for internal usage.
