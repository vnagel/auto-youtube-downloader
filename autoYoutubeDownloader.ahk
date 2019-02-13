#Include JSON.ahk

#NoEnv
SetWorkingDir %A_ScriptDir%
CoordMode, Mouse, Window
SendMode Input
#SingleInstance Force
SetTitleMatchMode 2
#WinActivateForce
SetControlDelay 1
SetWinDelay 0
SetKeyDelay -1
SetMouseDelay -1
SetBatchLines -1

; -1 is an invalid process id on windows
vlc := -1
chrome := -1

^!r::
closeProcessWindows(vlc)
closeProcessWindows(chrome)
Reload
Return

^!e::ExitApp

^!p::Pause

F4::
main:
filepaths := getFilepathsFromUser()
vlc := vlcOpen()
chrome := chromeOpen()
Loop, Read, % filepaths.youtubeUrlTxtFilepath
{
    ; get title of youtube video
    activateAndWaitPid(chrome)
    chromeJumpAddressBar()
    sendYoutubeOembedUrl(A_LoopReadLine)
    Send, {Enter}
    websiteWaitLoad("images\youtubeIcon.png")
    youtubeTitle := youtubeGetTitle()

    ; get url of video
    activateAndWaitPid(vlc)
    vlcOpenNetworkStream(vlc)
    vlcPlayNetworkStream(A_LoopReadLine, vlc)
    vlcHandleNetworkStreamError(filepaths.errorLogDir, vlc, chrome)
    vlcOpenCodecInformation(vlc)
    codecInfo := vlcGetCodecInformation(vlc)
    vlcExitCodecInformation()

    ; save video
    activateAndWaitPid(chrome)
    chromeJumpAddressBar()
    clipboardSendRaw(codecInfo)
    Send, {Enter}
    websiteWaitLoad("images\pageTabIcon.png")
    chromeSaveVideo(filepaths.saveDir, youtubeTitle, chrome)
    chromeCloseDownloadsSnackbar(chrome)
}
closeProcessWindows(vlc)
closeProcessWindows(chrome)
Return

websiteWaitLoad(chromeTabIcon)
{
    Sleep, 1000
    searchEndX := A_ScreenWidth // 8
    searchEndY := A_ScreenHeight // 8
    Loop
    {
        CoordMode, Pixel, Screen
        ImageSearch, FoundX, FoundY, 0, 0, searchEndX, searchEndY, %chromeTabIcon%
        CoordMode, Pixel, Window
    }
    Until ErrorLevel = 0
    Sleep, 1000
}

vlcOpen()
{
    Run, "vlc.exe", , , vlc
    WinWaitActive, ahk_pid %vlc%
    Sleep, 333
    fullscreen()
    return vlc
}

chromeOpen()
{
    IfWinExist, New Tab - Google Chrome ahk_class Chrome_WidgetWin_1 ahk_exe chrome.exe
    {
        Run, "chrome.exe"  ; returns incorrect chrome pid
        Sleep, 1000  ; to prevent matching on existing chrome tab
    }
    Else
    {
        Run, "chrome.exe"  ; returns incorrect chrome pid
    }
    WinWaitActive, New Tab - Google Chrome ahk_class Chrome_WidgetWin_1 ahk_exe chrome.exe
    Sleep, 333
    chrome := getActiveWindowPid()
    fullscreen()
    return chrome
}

activateAndWaitPid(pid)
{
    WinActivate, ahk_pid %pid%
    WinWaitActive, ahk_pid %pid%
    Sleep, 333
}

fullscreen()
{
    Send, #{up}
    Sleep, 333
}

chromeJumpAddressBar()
{
    Send, ^l
    Sleep, 333
}

vlcOpenNetworkStream(vlcPid)
{
    Send, ^n
    WinWaitActive, Open Media ahk_class Qt5QWindowIcon ahk_exe vlc.exe ahk_pid %vlcPid%
    Sleep, 333
}

vlcHandleNetworkStreamError(logDirFilepath, vlcPid, chromePid)
{
    logFilepath := logDirFilepath "\autoYoutubeDownloaderErrorLog.txt"
    IfWinExist, Errors ahk_class Qt5QWindowIcon ahk_exe vlc.exe ahk_pid %vlcPid%
    {
        WinWaitActive, Errors ahk_class Qt5QWindowIcon ahk_exe vlc.exe ahk_pid %vlcPid%
        Sleep, 333

        WinGetPos, , , windowWidth, windowHeight,Errors ahk_class Qt5QWindowIcon ahk_exe vlc.exe ahk_pid %vlcPid%
        Sleep, 333
        clickX := windowWidth // 2
        clickY := windowHeight // 2
        Click, %clickX%, %clickY%, Left, 1
        Sleep, 333

        Send, ^a
        Sleep, 333
        Send, ^c
        Sleep, 333
        FormatTime, currentTime
        errorMsg := currentTime . "`r`n" . Clipboard . "`r`n"

        FileAppend, %errorMsg%, %logFilepath%
        MsgBox, Error occurred when attempting to stream video.`r`nError log saved to %logFilepath%
        closeProcessWindows(vlcPid)
        closeProcessWindows(chromePid)
        Reload
    }
}

vlcPlayNetworkStream(url, vlcPid)
{
    Send, ^a
    Sleep, 333
    clipboardSendRaw(url)

    WinGetPos, , , windowWidth, windowHeight, Open Media ahk_class Qt5QWindowIcon ahk_exe vlc.exe ahk_pid %vlcPid%
    Loop
    {
        CoordMode, Pixel, Window
        ImageSearch, FoundX, FoundY, 0, 0, windowWidth, windowHeight, images\vlcNetworkStreamPlayButton.png
        CenterImgSrchCoords("images\vlcNetworkStreamPlayButton.png", FoundX, FoundY)
    }
    Until ErrorLevel = 0
    Click, %FoundX%, %FoundY% Left, 1
    Sleep, 2000
}

vlcOpenCodecInformation(vlcPid)
{
    Send, ^j
    Sleep, 333
    WinWaitActive, Current Media Information ahk_class Qt5QWindowIcon ahk_exe vlc.exe ahk_pid %vlcPid%
    Sleep, 333
}

vlcGetCodecInformation(vlcPid)
{
    codecInfo := ""
    isSrcLocation := 0
    WinGetPos, , , windowWidth, windowHeight, Current Media Information ahk_class Qt5QWindowIcon ahk_exe vlc.exe ahk_pid %vlcPid%

    Loop
    {
        CoordMode, Pixel, Window
        ImageSearch, FoundX, FoundY, 0, 0, windowWidth, windowHeight, images\vlcCodecInfoLocationTxt.png
        CenterImgSrchCoords("images\vlcCodecInfoLocationTxt.png", FoundX, FoundY)
    }
    Until ErrorLevel = 0

    clickX := windowWidth // 2
    clickY := FoundY

    While not isSrcLocation
    {
        Sleep, 1000
        Click, %clickX%, %clickY%, Left, 3
        Sleep, 333
        Send, ^c
        Sleep, 333
        codecInfo := Clipboard
        isSrcLocation := InStr(codecInfo, "googlevideo")
    }
    return codecInfo
}

vlcExitCodecInformation()
{
    Send, {Esc}
    Sleep, 333
}

chromeSaveVideo(saveDir, youtubeTitle, chromePid)
{
    Send, ^s
    WinWaitActive, Save As ahk_class #32770 ahk_exe chrome.exe ahk_pid %chromePid%
    Sleep, 333
    WinGetPos, , , windowWidth, windowHeight, Save As ahk_class #32770 ahk_exe chrome.exe ahk_pid %chromePid%

    ; enter filename
    Loop
    {
        CoordMode, Pixel, Window
        ImageSearch, FoundX, FoundY, 0, 0, windowWidth, windowHeight, images\chromeSaveAsFilenameTxt.png
        CenterImgSrchCoords("images\chromeSaveAsFilenameTxt.png", FoundX, FoundY)
    }
    Until ErrorLevel = 0
    clickX := windowWidth // 2
    clickY := FoundY
    Click, %clickX%, %clickY%, Left, 1
    Sleep, 333
    Send, ^a
    Sleep, 333
    clipboardSendRaw(youtubeTitle)

    ; enter file location
    Send, !d
    Sleep, 333
    Send, ^a
    Sleep, 333
    clipboardSendRaw(saveDir)
    Send, {Enter}
    Sleep, 333

    ; click save
    Loop
    {
        CoordMode, Pixel, Window
        ImageSearch, FoundX, FoundY, 0, 0, windowWidth, windowHeight, images\chromeSaveAsSaveButton.png
        CenterImgSrchCoords("images\chromeSaveAsSaveButton.png", FoundX, FoundY)
    }
    Until ErrorLevel = 0
    Click, %FoundX%, %FoundY%, Left, 1
    Sleep, 333
}

getActiveWindowPid()
{
    id := WinExist("A")
    WinGet, pid, PID, ahk_id %id%
    return pid
}

youtubeGetTitle()
{
    Send, ^a
    Sleep, 333
    Send, ^c
    Sleep, 333
    data := JSON.Load(Clipboard)
    title := data["title"]

    invalidFilenameCharacters := Array("/", "\", ":", "*", "?", "", "<", ">", "|")
    For key, value in invalidFilenameCharacters
    {
        title := StrReplace(title, value, " ")
    }
    return title
}

getFilepathsFromUser()
{
    ; For faster testing, comment out this section and uncomment the line below (you will likely have to change the filepaths).
    inputBoxTitle := "Auto YouTube Downloader"
    InputBox, youtubeUrlTxtFilepath, %inputBoxTitle%, Enter filepath to the text file with YouTube URL's.`r`ne.g. C:\Users\vnagel\Documents\youtubeDownloadList.txt
    InputBox, saveDir, %inputBoxTitle%, Enter filepath to directory to save videos. Directory must already exist.`r`ne.g. C:\Users\vnagel\Videos
    InputBox, errorLogDir, %inputBoxTitle%, Enter filepath to directory to save error logs. Directory must already exist.`r`ne.g. C:\Users\vnagel\Documents
    filepaths := {youtubeUrlTxtFilepath: youtubeUrlTxtFilepath, saveDir: saveDir, errorLogDir: errorLogDir}

    ; filepaths := {youtubeUrlTxtFilepath: "D:\Videos\Android\androidVideoDownloadList.txt", saveDir: "D:\Videos\Android\testing", errorLogDir: "D:\Videos\Android\testing",}

    return filepaths
}

chromeCloseDownloadsSnackbar(chromePid)
{
    WinGetPos, , , windowWidth, windowHeight, ahk_class Chrome_WidgetWin_1 ahk_exe chrome.exe ahk_pid %chromePid%
    searchStartX := windowWidth - windowWidth // 8
    searchStartY := windowHeight - windowHeight // 8
    Loop
    {
        CoordMode, Pixel, Window
        ImageSearch, FoundX, FoundY, searchStartX, searchStartY, windowWidth, windowHeight, images\chromeDownloadSnackbarX.png
        CenterImgSrchCoords("images\chromeDownloadSnackbarX.png", FoundX, FoundY)
    }
    Until ErrorLevel = 0
    Click, %FoundX%, %FoundY%, Left, 1
    Sleep, 333
}

closeProcessWindows(pid)
{
    DetectHiddenWindows, On
    While WinExist("ahk_pid" pid)
    {
        WinClose, ahk_pid %pid%
    }
    DetectHiddenWindows, Off
}

; pasting from clipboard is faster than SendRaw
clipboardSendRaw(text)
{
    Clipboard := text
    Send, ^v
    Sleep, 333
}

sendYoutubeOembedUrl(youtubeVidUrl)
{
    urlPrefix := "https://www.youtube.com/oembed?format=json&url="
    fullUrl := urlPrefix . youtubeVidUrl
    clipboardSendRaw(fullUrl)
}

CenterImgSrchCoords(File, ByRef CoordX, ByRef CoordY)
{
	static LoadedPic
	LastEL := ErrorLevel
	Gui, Pict:Add, Pic, vLoadedPic, %File%
	GuiControlGet, LoadedPic, Pict:Pos
	Gui, Pict:Destroy
	CoordX += LoadedPicW // 2
	CoordY += LoadedPicH // 2
	ErrorLevel := LastEL
}
