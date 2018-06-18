#WinActivateForce

; Global Constaints
global FishAddressBase := "0x00F02BD4"
global HK_SwitchFisher := "F11"
global HK_Info := "F8"
global HK_Exit := "F6"
global HK_RecordLocation := "F2"

global FH_MinWaitTime := 10000
global FH_CheckInterval := 500

global TooltipX := 100
global TooltipY := 100

; Global Variables
global Flag_Fishing := false
global Flag_Tooltip := true
global LureCount := 0
global TotalWaiting := 0

global Base := 0
global WaterAddr := 0
global ChocoAddr := 0
global LavaAddr := 0
global PlasmaAddr := 0
global WaterFishingAddr := 0
global ChocoFishingAddr := 0
global LavaFishingAddr := 0
global PlasmaFishingAddr := 0

global RX1 := 0
global RY1 := 0
global RX2 := 0
global RY2 := 0
global RX3 := 0
global RY3 := 0

; Show Tooltip
CoordMode, ToolTip, Screen
CoordMode, Mouse, Relative
UpdateTooltip()

; Bind Hotkeys
HotKey, %HK_SwitchFisher%, L_SwitchFisher
Hotkey, %HK_Info%, L_Info
Hotkey, %HK_Exit%, L_Exit
HotKey, %HK_RecordLocation%, L_RecordLocation
Return

L_SwitchFisher: ; Switch autofisher status
    if (Flag_Fishing) {
        Flag_Fishing := false
        UpdateTooltip()
    } else {
        Flag_Fishing := true
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

L_RecordLocation: ; Record Mouse Location
    RX1 := RX2
    RY1 := RY2
    RX2 := RX3
    RY2 := RY3
    MouseGetPos, RX3, RY3
    UpdateTooltip()
Return

AutoFish:
    ; Get Process Info
    WinGet, pidn, PID, A
    pid := pidn
    WinGet, hwnds, ID, A
    Handle := hwnds

    ; Get Memory Address Info
    Base := getProcessBaseAddress()
    WaterAddr := AddrW()
    WaterFishingAddr := WaterAddr - 0xAA0
    ChocoAddr := AddrC()
    ChocoFishingAddr := ChocoAddr - 0xAA0
    LavaAddr := AddrL()
    LavaFishingAddr := LavaAddr - 0x11B8
    PlasmaAddr := AddrP()
    PlasmaFishingAddr := PlasmaAddr - 0x1674

    ; Fishing
    ErrorWaiting := 1000
    while (Flag_Fishing) {
        ; Check
        if (isHooked()) {
            ; Wait before pull
            UpdateTooltip()
            Random, Wait, 1000, 2000
            Sleep, Wait
            TotalWaiting += Wait
            ; Pull
            Press("f", pid)
            ; Wait before throw
            UpdateTooltip()
            Random, Wait, 2000, 3000
            Sleep, Wait
            TotalWaiting += Wait
        }
        ; Throw
        if (Flag_Fishing and !isFishing()) {
            Press("f", pid)
            LureCount += 1
        }
        UpdateTooltip()
        Sleep, FH_CheckInterval
        TotalWaiting += FH_CheckInterval

        ; Detect Error
        if (Flag_Fishing and !isFishing()) {
            ; Try Destroy
            WinGet, pidn, PID, A
            if (pid = pidn) {
                Random, MouseSpeed, 4, 10
                MouseClickDrag, Left, %RX1%, %RY1%, %RX2%, %RY2%, MouseSpeed
                MouseMove %RX3%, %RY3%, MouseSpeed
                MouseClick, Left, %RX3%, %RY3%    
            }
            ; Dynamic Delay
            ErrorWaitingRest := ErrorWaiting
            while (Flag_Fishing and ErrorWaitingRest > 0) {
                Sleep, FH_CheckInterval
                TotalWaiting += FH_CheckInterval
                UpdateTooltip()
                ErrorWaitingRest -= FH_CheckInterval
            }
            ErrorWaiting *= 2
        }
        else {
            ErrorWaiting = 1000
        }
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

isFishing() {
    SignW := ReadMemory(WaterFishingAddr)
    SignC := ReadMemory(ChocoFishingAddr)
    SignL := ReadMemory(LavaFishingAddr)
    SignP := ReadMemory(PlasmaFishingAddr)
    return SignW or SignC or SignL or SignP
}

isHooked() {
    SignW := ReadMemory(WaterAddr)
    SignC := ReadMemory(ChocoAddr)
    SignL := ReadMemory(LavaAddr)
    SignP := ReadMemory(PlasmaAddr)
    return SignW or SignC or SignL or SignP
}

UpdateTooltip() {
    if (Flag_Tooltip) {

        TooltipText := "[YoRHa No.2 Type F]"

        autoFisherStatus := ""
        ; Status
        if (Flag_Fishing) {
            autoFisherStatus .= "`nAutoFisher : ON"
            ; Fishing Area
            if (ReadMemory(WaterFishingAddr)) {
                autoFisherStatus .= "`nFishing Area : Water"
            }
            else if (ReadMemory(ChocoFishingAddr)) {
                autoFisherStatus .= "`nFishing Area : Chocolate"
            }
            else if (ReadMemory(LavaFishingAddr)) {
                autoFisherStatus .= "`nFishing Area : Lava"
            }
            else if (ReadMemory(PlasmaFishingAddr)) {
                autoFisherStatus .= "`nFishing Area : Plasma"
            }
            else {
                autoFisherStatus .= "`nFishing Area : Unknown"   
            }
            ; Fishing Status
            if (isHooked()) {
                autoFisherStatus .= "`nFishing Status : Pulling"
            }
            else if (isFishing()) {
                autoFisherStatus .= "`nFishing Status : Waiting"
            }
            else {
                autoFisherStatus .= "`nFishing Status : zzZ"
            }
        }
        else {
            autoFisherStatus .= "`nAutoFisher : OFF"
        }
        ; Statistics
        autoFisherStatus .= "`n" . "Lure Used : " . LureCount
        hh := Floor(TotalWaiting / 1000 / 3600)
        mm := Floor(Mod(TotalWaiting / 1000, 3600) / 60)
        ss := Floor(Mod(TotalWaiting / 1000, 60))
        autoFisherStatus .= "`n" . "Total Wait : " . (StrLen(hh) = 1 ? "0" : "") . hh 
        autoFisherStatus .= ":" . (StrLen(mm) = 1 ? "0" : "") . mm
        autoFisherStatus .= ":" . (StrLen(ss) = 1 ? "0" : "") . ss
        TooltipText .= autoFisherStatus

        ; Deletion Positions
        TooltipText .= "`n`n[Mouse Position Stack]"
        TooltipText .= "`n(" . RX1 . ", " . RY1 . ")"
        TooltipText .= "`n(" . RX2 . ", " . RY2 . ")"
        TooltipText .= "`n(" . RX3 . ", " . RY3 . ")"

        ; DEBUG INFO

        ; TooltipText .= "`n`n`n[DEBUF INFO]"
        ; TooltipText .= "`nBaseAddr : " . Base
        ; SetFormat, Integer, H
        ; TooltipText .= "`nWaterAddr : " . WaterAddr
        ; SetFormat, Integer, H
        ; TooltipText .= "`nChocoAddr : " . ChocoAddr
        ; TooltipText .= "`nPlasmaAddr : " . PlasmaAddr
        ; TooltipText .= "`nChocoFishing : " . ChocoFishingAddr . " " . ReadMemory(ChocoFishingAddr)
        ; SetFormat, Integer, D

        ; Operation
        TooltipText .= "`n"
        TooltipText .= "`n[F11] : Trun On/Off AutoFisher"
        TooltipText .= "`n[F8] : Trun On/Off Tooltip"
        TooltipText .= "`n[F2] : Push Current Mouse Position into Stack"
        TooltipText .= "`n[F6] : Close Program"

        Tooltip, %TooltipText%, TooltipX, TooltipY
    }
}