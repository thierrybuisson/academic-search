function Create-AESKey() {
<#
.SYNOPSIS 
Generates a random AES key.

.DESCRIPTION
Generates a random AES key based on the desired key size.

.PARAMETER KeySize
Number of bits the generated key will have.

.EXAMPLE

$key = Create-AESKey

This example generates a random 256-bit AES key and stores it in the variable $key.

.NOTES
Author: Tyler Siegrist
Date: 8/23/2016
#>
    Param(
       [Parameter(Mandatory=$false, Position=1, ValueFromPipeline=$true)]
       [Int]$KeySize=256
    )

    try
    {
        $AESProvider = New-Object "System.Security.Cryptography.AesManaged"
        $AESProvider.KeySize = $KeySize
        $AESProvider.GenerateKey()
        return [System.Convert]::ToBase64String($AESProvider.Key)
    }
    catch
    {
        Write-Error $_
    }
}

Function Encrypt-File
{
<#
.SYNOPSIS 
Encrypts a file using AES.

.DESCRIPTION
Encrypts a file using an AES key.

.PARAMETER FileToEncrypt
File(s) to be encrypted

.PARAMETER Key
AES key to be used for encryption.

.EXAMPLE

$key = Create-AESKey
Encrypt-File 'C:\file.ext' $key

This example encrypts C:\file.ext with the key stored in the variable $key.

.NOTES
Author: Tyler Siegrist
Date: 8/23/2016
#>
    Param(
       [Parameter(Mandatory=$true, Position=1)]
       [System.IO.FileInfo[]]$FileToEncrypt,
       [Parameter(Mandatory=$true, Position=2)]
       [String]$Key,
       [Parameter(Mandatory=$false, Position=3)]
       [String]$Suffix = '.extension'
    )

    #Load dependencies
    Try
    {
        [System.Reflection.Assembly]::LoadWithPartialName('System.Security.Cryptography')
    }
    Catch
    {
        Write-Error 'Could not load required assembly.'
        Return
    }

    #Configure AES
    try
    {
        $EncryptionKey = [System.Convert]::FromBase64String($Key)
        $KeySize = $EncryptionKey.Length*8
        $AESProvider = New-Object 'System.Security.Cryptography.AesManaged'
        $AESProvider.Mode = [System.Security.Cryptography.CipherMode]::CBC
        $AESProvider.BlockSize = 128
        $AESProvider.KeySize = $KeySize
        $AESProvider.Key = $EncryptionKey
    }
    Catch
    {
        Write-Error 'Unable to configure AES, verify you are using a valid key.'
        Return
    }

    Write-Verbose "Encryping $($FileToEncrypt.Count) File(s) with the $KeySize-bit key $Key"

    #Used to store successfully encrypted file names.
    $EncryptedFiles = @()
    
    ForEach($File in $FileToEncrypt)
    {
        If($File.Name.EndsWith($Suffix))
        {
            Write-Error "$($File.FullName) already has a suffix of '$Suffix'."
            Continue
        }

        #Open file to encrypt
        Try
        {
            $FileStreamReader = New-Object System.IO.FileStream($File.FullName, [System.IO.FileMode]::Open)
        }
        Catch
        {
            Write-Error "Unable to open $($File.FullName) for reading."
            Continue
        }

        #Create destination file
        $DestinationFile = $File.FullName + $Suffix
        Try
        {
            $FileStreamWriter = New-Object System.IO.FileStream($DestinationFile, [System.IO.FileMode]::Create)
        }
        Catch
        {
            Write-Error "Unable to open $DestinationFile for writing."
            $FileStreamReader.Close()
            Continue
        }
    
        #Write IV length & IV to encrypted file
        $AESProvider.GenerateIV()
        $FileStreamWriter.Write([System.BitConverter]::GetBytes($AESProvider.IV.Length), 0, 4)
        $FileStreamWriter.Write($AESProvider.IV, 0, $AESProvider.IV.Length)

        Write-Verbose "Encrypting $($File.FullName) with an IV of $([System.Convert]::ToBase64String($AESProvider.IV))"

        #Encrypt file
        try
        {
            $Transform = $AESProvider.CreateEncryptor()
            $CryptoStream = New-Object System.Security.Cryptography.CryptoStream($FileStreamWriter, $Transform, [System.Security.Cryptography.CryptoStreamMode]::Write)
            [Int]$Count = 0
            [Int]$BlockSizeBytes = $AESProvider.BlockSize / 8
            [Byte[]]$Data = New-Object Byte[] $BlockSizeBytes
            Do
            {
                $Count = $FileStreamReader.Read($Data, 0, $BlockSizeBytes)
                $CryptoStream.Write($Data, 0, $Count)
            }
            While($Count -gt 0)
    
            #Close open files
            $CryptoStream.FlushFinalBlock()
            $CryptoStream.Close()
            $FileStreamReader.Close()
            $FileStreamWriter.Close()

            #Delete unencrypted file
            # Remove-Item $File.FullName
            Write-Verbose "Successfully encrypted $($File.FullName)"
            $EncryptedFiles += $DestinationFile
        }
        catch
        {
            Write-Error "Failed to encrypt $($File.FullName)."
            $CryptoStream.Close()
            $FileStreamWriter.Close()
            $FileStreamReader.Close()
            Remove-Item $DestinationFile
        }
    }

    $Result = New-Object –TypeName PSObject
    $Result | Add-Member –MemberType NoteProperty –Name Computer –Value $env:COMPUTERNAME
    $Result | Add-Member –MemberType NoteProperty –Name Key –Value $Key
    $Result | Add-Member –MemberType NoteProperty –Name Files –Value $EncryptedFiles
    return $Result
}

Function Decrypt-File
{
<#
.SYNOPSIS 
Decrypts a file using AES.

.DESCRIPTION
Decrypts a file using an AES key.

.PARAMETER FileToDecrypt
File(s) to be decrypted

.PARAMETER Key
AES key to be used for decryption.

.EXAMPLE

Decrypt-File 'C:\file.ext.encrypted' $key

This example decrypts C:\file.ext.encrypted with the key stored in the variable $key.

.NOTES
Author: Tyler Siegrist
Date: 8/23/2016
#>
    Param(
       [Parameter(Mandatory=$true, Position=1)]
       [System.IO.FileInfo[]]$FileToDecrypt,
       [Parameter(Mandatory=$true, Position=2)]
       [String]$Key,
       [Parameter(Mandatory=$false, Position=3)]
       [String]$Suffix = '.extension'
    )
 
    #Load dependencies
    Try
    {
        [System.Reflection.Assembly]::LoadWithPartialName('System.Security.Cryptography')
    }
    Catch
    {
        Write-Error 'Could not load required assembly.'
        Return
    }

    #Configure AES
    try
    {
        $EncryptionKey = [System.Convert]::FromBase64String($Key)
        $KeySize = $EncryptionKey.Length*8
        $AESProvider = New-Object 'System.Security.Cryptography.AesManaged'
        $AESProvider.Mode = [System.Security.Cryptography.CipherMode]::CBC
        $AESProvider.BlockSize = 128
        $AESProvider.KeySize = $KeySize
        $AESProvider.Key = $EncryptionKey
    }
    Catch
    {
        Write-Error 'Unable to configure AES, verify you are using a valid key.'
        Return
    }

    Write-Verbose "Encryping $($FileToDecrypt.Count) File(s) with the $KeySize-bit key $Key"

    #Used to store successfully decrypted file names.
    $DecryptedFiles = @()

    ForEach($File in $FileToDecrypt)
    {
        #Verify filename
        If(-not $File.Name.EndsWith($Suffix))
        {
            Write-Error "$($File.FullName) does not have an extension of '$Suffix'."
            Continue
        }

        #Open file to decrypt
        Try
        {
            $FileStreamReader = New-Object System.IO.FileStream($File.FullName, [System.IO.FileMode]::Open)
        }
        Catch
        {
            Write-Error "Unable to open $($File.FullName) for reading."
            Continue
        }
    
        #Create destination file
        $DestinationFile = $File.FullName -replace "$Suffix$"
        Try
        {
            $FileStreamWriter = New-Object System.IO.FileStream($DestinationFile, [System.IO.FileMode]::Create)
        }
        Catch
        {
            Write-Error "Unable to open $DestinationFile for writing."
            $FileStreamReader.Close()
            Continue
        }

        #Get IV
        try
        {
            [Byte[]]$LenIV = New-Object Byte[] 4
            $FileStreamReader.Seek(0, [System.IO.SeekOrigin]::Begin) | Out-Null
            $FileStreamReader.Read($LenIV,  0, 3) | Out-Null
            [Int]$LIV = [System.BitConverter]::ToInt32($LenIV,  0)
            [Byte[]]$IV = New-Object Byte[] $LIV
            $FileStreamReader.Seek(4, [System.IO.SeekOrigin]::Begin) | Out-Null
            $FileStreamReader.Read($IV, 0, $LIV) | Out-Null
            $AESProvider.IV = $IV
        }
        catch
        {
            Write-Error 'Unable to read IV from file, verify this file was made using the included Encrypt-File function.'
            Continue
        }

        Write-Verbose "Decrypting $($File.FullName) with an IV of $([System.Convert]::ToBase64String($AESProvider.IV))"

        #Decrypt
        try
        {
            $Transform = $AESProvider.CreateDecryptor()
            [Int]$Count = 0
            [Int]$BlockSizeBytes = $AESProvider.BlockSize / 8
            [Byte[]]$Data = New-Object Byte[] $BlockSizeBytes
            $CryptoStream = New-Object System.Security.Cryptography.CryptoStream($FileStreamWriter, $Transform, [System.Security.Cryptography.CryptoStreamMode]::Write)
            Do
            {
                $Count = $FileStreamReader.Read($Data, 0, $BlockSizeBytes)
                $CryptoStream.Write($Data, 0, $Count)
            }
            While ($Count -gt 0)

            $CryptoStream.FlushFinalBlock()
            $CryptoStream.Close()
            $FileStreamWriter.Close()
            $FileStreamReader.Close()

            #Delete encrypted file
            Remove-Item $File.FullName
            Write-Verbose "Successfully decrypted $($File.FullName)"
            $DecryptedFiles += $DestinationFile
        }
        catch
        {
            Write-Error "Failed to decrypt $($File.FullName)."
            $CryptoStream.Close()
            $FileStreamWriter.Close()
            $FileStreamReader.Close()
            Remove-Item $DestinationFile
        }        
    }

    $Result = New-Object –TypeName PSObject
    $Result | Add-Member –MemberType NoteProperty –Name Computer –Value $env:COMPUTERNAME
    $Result | Add-Member –MemberType NoteProperty –Name Key –Value $Key
    $Result | Add-Member –MemberType NoteProperty –Name Files –Value $DecryptedFiles
    return $Result
}

Export-ModuleMember -Function Create-AESKey
Export-ModuleMember -Function Encrypt-File
Export-ModuleMember -Function Decrypt-File