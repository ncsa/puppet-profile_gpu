# profile_gpu

![pdk-validate](https://github.com/ncsa/puppet-profile_gpu/workflows/pdk-validate/badge.svg)
![yamllint](https://github.com/ncsa/puppet-profile_gpu/workflows/yamllint/badge.svg)

NCSA Configuration specific to Hosts with GPUs

## Table of Contents

1. [Description](#description)
1. [Setup - The basics of getting started with profile_gpu](#setup)
1. [Usage - Configuration options and additional functionality](#usage)
1. [Dependencies](#dependencies)
1. [Limitations - OS compatibility, etc.](#limitations)
1. [Development - Guide for contributing to the module](#development)

## Description

This puppet profile handles configuration specific to Hosts with GPUs

## Setup

Include profile_gpu in a puppet profile file:
```
include ::profile_gpu
```

## Usage

### DCGM Telegraf Metrics

To collect telegraf metrics you must define the hiera value `profile_gpu::dcgm::install::bind_mount_install`.

- This is set to no value in data/common.yaml and must be defined in your project control-repo.
- See REFERENCE.md for details

## Dependencies

- [puppet/systemd](https://forge.puppet.com/modules/puppet/systemd)

If collecting DCGM telegraf metrics, telegraf must be installed (no dependency on a particular telegraf module, only that telegraf is installed and working)

## Reference

See: [REFERENCE.md](REFERENCE.md)

## Limitations

n/a

## Development

This Common Puppet Profile is managed by NCSA for internal usage.
