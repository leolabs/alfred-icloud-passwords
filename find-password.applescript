#!/usr/bin/osascript

on run argv
# Open passwords window
do shell script "open /Library/Apple/System/Library/CoreServices/SafariSupport.bundle/Contents/PreferencePanes/Passwords.prefPane"

set searchQuery to (item 1 of argv)

tell application "System Events"
	tell window "Passwords" of process "System Preferences"
		# Wait for search field to be available
		repeat until ((first text field whose subrole is "AXSearchField") exists)
			delay 0.1
		end repeat
		
		# Enter the search query
		set value of first text field whose subrole is "AXSearchField" to searchQuery
		
		set results to outline 1 of scroll area 1
		
		if not (row 2 of results exists) then
			display notification "No entry found for " & searchQuery & "."
			tell me to quit
		end if
		
		# First result is the second row, first row is the search field
		set firstResult to row 2 of results
		
		# Select the first result
		set selected of firstResult to true
	end tell
end tell
end run