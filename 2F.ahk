#WinActivateForce

; Global Constaints
global FishAddress := "0x00F02AD4"
global FishAddressBase := "0x00F02BD4"
global HK_SwitchFisher := "F11"
global HK_Info := "F8"
global HK_Exit := "F6"

global FH_MinWaitTime := 10000
global FH_MaxWaitTime := 35000
global FH_CheckInterval := 1000
global FH_MaxLureAmount := 9999

global TooltipX := 200
global TooltipY := 200
global Tooltip_Refresh := 1000

; Global Variables
global isFishing := false
global Flag_Tooltip := true
global LureCount := 0
global Waiting := 0
global TotalWaiting := 0

global Base := 0
global WaterAddr := 0
global ChocoAddr := 0
global ChocoFishingAddr := 0

; Show Tooltip
CoordMode, ToolTip, Screen
UpdateTooltip()

; Bind Hotkeys
HotKey, %HK_SwitchFisher%, L_SwitchFisher
Hotkey, %HK_Info%, L_Info
Hotkey, %HK_Exit%, L_Exit
Return

L_SwitchFisher: ; Switch autofisher status
    if (isFishing) {
        isFishing := false
        UpdateTooltip()
    } else {
        isFishing := true
        UpdateTooltip()
        SetTimer, AutoFish, -1
    }
Return

L_Info: ; Toggle tooltip
    if (Flag_Tooltip) {
        Flag_Tooltip := false
        ToolTip
    } else {
        Flag_Tooltip := true
        UpdateTooltip()
    }
Return

L_Exit: ; Stop the script
ExitApp

AutoFish:
    WinGet, pidn, PID, A
    pid := pidn
    WinGet, hwnds, ID, A
    Handle := hwnds

    Base := getProcessBaseAddress()
    WaterAddr := AddrW()
    ChocoAddr := AddrC()
    ChocoFishingAddr := AddrCF()

    Press("f", pid)
    LureCount += 1
    Waiting := 0
    while (isFishing and LureCount < FH_MaxLureAmount) {
        ; Check
        if (Waiting >= FH_MinWaitTime and isHooked(Base)) {
            ; Wait before pull
            Random, Wait, 1000, 2000
            Sleep, Wait
            ; Pull
            Press("f", pid)
            ; Wait before throw
            Random, Wait, 2000, 3000
            Sleep, Wait
            ; Throw
            Waiting := FH_MaxWaitTime + 1
        }
        ; Throw | Fix error
        if (Waiting > FH_MaxWaitTime) {
            Press("f", pid)
            LureCount += 1
            Waiting := 0
        }
        UpdateTooltip()
        Sleep, FH_CheckInterval
        Waiting += FH_CheckInterval
        TotalWaiting += FH_CheckInterval
    }
Return


UpdateTimer:
    UpdateTooltip()
Return

NatualSleep() {
    Random, SleepTime, 66, 122
    Sleep, %SleepTime%
}

Press(npbtn, nppid) {
    ControlSend, , {Blind}{%npbtn% down}, ahk_pid %nppid%
    NatualSleep()
    ControlSend, , {Blind}{%npbtn% up}, ahk_pid %nppid%
    NatualSleep()
}

getProcessBaseAddress() {
    global Handle
    return DllCall( A_PtrSize = 4
        ? "GetWindowLong"
        : "GetWindowLongPtr"
        , "Ptr", Handle
        , "Int", -6
        , "Int64") ; Use Int64 to prevent negative overflow when AHK is 32 bit and target process is 64bit
    ; if DLL call fails, returned value will = 0
}

AddrW() {
    pointerBase := Base + FishAddress
    y1 := ReadMemory(pointerBase)
    y2 := ReadMemory(y1 + 0x8)
    y3 := ReadMemory(y2 + 0x1B4)
    Return y3 + 0x22C
}

AddrC() {
    pointerBase := Base + FishAddressBase
    y1 := ReadMemory(pointerBase)
    y2 := ReadMemory(y1 + 0xE0)
    y3 := ReadMemory(y2 + 0x324)
    Return y3 + 0x78
}

AddrCF() {
    Return AddrC() - 0xAA0
}

ReadMemory(MADDRESS) {
    global pid
    VarSetCapacity(MVALUE,4,0)
    ProcessHandle := DllCall("OpenProcess", "Int", 24, "Char", 0, "UInt", pid, "UInt")
    ;DllCall("ReadProcessMemory", "UInt", ProcessHandle, "UInt", MADDRESS, "Str", MVALUE, "UInt", 4, "UInt *", 0)
    DllCall("ReadProcessMemory", "UInt", ProcessHandle, "Ptr", MADDRESS, "Ptr", &MVALUE, "Uint", 4)
    Loop 4
    result += *(&MVALUE + A_Index-1) << 8*(A_Index-1)
    return, result
}

isHooked(Base) {
    SignW := ReadMemory(WaterAddr)
    SignC := ReadMemory(ChocoAddr)
    return SignW or SignC
}

UpdateTooltip() {
    if (Flag_Tooltip) {

        TooltipText := "[YoRHa No.2 Type F]"

        autoFisherStatus := "`n"
        if (isFishing) {
            autoFisherStatus .= "AutoFisher : ON"
        }
        else {
            autoFisherStatus .= "AutoFisher : OFF"
        }
        autoFisherStatus .= "`n" . "Lure Used : " . LureCount
        autoFisherStatus .= "`n" . "Current Wait : " . Floor(Waiting / 1000)
        autoFisherStatus .= "`n" . "Total Wait : " . Floor(TotalWaiting / 1000)
        TooltipText .= autoFisherStatus

        ; DEBUG INFO

        TooltipText .= "`n[DEBUF INFO]"
        TooltipText .= "`nBaseAddr : " . Base
        SetFormat, Integer, H
        TooltipText .= "`nWaterAddr : " . WaterAddr
        SetFormat, Integer, H
        TooltipText .= "`nChocoAddr : " . ChocoAddr
        TooltipText .= "`nChocoFishing : " . ChocoFishingAddr . " " . ReadMemory(ChocoFishingAddr)
        SetFormat, Integer, D

        Tooltip, %TooltipText%, TooltipX, TooltipY
    }
}