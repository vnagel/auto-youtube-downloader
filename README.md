# Auto YouTube Downloader
This project contains an AutoHotkey script that uses Chrome and VLC media player to automatically download YouTube videos.

## Getting Started

### Prerequisites
You must be running Windows because that is the only OS supported by AutoHotkey.

Install [Chrome](https://www.google.com/chrome/) and [VLC media player](https://www.videolan.org/vlc/).

You can run autoYoutubeDownloader.exe found in the [releases](https://github.com/vnagel/auto-youtube-downloader/releases) without installing any additional software. It must be run in a directory containing all the project files. If you want to edit the script, you need to install [AutoHotkey](https://www.autohotkey.com/download/).

You might need to retake the screen clippings that are in the "images" directory if the your screen resolution differs from mine (1920 x 1080).

### Usage
Create a text file with the URL's of the YouTube videos you want to download each on their own line.

F4: Run script. You will be prompted to enter the filepath to the text file and the directory you want to save the videos to.

Ctrl + Alt + r: Reload script

Ctrl + Alt + e: Exit script

Ctrl + Alt + p: Pause script

## To-do List
* Bugs
  * Chrome sometimes loses focus on first search. Possible fix: Search screen (not window) for search bar and click instead of using Ctrl + l
  * Script sometimes stops when saving video
* Enhancements
  * Handle saving video when name already exists in directory. Have user specify overwrite or skip at start of script?
  * Add checks for windows off screen before clicking. Add error logs for this.
  * Add more logging
  * Remove unnecessary Sleep calls. Change SendMode?
  * Make user screen clip all images when first open program and/or provide screen clippings for all common screen resolutions
  * Search images by text so don't have so many images. However, this could incorrectly pick up other things such as folder and file names
  * Add screen clippings for buttons in the case that mouse is hovering over them or just move cursor to corner of screen before doing image searches.
  * Switch to Internet Explorer or Edge to handle webpages better? Or use [Selenium](https://www.reddit.com/r/AutoHotkey/comments/6dmzbf/using_selenium_autohotkey_to_automate_browsers/)?

## Attributions
Part of autoYoutubeDownloader.ahk was made using [Pulover's Macro Creator](https://github.com/Pulover/PuloversMacroCreator).

JSON parsing is done using [AutoHotkey-JSON](https://github.com/cocobelgica/AutoHotkey-JSON)