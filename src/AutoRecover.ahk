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

; world
while True {
    ; update process's info
    GetProcessInfo()
    ; give world a moment
    TryRecover()
    ; hang on a while
    Sleep, 100
}
Return

TryRecover() {
    global pid
    static cooldown = 0
    currentHP := GetAvatarHP()
    currentHPMAX := GetAvatarHPMAX()
    if (cooldown = 0) 
    {
        if (currentHP > 0 and currentHPMAX < 10000000 and currentHP * 4 <= currentHPMAX) {
            NatualPress("q", pid)
            cooldown := 1
        }
    }
    else 
    {
        cooldown -= 1
    }
}

NatualPress(npbtn, nppid) {
    ControlSend, , {Blind}{%npbtn% down}, ahk_pid %nppid%
    ControlSend, , {Blind}{%npbtn% up}, ahk_pid %nppid%
}

F4::
    hp := GetAvatarHP()
    MsgBox, %hp%
Return