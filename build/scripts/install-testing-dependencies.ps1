# Download and install the software which is required by the automated testing
# infrastructure. This does not include applications like web browsers or
# screen readers, as these will be installed immediately prior to test
# execution according to the versions specified at that moment.

Set-StrictMode -Version 5.1
$ErrorActionPreference = "Stop"

$nodejs_version = "16.14.0"

function log([string]$message) {
  echo "$(Get-Date -Uformat '[%Y-%m-%d %H:%M:%S]') $message"
}

# Install an application from a `.exe` file, taking care to block
# until the process exits and to throw if the process fails.
function Install-ExeFile([string]$name, [string]$option) {
  $params = @{
    "FilePath" = $name
    "ArgumentList" = @($option)
    "Verb" = "runas"
    "PassThru" = $true
  }

  $process = Start-Process @params
  $process.WaitForExit()

  if (($process.ExitCode) -ne 0) {
    throw "Error installing $name"
  }
}

# Install an application from a `.msi` file, taking care to block
# until the process exits and to throw if the process fails.
function Install-MsiFile([string]$name) {
  $absolute_path = (Resolve-Path $name).ToString()
  $params = @{
    "FilePath" = "$Env:SystemRoot\system32\msiexec.exe"
    "ArgumentList" = @("/package", $absolute_path, "/quiet")
    "Verb" = "runas"
    "PassThru" = $true
  }

  $process = Start-Process @params
  $process.WaitForExit()

  if (($process.ExitCode) -ne 0) {
    throw "Error installing $name"
  }
}

$downloads = "${env:TEMP}\downloads"

mkdir -Force $downloads | Out-Null

$nodejs_url = "https://nodejs.org/dist/v${nodejs_version}/node-v${nodejs_version}-x64.msi"
$nodejs_dest = "${downloads}\install-nodejs-${nodejs_version}.msi"

log "Downloading Node.js version ${nodejs_version}"
Start-BitsTransfer -Source $nodejs_url -Destination $nodejs_dest

log "Installing Node.js version ${nodejs_version}"
Install-MsiFile $nodejs_dest

$git_url = 'https://github.com/git-for-windows/git/releases/download/v2.35.1.windows.2/Git-2.35.1.2-64-bit.exe'
$git_dest = "${downloads}\install-git.exe"

log 'Downloading Git'
Start-BitsTransfer -Source $git_url -Destination $git_dest

log 'Installing Git'
Install-ExeFile $git_dest '/verysilent'

$vc_runtime_url = 'https://aka.ms/vs/16/release/vc_redist.x86.exe'
$vc_runtime_dest = "${downloads}\install-vc-runtime.exe"

log 'Downloading Visual C++ runtime'

Start-BitsTransfer -Source $vc_runtime_url -Destination $vc_runtime_dest

log 'Installing Visual C++ runtime'

Install-ExeFile $vc_runtime_dest '/quiet'

rm -r $downloads

log 'Done'
