#WinActivateForce
#Include Memory.ahk

; Global Constaints
global FishAddressBase := "0x00F02BD4"
global HK_SwitchFisher := "F11"
global HK_SwitchTooltip := "F8"
global HK_Exit := "F6"
global HK_RecordLocation := "F3"

global TooltipX := 100
global TooltipY := 100

global World_Moment := 500

; Global Variables
global Flag_Fishing := false
global Flag_Tooltip := true
global LureCount := 0
global TotalWaiting := 0

; Show Tooltip
CoordMode, ToolTip, Screen
CoordMode, Mouse, Client
CoordMode, Window, Client
UpdateTooltip()

; Bind Hotkeys
HotKey, %HK_SwitchFisher%, L_SwitchFisher
Hotkey, %HK_SwitchTooltip%, L_SwitchTooltip
Hotkey, %HK_Exit%, L_Exit
HotKey, %HK_RecordLocation%, L_RecordLocation

; World
global ErrorWaiting := 1000
while (True) {
    GetProcessInfo()

    ; Auto Fishing
    just_throw := false
    if (Flag_Fishing) {
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
            just_throw := true
        }
    }

    UpdateTooltip()
    Sleep, World_Moment
    if (Flag_Fishing) {
        TotalWaiting += World_Moment   
    }

    ; Detect Error
    if (Flag_Fishing and just_throw and !isFishing()) {
        ; Try Destroy
        if (SomeWindowIsShown()) {
            ControlSend, , {ESC}, ahk_pid %pid%
            NatualSleep()
        }
        Press("b", pid)
        NatualSleep()
        ; Drop Last Item

        GetClientSize(Width, Height)
        ; WinGetPos, X_, Y_, Width_, Height_, ahk_exe trove.exe
        X0 := max(Width / 1.4, Width - Height / 2, Width - 384)
        W0 := Width - X0
        Y0 := Height / 2 - W0
        H0 := Height - Y0 * 2
        X1 := X0 + 0.8 * W0
        Y1 := Y0 + 0.81  * H0
        X2 := X0 + 0.78 * W0
        Y2 := Y0 + 0.91 * H0
        ; MsgBox, %X0% . "," . %Y0%


        Random, MouseSpeed, 4, 10
        MouseClickDrag, Left, %X1%, %Y1%, %X2%, %Y2%, MouseSpeed
        ; MouseMove %X1%, %Y1%, MouseSpeed
        ; MouseClick, Left, %RX3%, %RY3%
        ; Dynamic Delay
        ErrorWaitingRest := ErrorWaiting
        while (Flag_Fishing and ErrorWaitingRest > 0) {
            Sleep, World_Moment
            TotalWaiting += World_Moment
            UpdateTooltip()
            ErrorWaitingRest -= World_Moment
        }
        ErrorWaiting *= 2
    }
    else {
        ErrorWaiting := 1000
    }
}
Return

L_Exit:
ExitApp

L_SwitchFisher: ; Switch Autofisher Status
    Flag_Fishing ^= 1
    ErrorWaiting := 1000
    UpdateTooltip()
Return

L_SwitchTooltip: ; Switch Tooltip status
    Flag_Tooltip ^= 1
    UpdateTooltip()
Return

L_RecordLocation: ; Record Mouse Location
    RX1 := RX2
    RY1 := RY2
    RX2 := RX3
    RY2 := RY3
    MouseGetPos, RX3, RY3
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

; ToolTip Generation

AutoFisherStatus() {
    autoFisherStatus := "Game : " . (GameIsRunning() ? "Running" : "Not Running")
    ; AutoFisher Status
    autoFisherStatus .= "`n`n[AutoFisher : " . (Flag_Fishing ? "ON" : "OFF") . "]"
    if (Flag_Fishing) {
        ; Fishing Status
        autoFisherStatus .= "`nFishing Status : " . (IsHooked() ? "Hooked" : (isFishing() ? "Waiting" : "zzZ"))
        ; Fishing Area
        if (GetFishingArea() <> "Unknown") {
            autoFisherStatus .= " in " . GetFishingArea()        
        }
    }
    ; Other Statistics
    autoFisherStatus .= "`n" . "Lure Used : " . LureCount
    hh := Floor(TotalWaiting / 1000 / 3600)
    mm := Floor(Mod(TotalWaiting / 1000, 3600) / 60)
    ss := Floor(Mod(TotalWaiting / 1000, 60))
    autoFisherStatus .= "`n" . "Total Wait : " . (StrLen(hh) = 1 ? "0" : "") . hh 
    autoFisherStatus .= ":" . (StrLen(mm) = 1 ? "0" : "") . mm
    autoFisherStatus .= ":" . (StrLen(ss) = 1 ? "0" : "") . ss
    return autoFisherStatus
}

DebugInfo() {
    debugInfo := "[DEBUF INFO]"
    debugInfo .= "`nSomeWindowIsShown : " . (SomeWindowIsShown() ? "YES" : "NO")
    global Width
    global Height
    w := Width
    debugInfo .= "`nWidth : " . %w%
    debugInfo .= "`nHeight : " . %Height%
    return debugInfo
}

UpdateTooltip() {
    if (Flag_Tooltip) {
        TooltipText := "[YoRHa No.2 Type F]"

        TooltipText .= "`n" . AutoFisherStatus()

        ; Deletion Positions
        ; TooltipText .= "`n`n[Mouse Position Stack]"
        ; TooltipText .= "`n(" . RX1 . ", " . RY1 . ")"
        ; TooltipText .= "`n(" . RX2 . ", " . RY2 . ")"
        ; TooltipText .= "`n(" . RX3 . ", " . RY3 . ")"

        ; DEBUG INFO

        ; TooltipText .= "`n`n" . DebugInfo() 

        ; Operation
        TooltipText .= "`n"
        TooltipText .= "`n[F11] : Trun On/Off AutoFisher"
        TooltipText .= "`n[F8] : Trun On/Off Tooltip"
        ; TooltipText .= "`n[" . HK_RecordLocation . "] : Push Current Mouse Position into Stack"
        TooltipText .= "`n[F6] : Close Program"

        Tooltip, %TooltipText%, TooltipX, TooltipY
    }
    else {
        ToolTip
    }
}