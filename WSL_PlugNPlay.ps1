# Get script file path and name
$currentExePath = [System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName
$currentPs1Path = $MyInvocation.MyCommand.Path

# Check if running as an .exe file
$isRunningAsExe = $currentExePath.EndsWith('.exe') # TODO: eventually add the ability for the script
                                                   # to run as admin by itself based on whether it is
                                                   # run from a .ps1 or .exe file

# Use the appropriate file path depending on the execution type
$currentFileName = [System.IO.Path]::GetFileNameWithoutExtension($currentExePath)
$exeFullPath = Join-Path -Path (Get-Location) -ChildPath "$currentFileName.exe"

# Determine whether running as admin and elevates permissions accordingly
# If user selects 'no' warn user that program needs admin
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    try {
        if ($isRunningAsExe) {
            Start-Process -FilePath $exeFullPath -Verb Runas -ErrorAction Stop
        } else {
            Start-Process -FilePath Powershell.exe -Verb RunAs -ArgumentList "& '$currentPs1Path'"
        }
    } catch {
        Add-Type -AssemblyName System.Windows.Forms
        $shell = New-Object -ComObject Wscript.Shell
        $answer = $shell.Popup("This program must be run as Administrator.", 0, "Administrator Privileges Required", [System.Windows.Forms.MessageBoxButtons]::OK)
        Exit
    }
    Exit
}

# Load required assemblies
Add-Type -AssemblyName System.Windows.Forms

# Use usbipd to get a list of all externally attached USB devices
$usbDevices = & wsl.exe usbipd.exe wsl list | Select-String -Pattern "^([\d\w-]+)\s+([\d\w:]+)\s+(.+)\s+Not attached$" | ForEach-Object {
  $busId = $_.Matches.Groups[1].Value
  $vidPid = $_.Matches.Groups[2].Value
  $deviceName = $_.Matches.Groups[3].Value.Trim()
  [PSCustomObject]@{
    BusId = $busId
    VIDPID = $vidPid
    DeviceName = $deviceName
    Attach = $false
  }
}

# Check if any devices are attached
function AreAnyDevicesAttached {
  return ($usbDevices | Where-Object { $device.Attach -eq $true }).Count -gt 0
}

# Detach all devices on close
function DetachAllDevicesBeforeClosing {
  $attachedDevices = $usbDevices | Where-Object { $_.Attach -eq $true }
  foreach ($device in $attachedDevices) {
    & wsl.exe usbipd.exe wsl detach --busid $device.BusId
    $device.Attach = $false
  }
}

# Display list of all attached USB devices with checkboxes
$form = New-Object System.Windows.Forms.Form
$form.Text = "Select which USB devices to attach or detach"
$form.Size = New-Object System.Drawing.Size(500, 400)
$form.StartPosition = "CenterScreen"

$checkedListBox = New-Object System.Windows.Forms.CheckedListBox
$checkedListBox.Size = New-Object System.Drawing.Size(460, 250)
$checkedListBox.Location = New-Object System.Drawing.Point(10, 10)
$checkedListBox.CheckOnClick = $true
$checkedListBox.Font = New-Object System.Drawing.Font("Consolas", 10) # Adjust the font style/size here (e.g. "Consolas", 12)
$form.Controls.Add($checkedListBox)
$form.Add_Shown({$form.Activate()})

foreach ($device in $usbDevices) {
  $text = "$($device.DeviceName) ($($device.VIDPID)) [$($device.BusId)]"
  $checkedListBox.Items.Add($text, $device.Attach) | Out-Null
}

# Attach devices in real time, based on checkbox status
$checkedListBox.Add_MouseClick({
  $clickedIndex = $checkedListBox.IndexFromPoint($_.Location)
  if ($clickedIndex -ge 0 -and $clickedIndex -lt $checkedListBox.Items.Count) {
    $checkBoxState = $checkedListBox.GetItemChecked($clickedIndex)
    $device = $usbDevices[$clickedIndex]
    if (-not $checkBoxState) {
      & wsl.exe usbipd.exe wsl attach --busid $device.BusId
    } else {
      & wsl.exe usbipd.exe wsl detach --busid $device.BusId
    }
    # Update the device.Attach status in the $usbDevices array
    $usbDevices[$clickedIndex].Attach = -not $checkBoxState
  }
})

# If devices are attached on closing, prompt the user to detach all devices
# If the user answers 'no' display warning box with instructions to manually detach devices
$form.Add_FormClosing({
  if (AreAnyDevicesAttached) {
    $e = $_.Exception
    $messageBoxResult = [System.Windows.Forms.MessageBox]::Show("Do you want to detach all devices before exiting?", "Detach devices", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Question)
    if ($messageBoxResult -eq "Yes") {
      DetachAllDevicesBeforeClosing
    } else {
      [System.Windows.Forms.MessageBox]::Show("If you want to detach device manually after exiting, either physically disconnect the device or use the following command in powershell administrator: `n`nusbipd wsl detach --busid <busid>`n`nReplace <busid> with the corresponding BusId of the device. `n`nMake sure you do this for each device you want to detach.", "Detach devices manually", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
    }
  }
})

$form.ShowDialog() | Out-Null
$form.Dispose()