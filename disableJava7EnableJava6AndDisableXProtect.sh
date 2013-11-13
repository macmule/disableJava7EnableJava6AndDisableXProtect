#!/bin/sh
####################################################################################################
#
# This is free and unencumbered software released into the public domain.
# 
# Anyone is free to copy, modify, publish, use, compile, sell, or
# distribute this software, either in source code form or as a compiled
# binary, for any purpose, commercial or non-commercial, and by any
# means.
# 
# In jurisdictions that recognise copyright laws, the author or authors
# of this software dedicate any and all copyright interest in the
# software to the public domain. We make this dedication for the benefit
# of the public at large and to the detriment of our heirs and
# successors. We intend this dedication to be an overt act of
# relinquishment in perpetuity of all present and future rights to this
# software under copyright law.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR
# OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
# ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
# OTHER DEALINGS IN THE SOFTWARE.
# 
# For more information, please refer to <http://unlicense.org/>
#
####################################################################################################
#
# ABOUT THIS PROGRAM
#
# NAME
#  This script is to be used to get Java 6 working on a mac that has only had Java 7 before hand.
#
#	"Java 2012-006" (http://support.apple.com/kb/DL1572) is required to be installed 1st.
#
#	Liberally pinched from: 
#	https://github.com/rtrouton/rtrouton_scripts/tree/master/rtrouton_scripts/re-enable_java_6
#	https://github.com/rtrouton/rtrouton_scripts/tree/master/rtrouton_scripts/enable_java_web_plugins_at_login
#	http://managingosx.wordpress.com/2013/01/31/disabled-java-plugins-xprotect-updater/
#
#
# DESCRIPTION
#	This script will; disable the Java 7 plugin, re-enable the Java 6  plugin & disables XProtect.
#
#	And, this script will set /Applications/Safari.app as the default application for the html MIME type
#	for the currently logged in user.
#
####################################################################################################
#
# More information: http://macmule.com/2013/02/18/getting-java-6-working-on-a-mac-that-has-only-had-java-7-installed/
#
# GitRepo: https://github.com/macmule/disableJava7EnableJava6AndDisableXProtect
#
####################################################################################################
#
# DEFINE VARIABLES & READ IN PARAMETERS
#
####################################################################################################

###
# Get logged in users username & home folder path for plist creation later.
###
loggedInUser=`/bin/ls -l /dev/console | /usr/bin/awk '{ print $3 }'`
loggedInUserHome=`dscl . -read /Users/$loggedInUser | grep  NFSHomeDirectory: | cut -c 19- | head -n 1`

echo "Home Directory for: $loggedInUser, is here: $loggedInUserHome..."

###
# Get the Macs UUID
###

if [[ `ioreg -rd1 -c IOPlatformExpertDevice | grep -i "UUID" | cut -c27-50` == "00000000-0000-1000-8000-" ]]; then
	MAC_UUID=`ioreg -rd1 -c IOPlatformExpertDevice | grep -i "UUID" | cut -c51-62 | awk {'print tolower()'}`
elif [[ `ioreg -rd1 -c IOPlatformExpertDevice | grep -i "UUID" | cut -c27-50` != "00000000-0000-1000-8000-" ]]; then
	MAC_UUID=`ioreg -rd1 -c IOPlatformExpertDevice | grep -i "UUID" | cut -c27-62`
fi

echo "This Mac's UUID is: $MAC_UUID..."

###
# Checks for backup directory for Java 7 plug-in, creating if needed.
###

if [ -d "/Library/Internet Plug-Ins (Disabled)" ]; then
     echo "Directory /Library/Internet Plug-Ins (Disabled) found. Skipping... "
  else
     mkdir "/Library/Internet Plug-Ins (Disabled)"
     chown -R root:wheel "/Library/Internet Plug-Ins (Disabled)"
     echo "Directory /Library/Internet Plug-Ins (Disabled) not found. Creating... "
fi

###
# Removes previous versions for Java 7 if found in "Internet Plug-Ins (Disabled)"
###

if [ -d "/Library/Internet Plug-Ins (Disabled)/JavaAppletPlugin.plugin" ]; then
      rm -rf "/Library/Internet Plug-Ins (Disabled)/JavaAppletPlugin.plugin"
      echo "Deleting previous Java 7 plug-in found in /Library/Internet Plug-Ins (Disabled)..."
fi

###
# Moves current Java 7 plug-in to the backup directory
###

if [ -d "/Library/Internet Plug-Ins/JavaAppletPlugin.plugin" ]; then
     mv "/Library/Internet Plug-Ins/JavaAppletPlugin.plugin" "/Library/Internet Plug-Ins (Disabled)/JavaAppletPlugin.plugin"
     echo "Moving Java 7 plug-in to /Library/Internet Plug-Ins (Disabled)..."
fi

###
# Create symlink to the Apple Java 6 plug-in in /Library/Internet Plug-Ins 
###

ln -sf "/System/Library/Java/Support/Deploy.bundle/Contents/Resources/JavaPlugin2_NPAPI.plugin" "/Library/Internet Plug-Ins/JavaAppletPlugin.plugin"
echo "Created symlink for Java 6 plug-in..."

###
# Re-enable Java SE 6 Web Start, which allows Java applets to run in web browsers
###

ln -sf "/System/Library/Frameworks/JavaVM.framework/Commands/javaws" "/usr/bin/javaws"
echo "Re-enabled Java SE 6 Web Start..."

###
# Set the the "Enable applet plug-in and Web Start Applications" setting in the Java Preferences for the current user.
###

/usr/libexec/PlistBuddy -c "Delete :GeneralByTask:Any:WebComponentsEnabled" "$loggedInUserHome"/Library/Preferences/ByHost/com.apple.java.JavaPreferences.${MAC_UUID}.plist
/usr/libexec/PlistBuddy -c "Add :GeneralByTask:Any:WebComponentsEnabled bool true" "$loggedInUserHome"/Library/Preferences/ByHost/com.apple.java.JavaPreferences.${MAC_UUID}.plist
/usr/libexec/PlistBuddy -c "Delete :GeneralByTask:Any:WebComponentsLastUsed" "$loggedInUserHome"/Library/Preferences/ByHost/com.apple.java.JavaPreferences.${MAC_UUID}.plist
/usr/libexec/PlistBuddy -c "Add :GeneralByTask:Any:WebComponentsLastUsed real $(( $(date "+%s") - 978307200 ))" "$loggedInUserHome"/Library/Preferences/ByHost/com.apple.java.JavaPreferences.${MAC_UUID}.plist

##
# Delete the JavaAppletPlugin version key from XProtect
###

sudo /usr/libexec/PlistBuddy -c "Delete :JavaWebComponentVersionMinimum" /System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/XProtect.meta.plist

###
# Stop XProtect Updating itself
###

sudo /bin/launchctl unload -w "/System/Library/LaunchDaemons/com.apple.xprotectupdater.plist"

exit 0
