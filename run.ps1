param(
    [string]
    $branch = "2.0.x",

    [string]
    $commit = "",

    [Switch]
    $configsOnly
)
$MARLIN_BRANCH = $branch

function Compute-Sha([string] $file)
{
    if (Test-Path $file)
    {
        $hash = Get-FileHash -Algorithm SHA256 -Path $file
        return $hash.Hash
    }

    return ""
}

function Download-File([string] $file, [string] $url)
{
    Invoke-WebRequest -Uri $url -OutFile download.temp
    if ((Compute-Sha -file $file) -ne (Compute-Sha -file download.temp))
    {
        Copy-Item download.temp $file -Force
    }
    Remove-Item download.temp
}

Download-File -file "./temp/marlinlatest" -url "https://api.github.com/repos/MarlinFirmware/Marlin/branches/${MARLIN_BRANCH}"

if ($commit -ne "")
{
    $MARLIN_BRANCH = $commit
}

if ($configsOnly -eq $true)
{
    docker image build --build-arg MARLIN_BRANCH=${MARLIN_BRANCH} -t marlinconfigs -f ./Dockerfile-Configs .
    $containerId = & docker container create -it marlinconfigs /bin/sh
    mkdir configs -ErrorAction SilentlyContinue | Out-Null

    docker cp ${containerId}:/marlin/. configs

    docker rm $containerId
}
else {
    Download-File -file "./temp/arduino-cli.tar.gz" -url "https://downloads.arduino.cc/arduino-cli/arduino-cli_latest_Linux_64bit.tar.gz"

    docker image build --build-arg MARLIN_BRANCH=${MARLIN_BRANCH} -t marlin .
    $containerId = & docker container create -it marlin /bin/sh
    mkdir build -ErrorAction SilentlyContinue | Out-Null

    docker cp ${containerId}:/marlin/. build

    docker rm $containerId
}