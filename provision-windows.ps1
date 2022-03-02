$nvda_version = "2021.3.3"
$firefox_version = "97.0.1"
$geckodriver_version = "v0.30.0"
$nodejs_version = "16.14.0"

function log([string]$message) {
  echo "$(Get-Date -Uformat '[%Y-%m-%d %H:%M:%S]') $message"
}

# Source: "Check if a Software Program Is Installed using PowerShell Script"
# https://morgantechspace.com/2018/02/check-if-software-program-is-installed-powershell.html
function Confirm-ProgramInstalled {
  param (
    [Parameter(Mandatory=$true)] [string]$programName
  )

  $x86_check = ((Get-ChildItem "HKLM:Software\Microsoft\Windows\CurrentVersion\Uninstall") |
    Where-Object { $_."Name" -like "*$programName*" } ).Length -gt 0;

  if(Test-Path 'HKLM:Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall') {
    $x64_check = ((Get-ChildItem "HKLM:Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall") |
      Where-Object { $_."Name" -like "*$programName*" } ).Length -gt 0;
  }

  return $x86_check -or $x64_check;
}

function Wait-ProgramInstalled {
  param (
    [Parameter(Mandatory=$true)] [string]$programName,
    [Parameter(Mandatory=$true)] [int]$timeout
  )

  $args = @{
    programName = $programName
  }
  $start = $(Get-Date -UFormat %s)

  while ( $false -eq (Confirm-ProgramInstalled @args) ) {
    $now = $(Get-Date -UFormat %s)

    if ( ($now - $start) -gt $timeout ) {
      throw "Timed out waiting $timeout seconds for $programName to be installed."
    }
  }
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

mkdir -Force downloads | Out-Null

$python_url = "https://www.python.org/ftp/python/${python_version}/python-${python_version}-amd64.exe"
$python_dest = "downloads/install-python-${python_version}.exe"

#log 'Downloading Python'
#Start-BitsTransfer -Source $python_url -Destination $python_dest

#log 'Installing Python'
#Install-ExeFile $python_dest '/quiet'

$nodejs_url = "https://nodejs.org/dist/v${nodejs_version}/node-v${nodejs_version}-x64.msi"
$nodejs_dest = "downloads/install-nodejs-${nodejs_version}.msi"

log 'Downloading Node.js'
Start-BitsTransfer -Source $nodejs_url -Destination $nodejs_dest

log 'Installing Node.js'
Install-MsiFile $nodejs_dest

$git_url = 'https://github.com/git-for-windows/git/releases/download/v2.35.1.windows.2/Git-2.35.1.2-64-bit.exe'
$git_dest = 'downloads/install-git.exe'

log 'Downloading Git'
Start-BitsTransfer -Source $git_url -Destination $git_dest

log 'Installing Git'
Install-ExeFile $git_dest '/verysilent'

$nvda_url = "https://www.nvaccess.org/download/nvda/releases/${nvda_version}/nvda_${nvda_version}.exe"
$nvda_dest = "downloads/install-nvda-${nvda_version}.exe"

# `Start-BitsTransfer` cannot be used for this task because the nvaccess.org server
# does not support the relevant protocol
log 'Downloading NVDA'
Invoke-WebRequest -Uri $nvda_url -OutFile $nvda_dest

# The `--install-silent` flag circumvents a prompt which interferes with unattended
# installation, and it also prevents NVDA from running immediately.
log 'Installing NVDA'
Install-ExeFile $nvda_dest '--install-silent'

# Source: "Install an older version of Firefox"
# https://support.mozilla.org/en-US/kb/install-older-version-firefox
$firefox_url = "https://ftp.mozilla.org/pub/firefox/releases/${firefox_version}/win64/en-US/Firefox%20Setup%20${firefox_version}.msi"
$firefox_dest = "downloads/install-firefox-${firefox_version}.msi"

log 'Downloading Firefox'
Start-BitsTransfer -Source $firefox_url -Destination $firefox_dest

# Source: "Firefox > Installer > Full Installer > Full Installer Configuration"
# https://firefox-source-docs.mozilla.org/browser/installer/windows/installer/FullConfig.html
log 'Installing Firefox'
Install-MsiFile $firefox_dest

# Disable automatic updates in Firefox
# Source: "mozilla/policy-templates Policy Templates for Firefox"
# https://github.com/mozilla/policy-templates/blob/master/README.md#disableappupdate
# See also: "Using PowerShell to write a file in UTF-8 without the BOM"
# https://stackoverflow.com/questions/5596982/using-powershell-to-write-a-file-in-utf-8-without-the-bom
$firefox_distribution_dir = "$Env:ProgramFiles\Mozilla Firefox\distribution"
mkdir -Force $firefox_distribution_dir | Out-Null
[IO.File]::WriteAllLines(
  "$firefox_distribution_dir\policies.json",
  '{"policies":{"DisableAppUpdate":true}}'
)

# Source: "web-platform-tests/wpt browser.py"
# https://github.com/web-platform-tests/wpt/blob/d2985fa20494dd64e74adc6cfcb81b38318be694/tools/wpt/browser.py
$geckodriver_url = "https://github.com/mozilla/geckodriver/releases/download/${geckodriver_version}/geckodriver-${geckodriver_version}-win64.zip"
$geckodriver_dest = "downloads/geckodriver-${geckodriver_version}.zip"

log 'Downloading Geckodriver'
Start-BitsTransfer -Source $geckodriver_url -Destination $geckodriver_dest

log 'Installing Geckodriver'
Expand-Archive -LiteralPath $geckodriver_dest -DestinationPath ./downloads

log 'Done'
