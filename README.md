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

To collect telegraf metrics you must define the hiera value `profile_gpu::dcgm::install::bind_mount_install`.

- This is set to no value in data/common.yaml and must be defined in your project control-repo.
- See REFERENCE.md for details

In order to enable Nvidia performance counters on Ampere and older cards (Hopper may not require this work around), DCGM must not be running and collecting data. Disabling DCGM and Telegraf can be done via a Slurm prolog/epilog (an example is listed below. To make this profile not restart the services, a fact has been created to look for a file. This file is hardcoded to look at '/var/spool/slurmd/nvperfenabled'. If this file is found, DCGM and Telegraf will not be restarted.

Prolog:

```
#!/bin/bash

touch /var/spool/slurmd/nvperfenabled

IFS=',' read -ra features <<< "$SLURM_JOB_CONSTRAINTS"

for feature in "${features[@]}"; do
   echo $feature
   if [ "$feature" = "nvperf" ]; then
      /usr/bin/systemctl stop dcgmd-telegraf.service
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
      /usr/bin/systemctl stop dcgmd-telegraf.service
      /usr/bin/systemctl stop nvidia-dcgm.service
      /usr/bin/systemctl stop nvidia-persistenced.service
      /usr/sbin/modprobe -rf nvidia_uvm nvidia_drm nvidia_modeset nvidia
      /usr/sbin/modprobe nvidia
      /usr/sbin/modprobe nvidia_uvm nvidia_drm nvidia_modeset
      /usr/bin/systemctl start nvidia-persistenced.service
      /usr/bin/systemctl start dcgmd-telegraf.service
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
