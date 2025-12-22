$paths=@('scripts/key/ct_datalake_id_ed25519','scripts/key/ct_datalake_id_ed25519.pub')
foreach($p in $paths){
    $acl = New-Object System.Security.AccessControl.FileSecurity
    $rule = New-Object System.Security.AccessControl.FileSystemAccessRule($env:USERNAME,'Read','Allow')
    $acl.SetAccessRule($rule)
    Set-Acl -Path $p -AclObject $acl
}
