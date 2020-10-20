rem del "zombie-trash.love"

rem powershell.exe -nologo -noprofile -command "& { Add-Type -A 'System.IO.Compression.FileSystem'; [IO.Compression.ZipFile]::CreateFromDirectory('./zombie-trash', 'zombie-trash.love'); }"

rem adb push zombie-trash.love /sdcard/zombie-trash.love

rem adb shell am start -S -n "org.love2d.android/.GameActivity" -d "file:///sdcard/zombie-trash.love"

adb shell rm -r sdcard/lovegame

adb push water-shed/ /sdcard/lovegame

adb shell am start -S -n "org.love2d.android/.GameActivity"