Facter.add('has_gpu_nvidia') do
  setcode do
    Facter::Core::Execution.execute('lspci | grep -i nvidia | egrep -iqw "3D|Tesla"')
    $CHILD_STATUS.success?
  end
end
