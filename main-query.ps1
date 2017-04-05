param (
    [STRING]$customerUsername = "***MCPUSERNAME***",
    [STRING]$customerPassword = "***MCPPASSWORD***"
)

$ErrorActionPreference= 'stop'
$strFileName = "$PSScriptRoot\outputfile.csv"
$regions = @("AF","AP","AU","EU","NA")

################################################################################################
## DO NOT EDIT BELOW THIS LINE
##
## Author: Jonathan Ment
##         Dimension Data
##
################################################################################################

function FixDate ($Value) {
    $origin = New-Object -Type DateTime -ArgumentList 1970, 1, 1, 0, 0, 0, 0
    $whatIWant = $origin.AddSeconds($value)
    Return $whatIWant
}

CLEAR

If (Test-Path $strFileName){
	Remove-Item $strFileName
}


foreach ($region in $regions) {

    Write-Host "Processing ... $region"

    $securepassword = ConvertTo-SecureString $customerPassword -AsPlainText -Force
    $credentials = New-Object System.Management.Automation.PSCredential($customerUsername,$securepassword)

    $BaseURI = "https://$region-monitoring.mcp-services.net"

    $URI = "$BaseURI/api/device?limit=500"

    try {

        $devices = Invoke-WebRequest -Uri $URI -Credential $credentials
        $devices = $devices.RawContent
        $devices = $devices.Substring($devices.IndexOf("{"))
        $devices = ConvertFrom-Json -InputObject $devices
        $devices = $devices.result_set

        foreach ($device in $devices) {

            $URI = $device.URI
            $MachineName = $device.Description
            $deviceID = $URI.split("/")
            $deviceID = $deviceID[3]

            $MachineName = $MachineName.Split("/")
            $MachineName = $MachineName[1]

            # Need to go query the data for this deviceID
            $URI = "$BaseURI/$URI"

            Write-Host "-- Processing ... $MachineName ($deviceID)"

            try {

                $link = Invoke-WebRequest -Uri $URI -Credential $credentials
                $link = $link.RawContent
                $link = $link.Substring($link.IndexOf("{"))
                $link = ConvertFrom-Json -InputObject $link
                $link = $link.vitals
                $link = $link.URI


                $URI = "$BaseURI/$link"

                try {

                    $vitals = Invoke-WebRequest -Uri $URI -Credential $credentials
                    $vitals = $vitals.RawContent
                    $vitals = $vitals.Substring($vitals.IndexOf("{"))
                    $vitals = ConvertFrom-Json -InputObject $vitals
                
                    $availability = $vitals.availability.data.URI
                    $cpu = $vitals.cpu.data.URI
                    $memory = $vitals.memory.data.URI
                
                    # Availability performance metrics
                    $URI = "$BaseURI/$availability"
                    try {
                        $availability = Invoke-WebRequest -Uri $URI -Credential $credentials
                        $availability = $availability.RawContent
                        $availability = $availability.Substring($availability.IndexOf("{"))
                        $availability = ConvertFrom-Json -InputObject $availability
                        $availability = $availability.data.d_check | out-string
                        $availability = $availability.replace(" ","")
                        $availability = $availability.replace("`n",":")
                        $availability = $availability.replace("`r",":")

                        $availability = $availability.replace("::",":")
                        $availability = $availability.replace("::","")
                        $availability = $availability.Trim()
                        $availability = $availability.split(":")

                        for($i=0;$i -lt $availability.count;$i+=2) {
                            $datestamp = FixDate($availability[$i])
                            $value  = $availability[$i+1]
                            #If ($value -eq 1) { $value = "On" } else { $value = "Off" }
                            $output = "$region,$machinename,Availability,$datestamp,$value"
                            $output | out-file -NoClobber -FilePath $strFileName -Append
                        }


                    } catch {
                        # Do nothing if an error occurred
                        $ErrorMessage = $_.Exception.Message
                    }
                
                    # CPU Performance Metrics
                    $URI = "$BaseURI/$cpu"
                    try {
                        $cpu = Invoke-WebRequest -Uri $URI -Credential $credentials
                        $cpu = $cpu.RawContent
                        $cpu = $cpu.Substring($cpu.IndexOf("{"))
                        $cpu = ConvertFrom-Json -InputObject $cpu
                        $cpu = $cpu.data.0 | out-string
                        $cpu = $cpu.replace(" ","")
                        $cpu = $cpu.replace("`n",":")
                        $cpu = $cpu.replace("`r",":")

                        $cpu = $cpu.replace("::",":")
                        $cpu = $cpu.replace("::","")
                        $cpu = $cpu.Trim()
                        $cpu = $cpu.split(":")

                        for($i=0;$i -lt $cpu.count;$i+=2) {
                            $datestamp = FixDate($cpu[$i])
                            $value  = $cpu[$i+1]
                            $output = "$region,$machinename,CPU,$datestamp,$value"
                            $output | out-file -NoClobber -FilePath $strFileName -Append
                        }

                    } catch {
                        # Do nothing if an error occurred
                        $ErrorMessage = $_.Exception.Message
                    }
                
                    $URI = "$BaseURI/$memory"
                    try {
                        $memory = Invoke-WebRequest -Uri $URI -Credential $credentials
                        $memory = $memory.RawContent
                        $memory = $memory.Substring($memory.IndexOf("{"))
                        $memory = ConvertFrom-Json -InputObject $memory
                        $memory = $memory.data.0 | out-string
                        $memory = $memory.replace(" ","")
                        $memory = $memory.replace("`n",":")
                        $memory = $memory.replace("`r",":")

                        $memory = $memory.replace("::",":")
                        $memory = $memory.replace("::","")
                        $memory = $memory.Trim()
                        $memory = $memory.split(":")

                        for($i=0;$i -lt $memory.count;$i+=2) {
                            $datestamp = FixDate($memory[$i])
                            $value  = $memory[$i+1]
                            $output = "$region,$machinename,Memory,$datestamp,$value"
                            $output | out-file -NoClobber -FilePath $strFileName -Append
                        }

                    } catch {
                        # Do nothing if an error occurred
                        $ErrorMessage = $_.Exception.Message
                    }

                } catch {
                    # Do nothing if an error occurred
                    $ErrorMessage = $_.Exception.Message
                }

            } catch {
                # Do nothing if an error occurred
                $ErrorMessage = $_.Exception.Message
            }

        }

    } catch {
        # Do nothing if an error occurred
        $ErrorMessage = $_.Exception.Message
    }

}

Write-Host ""
Write-Host "-- $strFileName successfully created!"

