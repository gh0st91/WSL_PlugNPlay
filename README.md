# WSL PlugNPlay

I am extremely lazy, so instead of having to run the commands to attach and detach devices from my Kali WSL install, I built this script. Hope it's helpful to someone. Effectively, the script allows you to easily manage USB devices for WSL in a simple and intuitive graphical interface. All of this is done in real time!

I have used ps2exe to produce an executable file, which can be found under [Releases](https://github.com/gh0st91/WSL_PlugNPlay/releases).

NOTE: READ THE USAGE AND REQUIREMENTS

## Requirements

- Windows 10 or later running WSL2 and a distro (Kali, Debian, Ubuntu, etc.)
- `usbipd.exe` from [usbipd-win](https://github.com/dorssel/usbipd-win/releases)
- PowerShell v5.1 or later (comes pre-installed on Windows 10+ systems)
- Administrator Privileges. (required for accessing USB devices)

## Usage

1. Download the latest WSL_PlugNPlay.exe or .ps1 from the [Releases](https://github.com/gh0st91/WSL_PlugNPlay/releases) page.
2. Have USB devices connected and your WSL distro up and running before opening either the .exe or .ps1
	- If you chose the powershell script, run it from an admin powershell prompt.
	- If you chose the exe, congratulations! Everything is taken care of. Just click 'Yes' on the UAC prompt.
	- NOTE: IF YOU CONNECT USB DEVICE(S) AFTER THE WINDOW IS OPEN, RESTART THE PROGRAM TO HAVE THOSE DEVICES APPEAR IN THE LIST.
4. A GUI window will appear, displaying a list of all attached USB devices.
5. Check the box next to the devices you want to attach or detach.
7. The selected USB devices will be instantly attached or detached, depending on what was selected.
8. On closing, the program will ask you if you want to detach all devices. If you pick 'No' a window will appear explaining how to detach them manually.

## Important Notice

Please be aware that attaching a USB device to a WSL instance requires the device to be detached from the host system first. This means that the device can no longer be used on the host system until it is detached from said instance.

## Disclaimer

This script is provided as-is, without any warranty, and the author is not responsible for any damages or loss of data caused by the usage of this script. Use at your own risk.

## Contributing

This is my final solution, and there likely will not be any significant changes. Still, feel free to submit a pull request if you see something that can be improved. Note: there is one TODO. If anyone can figure it out, major brownie points!

`Would you fork me? 
I'd fork me. I'd fork me so hard...`
