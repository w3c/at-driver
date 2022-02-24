$nvda_version = "2021.3.3"
$firefox_version = "97.0.1"
$geckodriver_version = "v0.30.0"

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

# Install an application from a .msi file, taking care to block
# until the process exits.
function Install-MsiFile($name) {
  $params = @{
    "FilePath" = "$Env:SystemRoot\system32\msiexec.exe"
    "ArgumentList" = @("/package", $name, "/quiet")
    "Verb" = "runas"
    "PassThru" = $true
  }

  $process = Start-Process @params
  $process.WaitForExit()
}

$nvda_url = "https://www.nvaccess.org/download/nvda/releases/${nvda_version}/nvda_${nvda_version}.exe"
$nvda_dest = "install-nvda-${nvda_version}.exe"

# `Start-BitsTransfer` cannot be used for this task because the nvaccess.org server
# does not support the relevant protocol
log 'Downloading NVDA'
Invoke-WebRequest -Uri $nvda_url -OutFile $nvda_dest

# The `--install-silent` flag circumvents a prompt which interferes with unattended
# installation, and it also prevents NVDA from running immediately.
log 'Installing NVDA'
#./install-nvda.exe --install-silent
& ./${nvda_dest} --install-silent

# Source: "Install an older version of Firefox"
# https://support.mozilla.org/en-US/kb/install-older-version-firefox
$firefox_url = "https://ftp.mozilla.org/pub/firefox/releases/${firefox_version}/win64/en-US/Firefox%20Setup%20${firefox_version}.msi"
$firefox_dest = "install-firefox-${firefox_version}.msi"
log 'Downloading Firefox'
Start-BitsTransfer -Source $firefox_url -Destination $firefox_dest

# Source: "Firefox > Installer > Full Installer > Full Installer Configuration"
# https://firefox-source-docs.mozilla.org/browser/installer/windows/installer/FullConfig.html
#& ./${firefox_dest} /S
#msiexec.exe /package ${firefox_dest} /quiet
log 'Installing Firefox'
Install-MsiFile $firefox_dest

# Source: "web-platform-tests/wpt browser.py"
# https://github.com/web-platform-tests/wpt/blob/d2985fa20494dd64e74adc6cfcb81b38318be694/tools/wpt/browser.py
$geckodriver_url = "https://github.com/mozilla/geckodriver/releases/download/${geckodriver_version}/geckodriver-${geckodriver_version}-win64.zip"
$geckodriver_dest = "geckodriver-${geckodriver_version}.zip"

log 'Downloading Geckodriver'
Start-BitsTransfer -Source $geckodriver_url -Destination $geckodriver_dest

log 'Installing Geckodriver'
Expand-Archive -LiteralPath $geckodriver_dest -DestinationPath ./
