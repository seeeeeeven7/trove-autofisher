; single instance
#SingleInstance force

; run as administrator
if (not A_IsAdmin) {
    Run *RunAs "%A_ScriptFullPath%"
    ExitApp
}

; forcefully active window
#WinActivateForce

; includes
#Include Memory.ahk

; Global Constaints
global HK_SwitchFisher := "F11"
global HK_SwitchDestroyer := "F10"
global HK_SwitchTooltip := "F8"
global HK_Exit := "F6"
global HK_RecordLocation := "F3"
global HK_Bosskey := "!Q"

global TooltipX := 100
global TooltipY := 100
global World_Moment := 500
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

; world
while True {
    ; update process's info
    GetProcessInfo()
    ; give world a moment
    TryGiveWorldAMoment()
    ; update Tooltip
    UpdateTooltip()
    ; hang on a while
    Wait(World_Moment, isFishing())
}

TryGiveWorldAMoment() {
    ; current waiting time that doubles itself each failure
    static error_waiting := 1000
    ; if authofisher is ON
    if Flag_Fishing {
        ; fishing status
        if isFishing() {
            if isHooked() {
                ; wait before pull
                RandomWait(750, true)
                ; pull
                NatualPress("f", pid)
                ; wait for pulling
                RandomWait(2000, true)
            }
        }
        else {
            ; throw lure
            NatualPress("f", pid)
            LureCount += 1
            ; wait a while
            RandomWait(500, true)
            ; failure
            if !isFishing() {
                ; try destroy last item to get that plot
                TryDestroyLastItem()
                ; dynamic delay (to avoid meaningless throw)
                rest := error_waiting
                while Flag_Fishing and rest > 0 {
                    Wait(World_Moment, true)
                    rest -= World_Moment
                }
                ; doubles waiting time each failure
                error_waiting *= 2
            }
            else {
                error_waiting := 1000
                ; wait a while
                RandomWait(500, true)
            }
        }
    }
    else {
        currentHP := GetAvatarHP()
        currentHPMAX := GetAvatarHPMAX()
        if (currentHP > 0 and currentHPMAX < 10000000 and currentHP * 4 <= currentHPMAX) {
            TryRecover()
        }
    }
}

TryRecover() {
    static cooldown = 0
    if (cooldown = 0) 
    {
        NatualPress("q", pid)
        cooldown := 2
    }
    else 
    {
        cooldown -= 1
    }
}

TryDestroyLastItem() {
    global pid
    ; Only enable destroyer when it's turned on
    if (Flag_Destroyer) {
        ; Move mouse back in window (So the screen won't rotate)
        Random, MouseSpeed, 4, 10
        if (!SomeWindowIsShown()) {
            NatualPress("b", pid)
            RandomWait(500, false)
        }
        MouseMove %RX3%, %RY3%, MouseSpeed
        RandomWait(500, false)
        ; Get PID of current activated window
        WinGet, pidn, PID, A
        ; Active window in case of some pop-out window
        if (pid <> pidn) {
            WinActivate, ahk_pid %pid%
        }
        RandomWait(500, false)
        ; Close all frame, and reopen bag
        if (SomeWindowIsShown()) {
            ControlSend, , {ESC}, ahk_pid %pid%
            RandomWait(500, false)
        }
        NatualPress("b", pid)
        RandomWait(500, false)
        ; Drop Last Item
        MouseClickDrag, Left, %RX1%, %RY1%, %RX2%, %RY2%, MouseSpeed
        RandomWait(500, false)
        ; Confirm
        MouseMove %RX3%, %RY3%, MouseSpeed
        RandomWait(100, false)
        MouseClick, Left, %RX3%, %RY3%    
        ; Give it a little time to process
        RandomWait(500, false)
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

; operations that feels more normal(randomly)

Wait(time, record) {
    UpdateTooltip()
    Sleep, %time%
    if record {
        TotalWaiting += time
    }
}

RandomWait(time, record) {
    Random, rtime, floor(time * 3 / 4), floor(time * 5 / 4)
    Wait(rtime, record)
}

NatualPress(npbtn, nppid) {
    ControlSend, , {Blind}{%npbtn% down}, ahk_pid %nppid%
    RandomWait(100, false)
    ControlSend, , {Blind}{%npbtn% up}, ahk_pid %nppid%
    RandomWait(100, false)
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
        TooltipText .= "`nHP : " (GetAvatarHPMAX() = 0 ? "Loading" : GetAvatarHP() "/" GetAvatarHPMAX())
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