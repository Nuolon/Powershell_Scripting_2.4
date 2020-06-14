#Nick Dierks 376141: JEA Powershell setup script pre-configured for [DNS Maintenance]. All Variables are change-able as you please.

$sj = "DeTest" #Subject, in our case DNS, so feel free to change! This allows creation of multiple, different JEA's
$dsn = "'A simple JEA for complete DNS maintenance'" #Description
$usr = "N.Dierks" #The user or usergroup
$dm = "ZP11G.hanze20" #Domainname
$odc = 'ITV2G-W16-21' #Other domain controller
$vcl = 'DnsServer\*', 'Get-NetAdapter' #Visiblecmdlets  

#$odc = [string](Get-ADDomainController -Filter {name -like "IT*"} | Select Name)[0] -replace ".*=" -replace "}"
#$odc = [string](Get-ADDomainController -Filter {name -like "IT*"} | Select Name)[1] -replace ".*=" -replace "}"

if(-not (Test-Path -Path c:\JEA)){
Write-Host "C:\JEA Not present, creating it now..." -ForegroundColor Yellow
New-Item -Path C:\JEA -ItemType Directory | Out-Null
Start-Sleep -Milliseconds 750
}

if(Test-Path -Path  C:\JEA\JEA_$sj){
Write-Warning "A JEA functionality with the name: $sj , already exists. Change name and try again."
Write-Warning "Exiting script...<3"
Return
}

Write-Host "Starting creation of requested JEA configuration inside default directory: C:\JEA -> C:\JEA\JEA_$sj" -ForegroundColor Yellow
Start-Sleep -Milliseconds 1000
New-Item -Path C:\JEA\JEA_$sj -ItemType Directory | Out-Null

Write-Host "Creating specific Transcript folder at: C:\JEA\JEA_$sj\Transcripts_JEA_$sj" -ForegroundColor Yellow
Start-Sleep -Milliseconds 1000
New-Item -Path C:\JEA\JEA_$sj\Transcripts_JEA_$sj -ItemType Directory | Out-Null

cd c:\JEA\JEA_$sj

Write-Host "The PowerShell module named $sj is being generated, including it's PSM1 and PSD1 file with a RoleCabilities folder plus the Configuration file" -ForegroundColor Yellow
Start-Sleep -Milliseconds 1000
New-Item -Path C:\JEA\JEA_$sj\$sj -ItemType Directory | Out-Null

#Creates the PSM1 file, we do not really use it here but for completionists sake... It's in. Special file for custom functions and variables.  !!!Future thing, maybe include a function to recall history?!!!
New-Item -Path .\$sj\JEA_$sj.psm1

#Creating a new module manifest, which describes how a module is supposed to be processed with an attached root module, once again, not in use.  !!!Might revisit in the future, importing variables and stuff!!!.
New-ModuleManifest -Path .\$sj\JEA_$sj.psd1 -RootModule JEA_$sj.psm1 | Out-Null

#Creating the Capability file's location dir, inside the module directory.
New-Item -Path .\$sj\RoleCapabilities -ItemType Directory | Out-Null

#Creating the important Capability file, which configures what commands are available in a PS Session.
New-PSRoleCapabilityFile -Path .\$sj\RoleCapabilities\JEA_CONFIG_$sj.psrc -VisibleCmdlets $vcl -Description $dsn | Out-Null



#Creating the config file which configures who can use it, from where and where to store optional transcripts
New-PSSessionConfigurationFile -Path .\JEA_ENDPOINT_CON_$sj.pssc -SessionType RestrictedRemoteServer -TranscriptDirectory c:\JEA\JEA_$sj\Transcripts_JEA_$sj  -RunAsVirtualAccount -RoleDefinitions @{ "$dm\$usr" = @{ RoleCapabilities = "JEA_CONFIG_$sj" } } | Out-Null #Creating the config file which configures who can use it, from where and where to store optional transcripts.


if(Test-PSSessionConfigurationFile -Path .\JEA_ENDPOINT_CON_$sj.pssc){
Write-Host "Configuration file is valid and has been created successfully." -ForegroundColor Green
Start-Sleep -Milliseconds 1000
Write-Host "Sending files over to other Domain Controller..." -ForegroundColor Yellow
Start-Sleep -Milliseconds 1000
Write-Host "Registering the PSSession on remote and local Domain Controller..." -ForegroundColor Yellow
Write-Host "Ignore the I/O Error, this is typical Windows reacting to not be given immediate access." -ForegroundColor Yellow
Start-Sleep -Milliseconds 1000

$sesh = New-PSSession $odc #Setup connection to other DC
##Push JEA Module to other DC's powershell
Copy-Item -Path C:\JEA\JEA_$sj\$sj -Destination 'C:\Program Files\WindowsPowerShell\Modules' -Recurse -ToSession $sesh -Force | Out-Null
Copy-Item -Path C:\JEA -Destination 'C:\' -Recurse -ToSession $sesh -Force | Out-Null
#Push JEA to LOCAL powershell
Copy-Item -Path C:\JEA\JEA_$sj\$sj -Destination 'C:\Program Files\WindowsPowerShell\Modules' -Recurse -Force  | Out-Null

#Register the JEA on the other DC's powershell
Invoke-Command -Session $sesh -ScriptBlock {Register-PSSessionConfiguration -Path C:\JEA\JEA_$Using:sj\JEA_ENDPOINT_CON_$Using:sj.pssc -Name $Using:sj -Force} | Out-Null
#Register the JEA on the LOCAL powershell
Invoke-Command -ScriptBlock {Register-PSSessionConfiguration -Path C:\JEA\JEA_$sj\JEA_ENDPOINT_CON_$sj.pssc -Name $sj -Force} | Out-Null

Write-Host "Succesfully created the following JEA Session:" -ForegroundColor Green
Write-Host "Subject: "$sj -ForegroundColor Red
Write-Host "Description: "$dsn -ForegroundColor Red
write-Host "User/group: "$usr -ForegroundColor White
Write-Host "Domain: "$dm -ForegroundColor white
Write-Host "Commandlets: "$vcl -ForegroundColor Cyan
write-Host "Starting folder: C:\JEA\JEA_$sj" -ForegroundColor Cyan


} else {
Write-Warning "Error 376141: Configuration file is somehow not valid, script didnt run succesfully... did you check permissions? : ~ Nick, the IT guy"
}