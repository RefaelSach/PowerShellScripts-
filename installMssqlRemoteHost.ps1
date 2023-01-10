#The following powershell script, create a directory named "mssql-installs", 
#copies smms installation files from a network folder via 2 hop authentication
#installs sql database and sql management studio
#********** note ***********
# change the vvariables with brackets [   ] to you'r case. 


$hostName = "[hostName]"
$Username = "[userName]"
$Password = ConvertTo-SecureString "[password]" -AsPlainText -Force
$Credential = [pscredential]::new($Username,$Password) 
$Session = New-PSSession -ComputerName $hostName -Credential $Credential

#Perquisites for remote invoking
Invoke-Command -ComputerName $hostName -Credential $Credential -ScriptBlock {
Enable-PSRemoting –Force
Enable-WSManCredSSP -Role Client -DelegateComputer "[pshost.fqdn]" -Force
New-ItemProperty -Path "HKLM:\Software\Microsoft\Cryptography\Protect\Providers\df9d8cd0-1501-11d1-8c7a-00c04fc297eb" -Name "ProtectionPolicy" -PropertyType "DWORD" -Value "1" 
} 

#Creates new dir and copies files from share folder if doesn't exists
 if (-not(Invoke-Command -ComputerName $hostName -Credential $Credential -ScriptBlock {Test-Path -Path "C:\mssql-installs"})){ 
    Invoke-Command -ComputerName $hostName -Credential $Credential -ScriptBlock {New-Item "C:\mssql-installs" -ItemType Directory }
    Write-Host "Successfully created mssql-installs dir"
    Copy-Item "\\[RemotePsHost]\share\SSMS-Setup*" -Destination "C:\mssql-installs\" -Recurse -Force -ToSession $Session
    Copy-Item "\\[RemotePsHost]\share\SQLServer2019\" -Destination "C:\mssql-installs\" -Recurse -Force -ToSession $Session
    Write-Host "Successfully copied the install files"               
}else{
    Write-Host "Cannot create and copy files, already exists"
} 

#installs mssql
Invoke-Command -ComputerName $hostName -Credential $Credential -ScriptBlock {
$Username = "[domain]\" + "[username]"
$Password = ConvertTo-SecureString "[password]" -AsPlainText -Force
 c:\mssql-installs\SQLServer2019\setup.exe /SkipRules=RebootRequiredCheck `
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
/SAPWD=$Password `
/SECURITYMODE=SQL `
/SQLSVCSTARTUPTYPE=Automatic `
/SQLSYSADMINACCOUNTS=$Username `
/SQMREPORTING=False `
/TCPENABLED=1 `
/UpdateEnabled=FALSE `
/UpdateSource=MU `
}
 #/QUIET /ACTION="Install" /FEATURES=SQL /INSTANCENAME="rafitestsql" /SQLSVCACCOUNT=$Username /SQLSVCPASSWORD=$Password /SQLSYSADMINACCOUNTS=$Username /AGTSVCACCOUNT=$Username /AGTSVCPASSWORD=$Password /IAcceptSQLServerLicenseTerms /SECURITYMODE /UpdateEnabled=False}


Invoke-Command -ComputerName $hostName -Credential $Credential -ScriptBlock {
$folderpath="C:\mssql-installs"
$filepath="$folderpath\SSMS-Setup-ENU.exe"
 
write-host "Located the SQL SSMS Installer binaries, moving on to install..."
 
# start the SSMS installer
write-host "Beginning SSMS 2016 install..." -nonewline
$Parms = " /Install /Quiet /Norestart /Logs log.txt"
$Prms = $Parms.Split(" ")
& "$filepath" $Prms | Out-Null
Write-Host "SSMS installation complete" 
} 
 
