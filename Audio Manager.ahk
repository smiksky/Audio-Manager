/*
Audio Manager by Scott Mikutsky
Copyright © 2020


This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.


Version History:

1.0 - 10/25/2020 - Initial release
1.0.1 - 10/26/2020 - Updated about page
1.0.2 - 10/26/2020 - Initial Github release, updated included license and about
*/

#NoEnv
#SingleInstance force
#Persistent
SendMode Input
SetWorkingDir, %A_ScriptDir%

#Include <VA>

Menu, Tray, NoStandard
Menu, Tray, NoMainWindow
Menu, Tray, Click, 1

;Load resources

FileInstall, AudioManager.ico, AudioManager.ico
FileInstall, Default.ico, Default.ico
FileInstall, DefaultCom.ico, DefaultCom.ico
FileInstall, LICENSE.txt, LICENSE.txt

Gosub Initialize

;SetTimer, Initialize, 1000

return

Initialize:
	Try Menu, Tray, DeleteAll
	Try Menu, MainMenu, DeleteAll
	Try Menu, DevMenu, DeleteAll
	Try Menu, DevComMenu, DeleteAll
	Try Menu, OptionsMenu, DeleteAll
	Try Menu, HideShowMenu, DeleteAll


	;Create lists of devices
	devicesOutEnum := ComObjCreate("{BCDE0395-E52F-467C-8E3D-C4579291692E}", "{A95664D2-9614-4F35-A746-DE8DB63617E6}")
	VA_IMMDeviceEnumerator_EnumAudioEndpoints(devicesOutEnum, 0, 1, devicesOut)	;Gets all output devices that are active
	VA_IMMDeviceCollection_GetCount(devicesOut, countOut)

	devicesInEnum := ComObjCreate("{BCDE0395-E52F-467C-8E3D-C4579291692E}", "{A95664D2-9614-4F35-A746-DE8DB63617E6}")
	VA_IMMDeviceEnumerator_EnumAudioEndpoints(devicesInEnum, 1, 1, devicesIn)	;Gets all input devices that are active
	VA_IMMDeviceCollection_GetCount(devicesIn, countIn)


	;Get default devices
	VA_IMMDeviceEnumerator_GetDefaultAudioEndpoint(devicesInEnum, 0, 0, defaultDevice)
	global defaultOut = new Endpoint(defaultDevice)

	VA_IMMDeviceEnumerator_GetDefaultAudioEndpoint(devicesInEnum, 0, 2, defaultDevice)
	global defaultComOut = new Endpoint(defaultDevice)

	VA_IMMDeviceEnumerator_GetDefaultAudioEndpoint(devicesInEnum, 1, 0, defaultDevice)
	global defaultIn = new Endpoint(defaultDevice)

	VA_IMMDeviceEnumerator_GetDefaultAudioEndpoint(devicesInEnum, 1, 2, defaultDevice)
	global defaultComIn = new Endpoint(defaultDevice)

	ObjRelease(defaultDevice)


	;Create and populate arrays with active devices
	global Outputs := Array()
	Loop %countOut% {
		VA_IMMDeviceCollection_Item(devicesOut, A_Index-1, device)
		thisOut := new Endpoint(device)
		Outputs.push(thisOut)
	}
	global Inputs := Array()
	Loop %countIn% {
		VA_IMMDeviceCollection_Item(devicesIn, A_Index-1, device)
		thisIn := new Endpoint(device)
		Inputs.push(thisIn)
	}

	ObjRelease(devicesInEnum)
	ObjRelease(devicesOutEnum)
	ObjRelease(devicesIn)
	ObjRelease(devicesOut)
	ObjRelease(device)


	;Add default devices to the menu
	Menu, MainMenu, Add, Default Devices, Nothing
	Menu, MainMenu, Icon, Default Devices, Default.ico
	
	_name := defaultOut.GetName()
	Menu, MainMenu, Add, Out: %_name%, Nothing

	_name := defaultIn.GetName()
	Menu, MainMenu, Add, In: %_name%, Nothing

	Menu, MainMenu, Add
	Menu, MainMenu, Add, Default Communication Devices, Nothing
	Menu, MainMenu, Icon, Default Communication Devices, DefaultCom.ico

	if (!defaultOut.isSame(defaultComOut)){
		_name := defaultComOut.GetName()
		Menu, MainMenu, Add, Out: %_name%, Nothing
	}

	if(!defaultIn.isSame(defaultComIn)){
		_name := defaultComIn.GetName()
		Menu, MainMenu, Add, In: %_name%, Nothing
	}	

	;Create and populate the menus and arrays of devices
	
	global VisDev := Array()

	Loop, % countOut
	{
		dev := Outputs[A_INDEX]
		nam := dev.GetName()
		IniRead, hid, config.ini, Hide Devices, Hide Out: %nam%, 0

		Menu, HideShowMenu, Add, Hide Out: %nam%, ToggleHide

		if (hid = 0) {
			VisDev.push(dev)
			Menu, DevMenu, Add, Out: %nam%, SetDefault
			Menu, DevComMenu, Add, Out: %nam%, SetDefaultCom

			if (dev.IsSame(defaultOut)) {
				Menu, DevMenu, Disable, Out: %nam%
				Menu, HideShowMenu, Disable, Hide Out: %nam%
			}
			if (dev.IsSame(defaultComOut)){
				Menu, DevComMenu, Disable, Out: %nam%
				Menu, HideShowMenu, Disable, Hide Out: %nam%
			}
		} else {
			Menu, HideShowMenu, Check, Hide Out: %nam%
		}
	}

	VisDev.push("")
	Menu, DevMenu, Add
	Menu, DevComMenu, Add

	Loop, % countIn
	{
		dev := Inputs[A_INDEX]
		nam := dev.GetName()
		IniRead, hid, config.ini, Hide Devices, Hide In: %nam%, 0

		Menu, HideShowMenu, Add, Hide In: %nam%, ToggleHide

		if (hid = 0) {
			VisDev.push(dev)
			Menu, DevMenu, Add, In: %nam%, SetDefault
			Menu, DevComMenu, Add, In: %nam%, SetDefaultCom

			if (dev.IsSame(defaultIn)) {
				Menu, DevMenu, Disable, In: %nam%
				Menu, HideShowMenu, Disable, Hide In: %nam%
			}
			if (dev.IsSame(defaultComIn)){
				Menu, DevComMenu, Disable, In: %nam%
				Menu, HideShowMenu, Disable, Hide In: %nam%
			}
		} else {
			Menu, HideShowMenu, Check, Hide In: %nam%
		}
	}
	
	;Add the remainder of the menu options
	Menu, MainMenu, Add, Default Devices, :DevMenu
	Menu, MainMenu, Add, Default Communication Devices, :DevComMenu

	Menu, Tray, Icon, AudioManager.ico
	Menu, Tray, Add, Audio Manager, Open
	Menu, Tray, Icon, Audio Manager, AudioManager.ico
	Menu, Tray, Default, Audio Manager
	Menu, Tray, Add
	Menu, Tray, Add, About
	Menu, Tray, Add, Hide/Show Devices, :HideShowMenu
	Menu, Tray, Add, Start With Windows, ToggleWinStartup
	if FileExist(A_Startup "\Audio Manager.lnk")
		Menu, Tray, Check, Start With Windows
	Menu, Tray, Add, Quit, Exit
	Menu, Tray, Click, 1	

	return

Open:
	Gosub Initialize
	Menu, MainMenu, Show
	return

About:
	Gui, New, -MaximizeBox -MinimizeBox
	Gui, Add, Picture, w64 h-1, AudioManager.ico
	Gui, Add, Text, ys, Audio Manager by Scott Mikutsky
	Gui, Add, Text, yp+16, Version 1.0.2
	Gui, Add, Text, yp+16, Copyright © 2020
	Gui, Add, Link, yp+16, <a href="https://github.com/smikutsky/Audio-Manager">https://github.com/smikutsky/Audio-Manager</a>
	Gui, Add, Link, yp+16, <a href="mailto:smikutsky@gmail.com">smikutsky@gmail.com</a>
	Gui, Add, Text, xs W300, This software uses the Vista Audio library by Lexikos 
	Gui, Add, Text, W300, This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
	Gui, Add, Text, W300, This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
	Gui, Add, Link, W300, You should have received a copy of the GNU General Public License along with this program.  If not, see <a href="https://www.gnu.org/licenses/"><https://www.gnu.org/licenses/></a>.
	Gui, Show, , About
	return

Nothing:
	return

Exit:
	ExitApp
	return

SetDefault(name, index, menu){
	VA_SetDefaultEndpoint(VisDev[index].GetId(), 0)
	Gosub Initialize
}

SetDefaultCom(name, index, menu){
	VA_SetDefaultEndpoint(VisDev[index].GetId(), 2)
	Gosub Initialize
}

ToggleHide(name, index, menu){
	IniRead, hide, config.ini, Hide Devices, %name%, 0
	IniWrite, % !hide, config.ini, Hide Devices, %name%
	Menu, % menu, ToggleCheck, %name%
	Gosub Initialize
}

ToggleWinStartup(name, index, menu){
	if (FileExist(A_Startup "\Audio Manager.lnk"))
		FileDelete, %A_Startup%\Audio Manager.lnk
	else
		FileCreateShortcut, %A_ScriptFullPath%, %A_Startup%\Audio Manager.lnk, %A_WorkingDir%,,, %A_ScriptFullPath%
	Menu, % menu, ToggleCheck, % name	
}

;More functions to get information about devices, adapted from Vista Audio

GetDeviceDesc(device)
{
	static PKEY_Device_DeviceDesc
	if !VarSetCapacity(PKEY_Device_DeviceDesc)
		VarSetCapacity(PKEY_Device_DeviceDesc, 20)
		,VA_GUID(PKEY_Device_DeviceDesc :="{A45C254E-DF1C-4EFD-8020-67D146A850E0}")
		,NumPut(2, PKEY_Device_DeviceDesc, 16)
	VarSetCapacity(prop, 16)
	VA_IMMDevice_OpenPropertyStore(device, 0, store)
	; store->GetValue(.., [out] prop)
	DllCall(NumGet(NumGet(store+0)+5*A_PtrSize), "ptr", store, "ptr", &PKEY_Device_DeviceDesc, "ptr", &prop)
	ObjRelease(store)
	VA_WStrOut(deviceDesc := NumGet(prop,8))
	return deviceDesc
}

;Broken
GetDeviceIcon(device)
{
	static PKEY_DrvPkg_Icon
	if !VarSetCapacity(PKEY_DrvPkg_Icon)
		VarSetCapacity(PKEY_DrvPkg_Icon, 20)
		,VA_GUID(PKEY_DrvPkg_Icon :="{CF73BB51-3ABF-44A2-85E0-9A3DC7A12132}")
		,NumPut(4, PKEY_DrvPkg_Icon, 16)
	VarSetCapacity(prop, 16)
	VA_IMMDevice_OpenPropertyStore(device, 0, store)
	; store->GetValue(.., [out] prop)
	DllCall(NumGet(NumGet(store+0)+5*A_PtrSize), "ptr", store, "ptr", &PKEY_DrvPkg_Icon, "ptr", &prop)
	ObjRelease(store)
	VA_WStrOut(deviceIcon := NumGet(prop,8))
	return deviceIcon
}

;PKEY_DrvPkg_Icon: {CF73BB51-3ABF-44A2-85E0-9A3DC7A12132} 4
;PKEY_DeviceClass_Icon: {259ABFFC-50A7-47CE-AF8-68C9A7D73366} 4

;All audio devices will be stored as an Endpoint object
class Endpoint {
	
	__New(_device) {
		this.device := _device

		this.name := GetDeviceDesc(this.device)	

		VA_IMMDevice_GetId(this.device, _id)  ;id will be used as the UID for each object
		this.id := _id	

		;this.iconpath := GetDeviceIcon(this.device)
		;MsgBox, % this.iconpath
	}
	IsSame(ByRef _device) {
		return this.id == _device.GetId()
	}
	GetName() {
		return this.name
	}
	GetId() {
		return this.id
	}
}