param (
    [string]$VC,
    [string]$VCuser, 
    [string]$VCpassword
)
Connect-VIServer -Server $VC -User $VCuser -Password $VCpassword
