param (
    [string]$VC,
    [string]$VCuser, 
    [String]$VCpassword,
    [string]$ESXiuser, 
    [String]$ESXipassword,
    [string]$SNMPcommunity,
    [string]$LOGserver
        )

##Function to create a timestamp
function Get-TimeStamp 
{
    return "[{0:MM/dd/yy} {0:HH:mm:ss}]" -f (Get-Date)
}

function Set-SNMP 
{
        Get-VMHostSnmp | Set-VMHostSnmp -ReadonlyCommunity @()
        Get-VMHostSnmp | Set-VMHostSnmp -Enabled:$true  -ReadOnlyCommunity $SNMPcommunity
        Get-VMHostSnmp | set-VMHostSnmp -Targethost $LOGserver -targetcommunity $SNMPcommunity -AddTarget    
        Write-Output "$(Get-TimeStamp) $esxihost : Current SNMP config ==> Community string: $SNMPcommunity SNMP Trapserver: $LOGserver " >> $logpath\snmpenabled.txt
}

# Connect to vcenter and generate list of esxihosts
Connect-VIServer -Server $VC -User $VCuser -Password $VCpassword
$esxihosts = (Get-VMHost).Name
Disconnect-VIServer -Server * -Confirm:$false
$logpath = (get-location).Path
#Write-Host $logpath $esxihosts


foreach ($esxihost in $esxihosts)
{
    connect-viserver $esxihost -User $ESXiuser -Password $ESXipassword -ErrorVariable out 2>$null
    Start-Sleep 2

    if($out)
    {
        Write-Output "$(Get-TimeStamp) connection to $esxihost failed" $out >> $logpath\snmperrors.txt
    }

    else 
    {
          if ((Get-VMHostSnmp).Enabled) 
          {
            $old_snmp = (Get-VMHostSnmp).ReadOnlyCommunities
            $old_trapserver = (Get-VMHostSnmp).TrapTargets.HostName
            
            if ($old_snmp -ceq $SNMPcommunity -and $old_trapserver -eq $LOGserver )
            {
                Write-Output "$(Get-TimeStamp) $esxihost : No changes to SNMP config " >> $logpath\snmpenabled.txt
            }
            
            elseif ($old_snmp -ceq $SNMPcommunity -and $old_trapserver -ne $LOGserver) 
            {
                Write-Output "$(Get-TimeStamp) $esxihost : Changed SNMP trap server from $old_trapserver to $LOGserver" >> $logpath\snmpenabled.txt 
                Set-SNMP -SNMPcommunity $SNMPcommunity -LOGserver $LOGserver  
            }

            elseif ($old_snmp -ne $SNMPcommunity -and $old_trapserver -eq $LOGserver) 
            {
                Write-Output "$(Get-TimeStamp) $esxihost : Changed SNMP community string from $old_snmp to $SNMPcommunity" >> $logpath\snmpenabled.txt
                Set-SNMP -SNMPcommunity $SNMPcommunity -LOGserver $LOGserver
            }

            else 
            {
                Write-Output "$(Get-TimeStamp) $esxihost : SNMP reconfigured Old SNMP config ==> Community string: $old_snmp SNMP Trapserver: $old_trapserver " >> $logpath\snmpenabled.txt
                Set-SNMP -SNMPcommunity $SNMPcommunity -LOGserver $LOGserver
            }
            
          }  
          else
          {
            Write-Output "$(Get-TimeStamp) $esxihost : enabled SNMP service" >> $logpath\snmpenabled.txt
            Set-SNMP -SNMPcommunity $SNMPcommunity -LOGserver $LOGserver
          }
          
          disconnect-viserver * -confirm:$false
    }
}

