bluetoothConnectDisconnect(mode, deviceName) {
	DllCall("LoadLibrary", "str", "Bthprops.cpl", "ptr")
	VarSetCapacity(BLUETOOTH_DEVICE_SEARCH_PARAMS, 24+A_PtrSize*2, 0)
	NumPut(24+A_PtrSize*2, BLUETOOTH_DEVICE_SEARCH_PARAMS, 0, "uint")
	NumPut(1, BLUETOOTH_DEVICE_SEARCH_PARAMS, 4, "uint")   ; fReturnAuthenticated
	VarSetCapacity(BLUETOOTH_DEVICE_INFO, 560, 0)
	NumPut(560, BLUETOOTH_DEVICE_INFO, 0, "uint")
	returnStatus := -1 ; 0 - disconnected, 1 - connected, -1 - error
	
	loop
	{
		If (A_Index = 1)
		{
			foundDevice := DllCall("Bthprops.cpl\BluetoothFindFirstDevice", "ptr", &BLUETOOTH_DEVICE_SEARCH_PARAMS, "ptr", &BLUETOOTH_DEVICE_INFO, "ptr")
			if !foundDevice
			{
				return "no bluetooth devices found"
			}
		}
		else
		{
			if !DllCall("Bthprops.cpl\BluetoothFindNextDevice", "ptr", foundDevice, "ptr", &BLUETOOTH_DEVICE_INFO)
			{
				;msgbox "no found maybe"
				break
			}
		}

      ; BLUETOOTH_DEVICE_INFO struct field sizes:
		; DWORD             dwSize = 4
		; BLUETOOTH_ADDRESS Address = 8
		; ULONG             ulClassofDevice = 4
		; BOOL              fConnected = 4
		; BOOL              fRemembered = 4
		; BOOL              fAuthenticated = 4
		; SYSTEMTIME        stLastSeen = 16
		; SYSTEMTIME        stLastUsed = 16
		; WCHAR             szName = 496
		
		
		if (StrGet(&BLUETOOTH_DEVICE_INFO+64) = deviceName) { ; we have the right device
			if (mode = "read") {
				return (NumGet(&BLUETOOTH_DEVICE_INFO + 20, "Int") = 0) ? 0 : 1 ; read fConnected; if it is connected, then the value will be 32, if not, then 0
			}
			else if (mode = "set") {
				VarSetCapacity(Handsfree, 16)
				DllCall("ole32\CLSIDFromString", "wstr", "{0000111e-0000-1000-8000-00805f9b34fb}", "ptr", &Handsfree)   ; https://www.bluetooth.com/specifications/assigned-numbers/service-discovery/
				VarSetCapacity(AudioSink, 16)
				DllCall("ole32\CLSIDFromString", "wstr", "{0000110b-0000-1000-8000-00805f9b34fb}", "ptr", &AudioSink)
				
				; try to disconnect the device (look at last argument: 0)
				hr1 := DllCall("Bthprops.cpl\BluetoothSetServiceState", "ptr", 0, "ptr", &BLUETOOTH_DEVICE_INFO, "ptr", &Handsfree, "int", 0)   ; voice
				hr2 := DllCall("Bthprops.cpl\BluetoothSetServiceState", "ptr", 0, "ptr", &BLUETOOTH_DEVICE_INFO, "ptr", &AudioSink, "int", 0)   ; music
				
				if (hr1 = 0) and (hr2 = 0) {
					; disconnecting worked
					returnStatus = 0
					break
				}
				else ; device was already disconnected
				{
					; try to connect to the device
					hr1 := DllCall("Bthprops.cpl\BluetoothSetServiceState", "ptr", 0, "ptr", &BLUETOOTH_DEVICE_INFO, "ptr", &Handsfree, "int", 1) ; voice
					hr2 := DllCall("Bthprops.cpl\BluetoothSetServiceState", "ptr", 0, "ptr", &BLUETOOTH_DEVICE_INFO, "ptr", &AudioSink, "int", 1) ; music
					;hr3 := DllCall("Bthprops.cpl\BluetoothSetServiceState", "ptr", 0, "ptr", &BLUETOOTH_DEVICE_INFO, "ptr", &GenAudServ, "int", 0) ; music
					;hr4 := DllCall("Bthprops.cpl\BluetoothSetServiceState", "ptr", 0, "ptr", &BLUETOOTH_DEVICE_INFO, "ptr", &HdstServ, "int", 1) ; music
					;hr5 := DllCall("Bthprops.cpl\BluetoothSetServiceState", "ptr", 0, "ptr", &BLUETOOTH_DEVICE_INFO, "ptr", &AVRCTarget, "int", 1) ; music
					;hr6 := DllCall("Bthprops.cpl\BluetoothSetServiceState", "ptr", 0, "ptr", &BLUETOOTH_DEVICE_INFO, "ptr", &AVRC, "int", 1) ; music
					;hr7 := DllCall("Bthprops.cpl\BluetoothSetServiceState", "ptr", 0, "ptr", &BLUETOOTH_DEVICE_INFO, "ptr", &AVRCController, "int", 0) ; music
					;hr8 := DllCall("Bthprops.cpl\BluetoothSetServiceState", "ptr", 0, "ptr", &BLUETOOTH_DEVICE_INFO, "ptr", &PnP, "int", 0) ; music
					
					returnStatus = 1
					break
				}
			}
		}
	}
	
	DllCall("Bthprops.cpl\BluetoothFindDeviceClose", "ptr", foundDevice)
	;msgbox done
	return returnStatus
}
