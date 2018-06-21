global FishAddressBase := "0x00F02BD4"
global Base := 0
global WaterAddr := 0
global ChocoAddr := 0
global LavaAddr := 0
global PlasmaAddr := 0
global WaterFishingAddr := 0
global ChocoFishingAddr := 0
global LavaFishingAddr := 0
global PlasmaFishingAddr := 0

ReadMemory(MADDRESS) {
    global pid
    VarSetCapacity(MVALUE,4,0)
    ProcessHandle := DllCall("OpenProcess", "Int", 24, "Char", 0, "UInt", pid, "UInt")
    DllCall("ReadProcessMemory", "UInt", ProcessHandle, "Ptr", MADDRESS, "Ptr", &MVALUE, "Uint", 4)
    Loop 4
    result += *(&MVALUE + A_Index-1) << 8*(A_Index-1)
    return, result
}

GetProcessBaseAddress() {
    global handle
    return DllCall(A_PtrSize = 4 ? "GetWindowLong" : "GetWindowLongPtr", "Ptr", handle, "Int", -6, "Int64") 
}

GetClientSize(ByRef w, ByRef h) {
    global handle
    VarSetCapacity(rc, 16)
    DllCall("GetClientRect", "uint", handle, "uint", &rc)
    w := NumGet(rc, 8, "int")
    h := NumGet(rc, 12, "int")
}

GetProcessInfo() {
    ; Get Process Info
    WinGet, pidn, PID, ahk_exe trove.exe
    global pid := pidn
    WinGet, hwnds, ID, ahk_exe trove.exe
    global handle := hwnds

    ; Get Memory Address Info
    global Base := GetProcessBaseAddress()
    global WaterAddr := AddrW()
    global WaterFishingAddr := WaterAddr - 0xAA0
    global ChocoAddr := AddrC()
    global ChocoFishingAddr := ChocoAddr - 0xAA0
    global LavaAddr := AddrL()
    global LavaFishingAddr := LavaAddr - 0x11B8
    global PlasmaAddr := AddrP()
    global PlasmaFishingAddr := PlasmaAddr - 0x1674
}

GameIsRunning() {
    global pid
    return !(pid = "")
}

SomeWindowIsShown() {
    global Base
    if (GameIsRunning()) {
        pointerBase := Base + 0x00F27C3C
        y1 := ReadMemory(pointerBase)
        y2 := ReadMemory(y1 + 0x28)
        return y2 > 0 
    }
    return false
}

AddrW() {
    pointerBase := Base + FishAddressBase
    y1 := ReadMemory(pointerBase)
    y2 := ReadMemory(y1 + 0xE0)
    y3 := ReadMemory(y2 + 0xC8)
    Return y3 + 0x78
}

AddrC() {
    pointerBase := Base + FishAddressBase
    y1 := ReadMemory(pointerBase)
    y2 := ReadMemory(y1 + 0xE0)
    y3 := ReadMemory(y2 + 0x324)
    Return y3 + 0x78
}

AddrL() {
    pointerBase := Base + FishAddressBase
    y1 := ReadMemory(pointerBase)
    y2 := ReadMemory(y1 + 0xE0)
    y3 := ReadMemory(y2 + 0x324)
    Return y3 + 0x2D8
}

AddrP() {
    pointerBase := Base + FishAddressBase
    y1 := ReadMemory(pointerBase)
    y2 := ReadMemory(y1 + 0xE0)
    y3 := ReadMemory(y2 + 0x7E0)
    Return y3 + 0x78
}

IsFishing() {
    SignW := ReadMemory(WaterFishingAddr)
    SignC := ReadMemory(ChocoFishingAddr)
    SignL := ReadMemory(LavaFishingAddr)
    SignP := ReadMemory(PlasmaFishingAddr)
    return SignW or SignC or SignL or SignP
}

IsHooked() {
    SignW := ReadMemory(WaterAddr)
    SignC := ReadMemory(ChocoAddr)
    SignL := ReadMemory(LavaAddr)
    SignP := ReadMemory(PlasmaAddr)
    return SignW or SignC or SignL or SignP
}

GetFishingArea() {
    if (ReadMemory(WaterFishingAddr)) {
        return "Water"
    }
    if (ReadMemory(ChocoFishingAddr)) {
        return "Chocolate"
    }
    if (ReadMemory(LavaFishingAddr)) {
        return "Lava"
    }
    if (ReadMemory(PlasmaFishingAddr)) {
        return "Plasma"
    }
    return "Unknown"
}