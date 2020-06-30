# This script is used to configure the Docker service for Windows builds in Travis CI
Write-Host "Configuring Docker service to listen on TCP port 2375..."
$dockerSvcArgs = (Get-WmiObject Win32_Service | ?{$_.Name -eq 'docker'} | Select PathName).PathName
$dockerSvcArgs = "$dockerSvcArgs -H tcp://0.0.0.0:2375 -H npipe:////./pipe/docker_engine"
Write-Host "Docker Service Args: $dockerSvcArgs"

Get-WmiObject Win32_Service -Filter "Name='docker'" | Invoke-WmiMethod -Name Change -ArgumentList @($null,$null,$null,$null,$null, $dockerSvcArgs) | Out-Null

Restart-Service docker -Force -Verbose
