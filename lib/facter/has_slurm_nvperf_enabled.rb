Facter.add('has_slurm_nvperf_enabled') do
  setcode do
    Facter::Core::Execution.execute('test -f /var/spool/slurmd/nvperfenabled')
    $CHILD_STATUS.success?
  end
end
