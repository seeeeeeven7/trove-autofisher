#Include Memory.ahk
; For ToolTip to display onTop
#WinActivateForce
; You can only create single instance
#SingleInstance force
; Require running as administrator
IF NOT A_IsAdmin
{
   Run *RunAs "%A_ScriptFullPath%"
   ExitApp
}
; Global Constaints
global HK_SwitchFisher := "F11"
global HK_SwitchDestroyer := "F10"
global HK_SwitchTooltip := "F8"
global HK_Exit := "F6"
global HK_RecordLocation := "F3"
global HK_Bosskey := "!Q"
global TooltipX := 100
global TooltipY := 100
global World_Moment := 100
; Global Variables
global Flag_Fishing := false
global Flag_Tooltip := true
global Flag_Destroyer := false
global Flag_Shown := true
global LureCount := 0
global TotalWaiting := 0
global RX1 := 0
global RY1 := 0
global RX2 := 0
global RY2 := 0
global RX3 := 0
global RY3 := 0

; Settings
CoordMode, ToolTip, Screen
CoordMode, Mouse, Client
CoordMode, Window, Client
DetectHiddenWindows, On
UpdateTooltip()

; Bind Hotkeys
HotKey, %HK_SwitchFisher%, L_SwitchFisher
HotKey, %HK_SwitchDestroyer%, L_SwitchDestroyer
Hotkey, %HK_SwitchTooltip%, L_SwitchTooltip
Hotkey, %HK_Exit%, L_Exit
HotKey, %HK_RecordLocation%, L_RecordLocation
HotKey, %HK_Bosskey%, L_Bosskey

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
            Random, Wait, 1000, 1500
            Sleep, Wait
            TotalWaiting += Wait
            ; Pull
            NatualPress("f", pid)
            ; Wait before throw
            UpdateTooltip()
            Random, Wait, 2000, 2500
            Sleep, Wait
            TotalWaiting += Wait
        }
        ; Throw
        if (Flag_Fishing and !isFishing()) {
            NatualPress("f", pid)
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
        ; Try destroy last item to get 1 plot
        TryDestroyLastItem()
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

L_SwitchTooltip: ; Switch Tooltip Status
    Flag_Tooltip ^= 1
    UpdateTooltip()
Return

L_SwitchDestroyer: ; Switch Destroyer Status
    Flag_Destroyer ^= 1
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

L_Bosskey: ; Hide / Show Trove
    global pid
    if (Flag_Shown) {
        WinHide ahk_exe trove.exe
        Flag_Shown := false
    }
    else {
        WinShow ahk_exe trove.exe
        Flag_Shown := true
    }
Return

TryDestroyLastItem() {
    global pid
    ; Only enable destroyer when it's turned on
    if (Flag_Destroyer) {
        ; Move mouse back in window (So the screen won't rotate)
        Random, MouseSpeed, 4, 10
        if (!SomeWindowIsShown()) {
            NatualPress("b", pid)
            NatualLongSleep()
        }
        MouseMove %RX3%, %RY3%, MouseSpeed
        NatualLongSleep()
        ; Get PID of current activated window
        WinGet, pidn, PID, A
        ; Active window in case of some pop-out window
        if (pid <> pidn) {
            WinActivate, ahk_pid %pid%
        }
        NatualLongSleep()
        ; Close all frame, and reopen bag
        if (SomeWindowIsShown()) {
            ControlSend, , {ESC}, ahk_pid %pid%
            NatualLongSleep()
        }
        NatualPress("b", pid)
        NatualLongSleep()
        ; Drop Last Item
        MouseClickDrag, Left, %RX1%, %RY1%, %RX2%, %RY2%, MouseSpeed
        NatualLongSleep()
        ; Confirm
        MouseMove %RX3%, %RY3%, MouseSpeed
        NatualSleep()
        MouseClick, Left, %RX3%, %RY3%    
        ; Give it a little time to process
        NatualLongSleep()
    }
}

NatualSleep() {
    Random, SleepTime, 66, 122
    Sleep, %SleepTime%
}

NatualLongSleep() {
    Random, SleepTime, 555, 666
    Sleep, %SleepTime%
}

NatualPress(npbtn, nppid) {
    ControlSend, , {Blind}{%npbtn% down}, ahk_pid %nppid%
    NatualSleep()
    ControlSend, , {Blind}{%npbtn% up}, ahk_pid %nppid%
    NatualSleep()
}

; ToolTip Generation

TooltipAutoFisherInfo() {
    ; AutoFisher Status
    info := "`n[AutoFisher : " . (Flag_Fishing ? "ON" : "OFF") . "]"
    if (Flag_Fishing) {
        info .= "`nFishing Status : "
        ; Fishing Area
        if (GetFishingArea() <> "Unknown") {
            info .= GetFishingArea() . " / "
        }
        ; Fishing Status
        info .= (IsHooked() ? "Hooked" : (isFishing() ? "Waiting" : "zzZ"))
    }
    ; Other Statistics
    info .= "`n" . "Lure Used : " . LureCount
    hh := Floor(TotalWaiting / 1000 / 3600)
    mm := Floor(Mod(TotalWaiting / 1000, 3600) / 60)
    ss := Floor(Mod(TotalWaiting / 1000, 60))
    info .= "`n" . "Total Wait : " . (StrLen(hh) = 1 ? "0" : "") . hh 
    info .= ":" . (StrLen(mm) = 1 ? "0" : "") . mm
    info .= ":" . (StrLen(ss) = 1 ? "0" : "") . ss
    return info
}

TooltipAutoDestroyerInfo() {
    info := "`n[AutoDestroyer : " . (Flag_Destroyer ? "ON" : "OFF") . "]"
    info .= "`n(" . RX1 . ", " . RY1 . ")"
    info .= " -> (" . RX2 . ", " . RY2 . ")"
    info .= " -> (" . RX3 . ", " . RY3 . ")"
    info .= "`nUse [" . HK_RecordLocation . "] to record mouse positions"
    return info
}

TooltipDebugInfo() {
    debugInfo := "[DEBUF INFO]"
    debugInfo .= "`nSomeWindowIsShown : " . (SomeWindowIsShown() ? "YES" : "NO")
    global Width
    global Height
    w := Width
    debugInfo .= "`nWidth : " . %w%
    debugInfo .= "`nHeight : " . %Height%
    return debugInfo
}

TooltipOperationInfo() {
    info := "`n[F11] : Trun On/Off AutoFisher"
    info .= "`n[" . HK_SwitchDestroyer . "] : Trun On/Off AutoDestroyer"
    info .= "`n[F8] : Trun On/Off Tooltip"
    info .= "`n[F6] : Close Program"
    return info
}

UpdateTooltip() {
    if (Flag_Tooltip) {
        TooltipText := "[YoRHa No.2 Type F]"
        TooltipText .= "`nGame : " . (GameIsRunning() ? "Running" : "Not Running")
        TooltipText .= "`n" . TooltipAutoFisherInfo()
        TooltipText .= "`n" . TooltipAutoDestroyerInfo()
        ; TooltipText .= "`n" . TooltipDebugInfo() 
        TooltipText .= "`n" . TooltipOperationInfo()
        Tooltip, %TooltipText%, TooltipX, TooltipY
    }
    else {
        ToolTip
    }
}