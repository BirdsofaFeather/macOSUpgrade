#!/bin/bash

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
#
# Copyright (c) 2017 Jamf.  All rights reserved.
#
#       Redistribution and use in source and binary forms, with or without
#       modification, are permitted provided that the following conditions are met:
#               * Redistributions of source code must retain the above copyright
#                 notice, this list of conditions and the following disclaimer.
#               * Redistributions in binary form must reproduce the above copyright
#                 notice, this list of conditions and the following disclaimer in the
#                 documentation and/or other materials provided with the distribution.
#               * Neither the name of the Jamf nor the names of its contributors may be
#                 used to endorse or promote products derived from this software without 
#                 specific prior written permission.
#
#       THIS SOFTWARE IS PROVIDED BY JAMF SOFTWARE, LLC "AS IS" AND ANY
#       EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
#       WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
#       DISCLAIMED. IN NO EVENT SHALL JAMF SOFTWARE, LLC BE LIABLE FOR ANY
#       DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
#       (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
#       LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
#       ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
#       (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
#       SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# 
# This script was designed to be used in a Self Service policy to ensure specific
# requirements have been met before proceeding with an inplace upgrade to macOS Sierra, 
# as well as to address changes Apple has made to the ability to complete macOS upgrades 
# silently. 
#
# REQUIREMENTS:
#			- Jamf Pro
#			- macOS Sierra Installer must be staged in /Users/Shared/
#
#
# For more information, visit https://github.com/kc9wwh/macOSUpgrade
#
#
# Written by: Joshua Roskos | Professional Services Engineer | Jamf
#
# Created On: January 5th, 2017
# Updated On: February 3rd, 2017
# 
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# USER VARIABLES
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 

##Enter 0 for Full Screen, 1 for Utility window (screenshots available on GitHub)
userDialog=0

##Title to be used for userDialog (only applies to Utility Window)
title="macOS Sierra Upgrade"

##Heading to be used for userDialog
heading="Please wait as we prepare your computer for macOS Sierra..."

##Title to be used for userDialog
description="
This process will take approximately 5-10 minutes. 
Once completed your computer will reboot and begin the upgrade."

##Icon to be used for userDialog
##Default is macOS Sierra Installer logo which is included in the staged installer package
icon=/Users/Shared/Install\ macOS\ Sierra.app/Contents/Resources/InstallAssistant.icns

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# SYSTEM CHECKS
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 

##Check if device is on battery or ac power
pwrAdapter=$( /usr/bin/pmset -g ac )
if [[ ${pwrAdapter} == "No adapter attached." ]]; then
	pwrStatus="ERROR"
else
	pwrStatus="OK"
fi

##Check if free space > 15GB
freeSpace=$( /usr/sbin/diskutil info / | grep "Free Space" | awk '{print $4}' )
if [[ ${freeSpace%.*} -ge 15 ]]; then
	spaceStatus="OK"
else
	spaceStatus="ERROR"
fi

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# APPLICATION
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 

if [[ ${pwrStatus} == "OK" ]] && [[ ${spaceStatus} == "OK" ]]; then
    ##Launch jamfHelper
    if [[ ${userDialog} == 0 ]]; then
	    /Library/Application\ Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper -windowType fs -title "" -icon "$icon" -heading "$heading" -description "$description" &
	    jamfHelperPID=$(echo $!)
    fi
    if [[ ${userDialog} == 1 ]]; then
	    /Library/Application\ Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper -windowType utility -title "$title" -icon "$icon" -heading "$heading" -description "$description" -iconSize 100 &
	    jamfHelperPID=$(echo $!)
    fi

	##Begin Upgrade
	/Users/Shared/Install\ macOS\ Sierra.app/Contents/Resources/startosinstall --volume / --applicationpath /Users/Shared/Install\ macOS\ Sierra.app --nointeraction --pidtosignal $jamfHelperPID &
    /bin/sleep 3
else
	/usr/bin/osascript -e 'Tell application "System Events" to display dialog "Your computer does not meet the requirements necessary to continue.

	Please contact the help desk for assistance. " with title "macOS Sierra Upgrade" with text buttons {"OK"} default button "OK" with icon 2'
fi

exit 0