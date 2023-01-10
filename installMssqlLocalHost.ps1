$hostName = "[hostName]"
$Username = "[userName]"
$Password = ConvertTo-SecureString "[password]" -AsPlainText -Force

#Perquisites for remote invoking
New-ItemProperty -Path "HKLM:\Software\Microsoft\Cryptography\Protect\Providers\df9d8cd0-1501-11d1-8c7a-00c04fc297eb" -Name "ProtectionPolicy" -PropertyType "DWORD" -Value "1" 

#Creates new dir and copies files from share folder if doesn't exists
 if (-not(Test-Path -Path "C:\mssql-installs")){ 
    New-Item "C:\mssql-installs" -ItemType Directory 
    Write-Host "Successfully created mssql-installs dir"
    Copy-Item "\\[RemotePsHost]\share\SSMS-Setup*" -Destination "C:\mssql-installs\" -Recurse -Force 
    Copy-Item "\\[RemotePsHost]\share\SQLServer2019\" -Destination "C:\mssql-installs\" -Recurse -Force 
    Write-Host "Successfully copied the install files"               
}else{
    Write-Host "Cannot create and copy files, already exists"
} 

#installs mssql database

$UsernameForInstallation = "[domain]\" + "$Username"
$Password = ConvertTo-SecureString "[password]" -AsPlainText -Force
c:\mssql-installs\SQLServer2019\setup.exe  /SkipRules=RebootRequiredCheck `
/ACTION=Install `
/AGTSVCSTARTUPTYPE=Automatic `
/BROWSERSVCSTARTUPTYPE=Automatic `
/ERRORREPORTING=False `
/FEATURES="SQL" `
/IACCEPTSQLSERVERLICENSETERMS `
/INSTANCEID="[instanceName]" `
/INSTANCENAME="[instanceName]" `
/ISSVCSTARTUPTYPE=Automatic `
/QUIET `
/SAPWD="$Password" `
/SECURITYMODE=SQL `
/SQLSVCSTARTUPTYPE=Automatic `
/SQLSYSADMINACCOUNTS="$UsernameForInstallation" `
/SQMREPORTING=False `
/TCPENABLED=1 `
/UpdateEnabled=FALSE `
/UpdateSource=MU ` 


$folderpath="C:\mssql-installs"
$filepath="$folderpath\SSMS-Setup-ENU.exe"
 
Write-host "Located the SQL SSMS Installer binaries, moving on to install..."
 
# start the SSMS installer
Write-host "Beginning SSMS 2016 install..." -nonewline
$Parms = " /Install /Quiet /Norestart /Logs log.txt"
$Prms = $Parms.Split(" ")
& "$filepath" $Prms | Out-Null
Write-Host "SSMS installation complete" 
