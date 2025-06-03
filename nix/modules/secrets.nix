{ secrets, ... }: {
  age.secrets.smb_corintho.file = "${secrets}/encrypted/smb_corintho.age";
}

