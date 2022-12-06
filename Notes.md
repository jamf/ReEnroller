#  Suppress notification

sign launch daemon:
/usr/bin/codesign --sign "Apple Development: Leslie N. Helou (J82ZK9L28H)" --identifier "com.jamf.ReEnroller" /Users/leslie/Documents/-projects/ReEnroller/v5.6.2/ReEnroller.app/Contents/Resources/com.jamf.ReEnroller.plist
(must sign the plist after the app is built)

view signing info:
 codesign -dv /Users/leslie/Documents/-projects/ReEnroller/v5.6.2/ReEnroller.app/Contents/Resources/com.jamf.ReEnroller.plist


[manage login items ventura](https://hammen.medium.com/managing-login-items-for-macos-ventura-e78d627f88b6)
Used TeamIdentifier: PS2F6S478M
