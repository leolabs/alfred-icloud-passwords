#!/usr/bin/osascript

on replace_chars(this_text, search_string, replacement_string)
	set AppleScript's text item delimiters to the search_string
	set the item_list to every text item of this_text
	set AppleScript's text item delimiters to the replacement_string
	set this_text to the item_list as string
	set AppleScript's text item delimiters to ""
	return this_text
end replace_chars

on run argv
	set sysinfo to system info
	set osver to system version of sysinfo
	
	if osver ³ 13 then -- macOS Venture and later
		
		-- Open passwords window
		do shell script "open x-apple.systempreferences:com.apple.Passwords"
		
		set searchQuery to (item 1 of argv)
		
		tell application "System Events"
			-- Wait for window Passwords
			set expireDate to (get current date) + 10
			repeat until ((window "Passwords" in process "System Settings") exists) or ((current date) > expireDate)
				delay 0.1
			end repeat
			if ((current date) > expireDate) then
				error "Find window timeout" number 100
			end if
			
			tell window "Passwords" in process "System Settings"
				
				tell group 1 of group 2 of splitter group 1 of group 1
					
					-- Wait for the user to unlock (wait for 5s then show notification and wait for another 20s)
					set expireDate to (get current date) + 5
					repeat until (first scroll area exists) or ((current date) > expireDate)
						delay 0.1
					end repeat
					if ((current date) > expireDate) then
						display notification "Please unlock the Passwords"
						set expireDate to (get current date) + 20
						repeat until (first scroll area exists) or ((current date) > expireDate)
							delay 0.1
						end repeat
					end if
					if ((current date) > expireDate) then
						error "Find element timeout" number 100
					end if
					
					-- Type in the searchQuery
					keystroke "a" using command down
					keystroke (ASCII character 8) -- ASCII character 8 is the backspace key
					keystroke searchQuery
					
					tell group 2 of first scroll area
						if not (first scroll area exists) then
							display notification "No entry found for " & searchQuery & "."
							-- tell me to quit
							return
						end if
						set detailButton to button 1 of UI element 1 of UI element 1 of UI element 1 of first scroll area
						click detailButton
					end tell
					
					
				end tell
				
				-- Wait for the pop-up window
				set expireDate to (get current date) + 10
				repeat until (sheet 1 exists) or ((current date) > expireDate)
					delay 0.1
				end repeat
				if ((current date) > expireDate) then
					error "Find window timeout" number 100
				end if
				
				-- Copy the OTP
				tell scroll area 1 of group 1 of sheet 1
					
					if not (group 2 exists) or (number of static text of group 2) < 3 then
						display notification "No verification code found"
						-- tell me to quit
						return
					end if
					
					-- Here we cannot simply use action "AXShowMenu" because the pop-up menu is in a wired hierarchy 
					-- Instead, we get the text directly
					set otp to value of last static text of group 2
					set the clipboard to (my replace_chars(otp, " ", ""))
				end tell
				
				-- Done
				tell group 1 of sheet 1
					set doneButton to last button
					click doneButton
				end tell
				
				-- Wait for the pop-up window to disappear
				set expireDate to (get current date) + 10
				repeat until not (sheet 1 exists) or ((current date) > expireDate)
					delay 0.1
				end repeat
				if ((current date) > expireDate) then
					error "Find window timeout" number 100
				end if
				
				display notification "Verification code copied"
			end tell
		end tell
		
		tell application "System Settings" to quit
		
	else -- before macOS Venture
		
		-- Open passwords window
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
				
				# Get selected domain and account names
				set domainName to value of static text 1 of UI element 1 of firstResult
				set accountName to value of static text 2 of UI element 1 of firstResult
				
				set foundOtp to false
				
				# Look for a verification code
				repeat with verificationCode in every button of scroll area 1 of group 1
					set titleMatch to do shell script "sed 's/[^0-9]//g' <<<" & quoted form of (title of verificationCode as string)
					
					# Code should be at least 6 characters long
					if (count titleMatch as string) ³ 6 then
						perform action "AXShowMenu" of verificationCode
						click menu item 1 of menu 1 of verificationCode
						
						display notification accountName with title "Copied verification code" subtitle domainName
						set foundOtp to true
					end if
				end repeat
				
				if not foundOtp then
					display notification "Account " & accountName & " has no OTP"
				end if
			end tell
			
			tell application "System Settings" to quit
		end tell
	end if
	
end run