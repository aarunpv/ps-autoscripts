$vms = Import-CSV "PATH TO CSV FILE"
foreach ($vm in $vms) {
Invoke-VMScript -vm $vm.name -GuestUser administrator -GuestPassword EMCDemo1@ -ScriptType Powershell '$password = "Physec1@" | ConvertTo-SecureString -asPlainText -Force
$username = "$vs\administrator" 
$credential = New-Object System.Management.Automation.PSCredential($username,$password)
Add-Computer vs.local.com -Credential $credential'
foreach ($vm in $vms) {
}}
