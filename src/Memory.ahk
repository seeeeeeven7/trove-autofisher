SetMemoryDefaults()

; set global variables / constaints
SetMemoryDefaults() {
    global
    processBaseAddress := 0
    fishingBiasAddress := "0x00F02BD4"
}

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
    global processBaseAddress := GetProcessBaseAddress()
}

; game status check

GameIsRunning() {
    global pid
    return !(pid = "")
}

SomeWindowIsShown() {
    global processBaseAddress
    if (GameIsRunning()) {
        pointerBase := processBaseAddress + 0x00F27C3C
        y1 := ReadMemory(pointerBase)
        y2 := ReadMemory(y1 + 0x28)
        return y2 > 0 
    }
    return false
}

; avatar status

BiasAddressOfAvatarHP() {
    global processBaseAddress
    pointerBase := processBaseAddress + 0x00F2A470
    y1 := ReadMemory(pointerBase)
    y2 := ReadMemory(y1 + 0x78)
    y3 := ReadMemory(y2 + 0x20C)
    y4 := ReadMemory(y3 + 0x8)
    return y4 + 0x10C
}

GetAvatarHP() {
    return ReadMemory(BiasAddressOfAvatarHP())
}

GetAvatarHPMAX() {
    return ReadMemory(BiasAddressOfAvatarHP() + 0x4)
}

; fishing status

IsFishing() {
    return IsFishingInWater() or IsFishingInChocolate() or IsFishingInLava() or IsFishingInPlasma()
}

IsHooked() {
    return IsHookedInWater() or IsHookedInChocolate() or IsHookedInLava() or IsHookedInPlasma()
}

GetFishingArea() {
    if IsFishingInWater()
        return "Water"
    if IsFishingInChocolate()
        return "Chocolate"
    if IsFishingInLava()
        return "Lava"
    if IsFishingInPlasma()
        return "Plasma"
    return "Unknown"
}

; fishing status check / water

BiasAddressOfHookedInWater() {
    global processBaseAddress, fishingBiasAddress
    pointerBase := processBaseAddress + fishingBiasAddress
    y1 := ReadMemory(pointerBase)
    y2 := ReadMemory(y1 + 0xE0)
    y3 := ReadMemory(y2 + 0xC8)
    Return y3 + 0x78
}

IsHookedInWater() {
    Return ReadMemory(BiasAddressOfHookedInWater())
}

IsFishingInWater() {
    Return ReadMemory(BiasAddressOfHookedInWater() - 0xAA0)
}

; fishing status check / chocolate

BiasAddressOfHookedInChocolate() {
    global processBaseAddress, fishingBiasAddress
    pointerBase := processBaseAddress + fishingBiasAddress
    y1 := ReadMemory(pointerBase)
    y2 := ReadMemory(y1 + 0xE0)
    y3 := ReadMemory(y2 + 0x324)
    Return y3 + 0x78
}

IsHookedInChocolate() {
    Return ReadMemory(BiasAddressOfHookedInChocolate())
}

IsFishingInChocolate() {
    Return ReadMemory(BiasAddressOfHookedInChocolate() - 0xAA0)
}

; fishing status check / lava

BiasAddressOfHookedInLava() {
    global processBaseAddress, fishingBiasAddress
    pointerBase := processBaseAddress + fishingBiasAddress
    y1 := ReadMemory(pointerBase)
    y2 := ReadMemory(y1 + 0xE0)
    y3 := ReadMemory(y2 + 0x324)
    Return y3 + 0x2D8
}

IsHookedInLava() {
    Return ReadMemory(BiasAddressOfHookedInLava())
}

IsFishingInLava() {
    Return ReadMemory(BiasAddressOfHookedInLava() - 0x11B8)
}

; fishing status check / plasma

BiasAddressOfHookedInPlasma() {
    global processBaseAddress, fishingBiasAddress
    pointerBase := processBaseAddress + fishingBiasAddress
    y1 := ReadMemory(pointerBase)
    y2 := ReadMemory(y1 + 0xE0)
    y3 := ReadMemory(y2 + 0x7E0)
    Return y3 + 0x78
}

IsHookedInPlasma() {
    Return ReadMemory(BiasAddressOfHookedInPlasma())
}

IsFishingInPlasma() {
    Return ReadMemory(BiasAddressOfHookedInPlasma() - 0x1674)
}