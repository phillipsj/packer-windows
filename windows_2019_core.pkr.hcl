packer {
  required_plugins {
    windows-update = {
      version = "0.14.0"
      source = "github.com/rgl/windows-update"
    }
  }
}

variable "autounattend" {
  type    = string
  default = "./answer_files/2019_core/Autounattend.xml"
}

variable "disk_size" {
  type    = string
  default = "61440"
}

variable "disk_type_id" {
  type    = string
  default = "1"
}

variable "headless" {
  type    = string
  default = "false"
}

variable "iso_checksum" {
  type    = string
  default = "sha256:549bca46c055157291be6c22a3aaaed8330e78ef4382c99ee82c896426a1cee1"
}

variable "iso_url" {
  type    = string
  default = "https://software-download.microsoft.com/download/pr/17763.737.190906-2324.rs5_release_svc_refresh_SERVER_EVAL_x64FRE_en-us_1.iso"
}

variable "manually_download_iso_from" {
  type    = string
  default = "https://www.microsoft.com/en-us/evalcenter/evaluate-windows-server-2019"
}

variable "memory" {
  type    = string
  default = "2048"
}

variable "virtio_win_iso" {
  type    = string
  default = "~/virtio-win.iso"
}

variable "winrm_timeout" {
  type    = string
  default = "6h"
}

variable "hyperv_switchname" {
  type    = string
  default = "Default"
}

variable "aws_s3_bucket_name" {
  type    = string
  default = "${env("AWS_S3_BUCKET")}"
}

source "hyperv-iso" "hyperv" {
  boot_wait             = "0s"
  communicator          = "winrm"
  configuration_version = "8.0"
  cpus                  = 2
  disk_size             = "${var.disk_size}"
  enable_secure_boot    = true
  floppy_files          = ["${var.autounattend}", "./scripts/disable-screensaver.ps1", "./scripts/disable-winrm.ps1", "./scripts/enable-winrm.ps1", "./scripts/microsoft-updates.bat", "./scripts/win-updates.ps1"]
  guest_additions_mode  = "disable"
  iso_checksum          = "${var.iso_checksum}"
  iso_url               = "${var.iso_url}"
  memory                = "${var.memory}"
  shutdown_command      = "shutdown /s /t 10 /f /d p:4:1 /c \"Packer Shutdown\""
  switch_name           = "${var.hyperv_switchname}"
  vm_name               = "WindowsServer2019Core"
  winrm_password        = "vagrant"
  winrm_timeout         = "${var.winrm_timeout}"
  winrm_username        = "vagrant"
}

source "qemu" "qemu" {
  accelerator      = "kvm"
  boot_wait        = "0s"
  communicator     = "winrm"
  cpus             = 2
  disk_size        = "${var.disk_size}"
  floppy_files     = ["${var.autounattend}", "./scripts/disable-screensaver.ps1", "./scripts/disable-winrm.ps1", "./scripts/enable-winrm.ps1", "./scripts/microsoft-updates.bat", "./scripts/win-updates.ps1"]
  headless         = true
  iso_checksum     = "${var.iso_checksum}"
  iso_url          = "${var.iso_url}"
  memory           = "${var.memory}"
  output_directory = "windows_2019_docker-qemu"
  qemuargs         = [["-drive", "file=windows_2019-qemu/{{ .Name }},if=virtio,cache=writeback,discard=ignore,format=qcow2,index=1"], ["-drive", "file=${var.iso_url},media=cdrom,index=2"], ["-drive", "file=${var.virtio_win_iso},media=cdrom,index=3"]]
  shutdown_command = "shutdown /s /t 10 /f /d p:4:1 /c \"Packer Shutdown\""
  vm_name          = "WindowsServer2019Docker"
  winrm_password   = "vagrant"
  winrm_timeout    = "${var.winrm_timeout}"
  winrm_username   = "vagrant"
}

source "virtualbox-iso" "virtualbox" {
  boot_wait            = "2m"
  communicator         = "winrm"
  cpus                 = 2
  disk_size            = "${var.disk_size}"
  floppy_files         = ["${var.autounattend}", "./scripts/disable-screensaver.ps1", "./scripts/disable-winrm.ps1", "./scripts/enable-winrm.ps1", "./scripts/microsoft-updates.bat", "./scripts/win-updates.ps1"]
  guest_additions_mode = "disable"
  guest_os_type        = "Windows2016_64"
  headless             = "${var.headless}"
  iso_checksum         = "${var.iso_checksum}"
  iso_url              = "${var.iso_url}"
  memory               = "${var.memory}"
  shutdown_command     = "shutdown /s /t 10 /f /d p:4:1 /c \"Packer Shutdown\""
  winrm_password       = "vagrant"
  winrm_timeout        = "${var.winrm_timeout}"
  winrm_username       = "vagrant"
}

source "vmware-iso" "vmware" {
  boot_wait         = "2m"
  communicator      = "winrm"
  cpus              = 2
  disk_adapter_type = "lsisas1068"
  disk_size         = "${var.disk_size}"
  disk_type_id      = "${var.disk_type_id}"
  floppy_files      = ["${var.autounattend}", "./scripts/disable-screensaver.ps1", "./scripts/disable-winrm.ps1", "./scripts/enable-winrm.ps1", "./scripts/microsoft-updates.bat", "./scripts/win-updates.ps1"]
  guest_os_type     = "windows9srv-64"
  headless          = "${var.headless}"
  iso_checksum      = "${var.iso_checksum}"
  iso_url           = "${var.iso_url}"
  memory            = "${var.memory}"
  shutdown_command  = "shutdown /s /t 10 /f /d p:4:1 /c \"Packer Shutdown\""
  vmx_data = {
    "RemoteDisplay.vnc.enabled" = "false"
    "RemoteDisplay.vnc.port"    = "5900"
  }
  vmx_remove_ethernet_interfaces = true
  vnc_port_max                   = 5980
  vnc_port_min                   = 5900
  winrm_password                 = "vagrant"
  winrm_timeout                  = "${var.winrm_timeout}"
  winrm_username                 = "vagrant"
}

build {
  sources = ["source.hyperv-iso.hyperv", "source.qemu.qemu", "source.virtualbox-iso.virtualbox", "source.vmware-iso.vmware"]

  provisioner "windows-shell" {
    scripts = ["./scripts/enable-rdp.bat"]
  }

  provisioner "powershell" {
    scripts = ["./scripts/vm-guest-tools.ps1", "./scripts/debloat-windows.ps1"]
  }

  provisioner "windows-shell" {
    scripts = ["./scripts/set-winrm-automatic.bat", "./scripts/uac-enable.bat", "./scripts/compile-dotnet-assemblies.bat", "./scripts/dis-updates.bat", "./scripts/compact.bat"]
  }

  post-processor "vagrant" {
    keep_input_artifact  = false
    output               = "windows_2019_core_<no value>.box"
    vagrantfile_template = "vagrantfile-windows_2019_core.template"
  }

  post-processor "amazon-import" {
    keep_input_artifact = false
    access_key          = ""
    ami_name            = "packer_windows_2019_core"
    license_type        = "BYOL"
    only                = ["virtualbox-iso"]
    region              = ""
    s3_bucket_name      = "${var.aws_s3_bucket_name}"
    secret_key          = ""
    tags = {
      Description = "packer-windows 2019 core amazon-import ${local.timestamp}"
    }
  }
}
