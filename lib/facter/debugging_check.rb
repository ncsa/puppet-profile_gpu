Facter.add('nvdebugging') do
  setcode do
    if File.exist? '/var/spool/slurmd/nvperfenabled'
       true
    else
       false
    end
  end
end
