Set-Location $PSScriptRoot

if ( (git rev-parse --abbrev-ref HEAD) -eq "master") {
  git reset --hard HEAD | Out-Null
  git pull -f | Out-Null
}

$training = ($args[0])
$stackFile = New-TemporaryFile | Rename-Item -NewName { $_ -replace '.tmp$', ".playpit-labs.$($training)" } –PassThru

$url = "https://playpit-labs-assets.s3-eu-west-1.amazonaws.com/docker-compose/sbeliakou-$($args[0]).yml"
Try { 
  (New-Object System.Net.WebClient).DownloadFile($url, $stackFile)
} Catch {
  Write-Output "Please specify 'training name'
  
Usage:
  start.ps1 {training name}

Available trainings:
  kubernetes
  docker
"
  exit 1
}

Write-Output "Cleaning Up"
docker ps -q --filter label=lab | ForEach-Object { docker rm -f $_ }
docker volume ls --filter label=lab -q | ForEach-Object { docker volume rm -f $_ }
docker network ls --filter label=lab -q | ForEach-Object {docker network rm $_ }

Write-Output "Pulling updates"
docker-compose -f $stackFile pull

Write-Output "Starting New Stack"
docker-compose -f $stackFile up -d --renew-anon-volumes --remove-orphans
Remove-Item -Path $stackFile -Force

Write-Output "`nReady! Browse: http://lab.playpit.net:8081`n"