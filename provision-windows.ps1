$nvda_version = "2021.3.3"
$firefox_version = "97.0.1"
$geckodriver_version = "v0.30.0"

$nvda_url = "https://www.nvaccess.org/download/nvda/releases/${nvda_version}/nvda_${nvda_version}.exe"
$nvda_dest = "install-nvda-${nvda_version}.exe"

# `Start-BitsTransfer` cannot be used for this task because the nvaccess.org server
# does not support the relevant protocol
Invoke-WebRequest -Uri $nvda_url -OutFile $nvda_dest

# The `--install-silent` flag circumvents a prompt which interferes with unattended
# installation, and it also prevents NVDA from running immediately.
./install-nvda.exe --install-silent

& ./${nvda_dest} --install-silent

# Source: "Install an older version of Firefox"
# https://support.mozilla.org/en-US/kb/install-older-version-firefox
$firefox_url = "https://ftp.mozilla.org/pub/firefox/releases/${firefox_version}/win64/en-US/Firefox%20Setup%20${firefox_version}.exe"
$firefox_dest = "install-firefox-${firefox_version}.exe"

Start-BitsTransfer -Source $firefox_url -Destination $firefox_dest

# Source: "Firefox > Installer > Full Installer > Full Installer Configuration"
# https://firefox-source-docs.mozilla.org/browser/installer/windows/installer/FullConfig.html
& ./${firefox_dest} /S

# Source: "web-platform-tests/wpt browser.py"
# https://github.com/web-platform-tests/wpt/blob/d2985fa20494dd64e74adc6cfcb81b38318be694/tools/wpt/browser.py
$geckodriver_url = "https://github.com/mozilla/geckodriver/releases/download/${geckodriver_version}/geckodriver-${geckodriver_version}-win64.zip"
$geckodriver_dest = "geckodriver-${geckodriver_version}.zip"

Start-BitsTransfer -Source $geckodriver_url -Destination $geckodriver_dest

Expand-Archive -LiteralPath $geckodriver_dest -DestinationPath ./
