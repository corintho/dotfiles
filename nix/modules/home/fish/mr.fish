function mr --argument remote
  set -q remote[1];
  if test $status -ne 0
    echo "$status"
    echo "No remote given"
  else
    echo "Using sudo to mount remote share"
    sudo mkdir -p /smb/$remote/
    sudo mount.cifs //192.168.2.250/$remote /smb/$remote/ -o uid=1000,gid=1000,credentials=/run/agenix/smb_corintho  echo "$status"
  end
end
