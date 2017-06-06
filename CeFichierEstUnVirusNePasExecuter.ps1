
# FROM https://gallery.technet.microsoft.com/scriptcenter/encryptdecrypt-files-use-65e7ae5d

$0 = $myInvocation.MyCommand.Definition
$dp0 = [System.IO.Path]::GetDirectoryName($0)

$p = [Environment]::GetEnvironmentVariable("PSModulePath")
write-host $p
$p += ";"+$dp0+"\Modules\"
[Environment]::SetEnvironmentVariable("PSModulePath",$p)

Import-Module -Name AES -Verbose

#Create Key
$key = Create-AESKey
Write-Host $key
#Encrypt the file and add the .crypto extension
Encrypt-File secrets.txt -Key $key -Suffix '.crypto'

#Decrypt the file
# Decrypt-File secrets.txt.crypto -Key $key -Suffix '.crypto'