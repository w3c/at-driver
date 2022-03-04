variable "windows_product_key" {
  type = string
}

source "virtualbox-ovf" "customized" {
  source_path = "output-generic/windows_10.ovf"
  ssh_username = "packer"
  ssh_password = "packer"
  guest_additions_mode = "disable"
  shutdown_command = "shutdown /s /t 10 /f /d p:4:1 /c \"Packer Shutdown\""
  communicator = "winrm"
  winrm_username = "vagrant"
  winrm_password = "vagrant"

  # The "automation voice" requires access to a valid audio device.
  #
  # Parameter documentation:
  # https://docs.oracle.com/en/virtualization/virtualbox/6.0/user/vboxmanage-modifyvm.html
  vboxmanage = [
    ["modifyvm", "{{.Name}}", "--audio", "pulse"],
    ["modifyvm", "{{.Name}}", "--audiocontroller", "hda"],
    ["modifyvm", "{{.Name}}", "--audioout", "on"],
  ]
}

build {
  sources = ["sources.virtualbox-ovf.customized"]

  provisioner "powershell" {
    scripts = [
      "./scripts/install-testing-dependencies.ps1"
    ]
    elevated_user = "SYSTEM"
    elevated_password = ""
  }

  provisioner "powershell" {
    scripts = [
      "./scripts/insert-windows-product-key.ps1"
    ]
    environment_vars = [
      "WINDOWS_PRODUCT_KEY=${var.windows_product_key}"
    ]
    elevated_user = "SYSTEM"
    elevated_password = ""
  }
}
