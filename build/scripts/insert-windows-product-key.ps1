# Insert a Windows product key in order to activate the currently-running
# operating system.

Set-StrictMode -Version 5.1
$ErrorActionPreference = "Stop"

$computer = gc env:computername

$service = Get-WmiObject -query "select * from SoftwareLicensingService" -computername $computer

$service.InstallProductKey($env:WINDOWS_PRODUCT_KEY)

$service.RefreshLicenseStatus()
