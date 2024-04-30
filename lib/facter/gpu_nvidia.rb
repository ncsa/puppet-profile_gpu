Facter.add(:gpu_nvidia) do
  setcode do
    `lspci | grep -i nvidia | egrep -iqw '3D|Tesla' && echo true || echo false`.strip
  end
end
