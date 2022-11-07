write-host "`nThis script requires the installation of AzureAD, MSOL, NuGet, and ExchangeOnline (or EXO V2)." -foregroundcolor Yellow
write-host "If you are missing one of these you've surely hit an error before reading to this point (If not, you're a fast reader!)." -foregroundcolor Yellow
write-host "Please make sure you're signed in to AzureAD, MSOL, and ExchangeOnline before re-running the script!" -foregroundcolor Yellow

#Lists for users info
$userHolder = @()
$masterList = @()

#Lists for users, depending on their info
$allOftheAbove = @()
$somethingOff = @()


#Counter for the sake of the user
$counter = 0

write-host "`nPulling list of users with credentials blocked and a list of users with E3 Licenses (for comparison)..."
$null = $userHolder = get-azureaduser -filter "AccountEnabled eq false" -all $true
$whoHasE3 = get-msoluser -all | where-object {($_.licenses.accountskuid -match "enterprisepack")} | select-object DisplayName | out-string
$numberOfusers = $userHolder.length

write-host "`nFinding if each user has a litigation hold (and it's length), marked as 'Terminated', and if they have an E3 license..."
foreach ($user in $userHolder)
{
    #Declarations in the list to act as a clear
    $countryInfo = " "
    $litHold = " "
    $litHoldlength = " "
    $userInbetween = ""
    
    #Pulling Display Name
    $usersName = $user.displayname

    #Pulling "Country" (If country is blank regex returns TRUE, so I'm manually entering a blank)
    $countryInfo = get-azureaduser -searchstring $user.displayname | select-object Country
    $pattern = "@{Country=([A-z]* *[A-z]*)}"
    if($countryInfo -match $pattern)
    {
        $countryInfo = $Matches[1]
    }
    if($countryInfo -eq $true)
    {
        $countryInfo = " "
    }

    #Checking to see if they have a litigation hold or not
    try
    {
        $litHold = get-mailbox -identity $user.objectid -erroraction stop | format-list litigationholdenabled | out-string
        $pattern = "LitigationHoldEnabled : ([A-z]+)"
        if($litHold -match $pattern)
        {
            $litHold = $Matches[1]
        }
        $litHoldlength = get-mailbox -identity $user.objectid -erroraction stop | format-list litigationholdduration | out-string
        $pattern = "LitigationHoldDuration : ([A-z]* *[0-9]*)"
        if($litHoldlength -match $pattern)
        {
            $litHoldlength = $Matches[1]
        }
    }
    catch
    {
        $litHold = "NoLicense"
        $litHoldlength = "Unspecified"
    }

    #Checking for EnterprisePack or "E3" license (This is comparing every blocked credential user with the list everytime, there must be a better way)
    if($whoHasE3.contains("$usersName"))
    {
        $licenseYorN = "TRUE"
    }
    else
    {
        $licenseYorN = "FALSE"
    }
    
    #Checking the info to sort the user appropriatley
    if($countryInfo -eq "Terminated" -and $litHold -eq "TRUE" -and $litHoldlength -eq "UNLIMITED" -and $licenseYorN -eq "FALSE")  #Might need to change lithold, becuase all of them will have "unlimited"
    {
        $userInbetween = @($usersName, $countryInfo, $litHold, $litHoldlength, $licenseYorN, "TRUE")
        $allOftheAbove += , $userInbetween
    }
    else
    {
        $userInbetween = @($usersName, $countryInfo, $litHold, $litHoldlength, $licenseYorN, "FALSE")
        $somethingOff += , $userInbetween 
    }


    #Updated messages
    write-progress -percentcomplete ($counter/$numberOfusers*100) -activity "Sorting Users With Blocked Credentials..." -status "In Progress"
    $counter += 1
}


###########################################################################################################################################################################################

#CSV creation

$masterList +=  @($allOftheAbove, $somethingOff)
$numberOfusers = $allOftheAbove.length + $somethingOff.length

#Transfering info to CSV
write-host "Transferring user info to a CSV file..."
$CSVheader = "DisplayName,Country,LitigationHoldActivated,LengthofLitgationHold,HaveE3License,PassedAllChecks"
$dateForCSV = get-date -format "MM-dd-yyyy"
$CSVheader | out-file -filepath ".\O365Audit$dateForCSV.csv" -encoding UTF8
foreach($seperateList in $masterList)
{
    $counter = 0
    $counterHolder = $seperateList.length

    foreach($individualPerson in $seperateList)
    {
        $stringHolder = ""
        foreach($detail in $individualPerson)
        {
            $stringHolder += "$detail" + ","
        }
        $stringHolder | out-file -filepath ".\O365Audit$dateForCSV.csv" -append -encoding UTF8

        $counter += 1
        write-progress -percentcomplete ($counter/($counterHolder)*100) -activity "Adding users to CSV..." -status "Writing to File"
        
    }
}

#Updating the user of the CSV's existence
write-host "`nFinished!"
write-host "Check you're downloads for a CSV titled: " -NoNewline; write-host "O365Audit$dateForCSV.csv" -foregroundcolor Green
write-host "The CSV is formatted with everyone who passed every check on the top and then everyone who was missing something from the checks below."
write-host "`nAll the users displayed have credentials blocked, the checks include..."
write-host "Country field reads 'Terminated', litigation hold is 'TRUE', length of litigation hold is 'UNLIMITED', and E3 license is 'FALSE'"


###########################################################################################################################################################################################


#Showing who can be deleted

if($allOftheAbove.length -le 20 )
{
    write-host "`nThe users who passed all these checks, and can be deleted are..."
    foreach($checkedUser in $allOftheAbove)
    {
        write-host $checkedUser[0] -foregroundcolor yellow
    }
}
else
{
    write-host "`nThere are more than 20 people that passed all the checks, please look at them in the CSV and return here."
}


###########################################################################################################################################################################################

#First and second check to make sure the user wants people deleted
$theAnswercontinue = $false
while($theAnswercontinue -eq $false)
{
    write-host "`nDo you want me to delete these users (you can select specific users to remove from the list soon)? [Yes] or [No]"
    write-host "THINK CAREFULLY. THIS CANNOT BE UNDONE: " -nonewline -foregroundcolor red
    $theAnswer = read-host
    $null = $theAnswer.tolower()
    if($theAnswer -eq 'yes' -or $theAnswer -eq 'no')
    {
        $theAnswercontinue = $true
    }
    else
    {
        write-host "`nThat wasn't a 'Yes' or a 'No', so I'll ask again..."
    }
}

$theAnswercontinue = $false
if($theAnswer -eq 'yes')
{
    while($theAnswercontinue -eq $false)
    {
        write-host "`nI want to re-iterate, this process CANNOT be undone. If you are uncertain please reach out to your supervisor and double check their intentions." -foregroundcolor yellow
        while($theAnswercontinue -eq $false)
        {
            write-host "If you are certain of your choice please enter 'Proceed' now, if not please enter 'No': " -nonewline -foregroundcolor yellow
            $theAnswer = read-host
            $null = $theAnswer.tolower()
            if($theAnswer -eq 'proceed')
            {
                $theAnswercontinue = $true
            }
            elseif($theAnswer -eq 'no')
            {
                $theAnswercontinue = $true
            }
            else
            {
                write-host "`nThat wasn't 'Proceed' or 'No'. So I'll repeat...`n"
            }
        }
    }
}


###########################################################################################################################################################################################

#Deleting users/selecting users to be saved

$dontRemovelist = @()
$toBeremovedList = @()

foreach($individualPerson in $allOftheAbove)
{
    $toBeremovedList += , $individualPerson[0]
}

if($theAnswer -eq 'proceed')
{

    $theAnswercontinue = $false
    $dontDelete = "waste"
    write-host "`nIf there are any users you wish to keep that were on the list, please enter their DisplayName below."
    write-host "You will have the chance to enter more than one. If you wish to cancel the deletion please type 'Cancel' below."
    write-host "For a full list of the commands in this section please type 'Commands'." -foregroundcolor Green
    write-host "Once you are finished entering users to save from the to-be-deleted list please type 'Continue'. You may not return here after you enter 'Continue' so please think about every entry carefully.`n"
    while($theAnswercontinue -eq $false)
    {
        write-host "Please enter the DisplayName of the user you wish to exclude from the deletion: " -nonewline
        $dontDelete = read-host
        $null = $dontDelete.tolower()

        if($dontDelete -eq "cancel")
        {
            $theAnswer = "waste"
            $theAnswercontinue = $true
        }
        elseif($dontDelete -eq "" -or $dontDelete -eq " ")
        {
            write-host "Ouch! Please don't enter blank spaces they hurt me :(" -foregroundcolor red
        }
        elseif($dontDelete -eq "continue")
        {
            $theAnswer = "finished"
            $theAnswercontinue = $true
        }
        elseif($dontDelete -eq "commands")
        {
            write-host ""
            write-host -nonewline "1. "; write-host -nonewline "*DisplayNameofUser* " -foregroundcolor green; write-host ": Adds the user to the 'save from deletion list'."
            write-host -nonewline "2. "; write-host -nonewline "Who " -foregroundcolor green; write-host ": Displays the users in the 'save from deletion list'."
            write-host -nonewline "3. "; write-host -nonewline "Delete *DisplayNameofUser* " -foregroundcolor green; write-host ": Removes the user from the 'save from deletion' list."
            write-host -nonewline "4. "; write-host -nonewline "Continue " -foregroundcolor green; write-host " : Moves onto the deletion of every user who is not marked 'TRUE' in PassedAllChecks and those who are not in the 'save from deletion list'."
            write-host -nonewline "5. "; write-host -nonewline "Cancel " -foregroundcolor green; write-host ": Cancels the script, stopping it then and there."
            write-host -nonewline "6. "; write-host -nonewline "Commands" -foregroundcolor green; write-host ": Displays the commands currently listed."
            write-host ""

        }
        elseif($dontDelete -eq "who")
        {
            write-host "`nThe following individuals were selected by you and therefore won't be deleted..." -ForegroundColor green
            foreach($individualPerson in $dontRemovelist)
            {
                write-host $individualPerson
            }
            write-host "`n"
        }
        elseif($dontdelete.length -gt 6 -and $dontDelete.substring(0,6) -eq "delete")
        {
            $dontDelete = $dontDelete.substring(7)
            $dontDelete = get-azureaduser -searchstring "$dontDelete" | select-object displayname
            $pattern = "@{DisplayName=([A-z]* *[A-z]* *[A-z]*)}"
            if($dontDelete -match $pattern)
            {
                $dontDelete = $Matches[1]
                $dontRemovelistHolder = @()
                $dontRemovelistCurrent = $dontRemovelist
                foreach($individualPerson in $dontRemovelist)
                {
                    if($individualPerson -eq $dontDelete)
                    {

                    }
                    else
                    {
                        $dontRemovelistHolder = $dontRemovelistHolder += $individualPerson
                    }
                }
                $dontRemovelist = $dontRemovelistHolder
                if($dontRemovelist -eq $dontRemovelistCurrent)
                {
                    write-host "The user wasn't found in the 'save from deletion' list. Perhaps you typed the name wrong, if not, please try the 'who' command to see who you are saving." -ForegroundColor yellow
                }
                else
                {
                    write-host "Okay, they will be added to the 'to be deleted' list. Please use the 'who' command to see who is being saved from deletion." -ForegroundColor green    
                }

            }
            else
            {
                write-host "You may have mistyped the user's name. Please try the command again." -foregroundcolor yellow    
            }

        }
        else
        {
            $counter = 0
            $dontDelete = get-azureaduser -searchstring "$dontDelete" | select-object displayname
            $pattern = "@{DisplayName=([A-z]* *[A-z]* *[A-z]*)}"
            if($dontDelete -match $pattern)
            {
                $dontDelete = $Matches[1]

                foreach($individualPerson in $toBeremovedList)
                {
                    if($individualPerson -eq $dontDelete)
                    {
                        $foundThem = $true
                        break
                    }
                    else
                    {
                        $foundThem = $false
                    }  
                }
                if($foundThem -eq $true)
                {
                    $dontRemovelist += , $dontDelete
                    write-host "Okay, found them! They won't be deleted!"
                }
                else
                {
                    write-host "That name wasn't recognzed, perhaps you typed it incorrectly." -ForegroundColor yellow
                }
            }
            else
            {
                write-host "That name wasn't recognzed, perhaps you typed it incorrectly." -ForegroundColor yellow
            }
            $theAnswercontinue = $false
        }
    }

    $toBeremovedList = $toBeremovedList | where-object{$dontRemovelist -notcontains $_}     #Creates list that removes the users who shouldn't be deleted

}

#Getting ready to delete the users, giving the person inputting commands one last chance to cancel

if($theAnswer -eq 'finished')
{
    $timer = 10

    write-host "`n"
    while($timer -gt -1)
    {
        if($timer -ge 7)
        {
            write-host -nonewline "`rIf you wish to cancel you have "; write-host -nonewline -foregroundcolor green "$timer"; write-host -nonewline " seconds to press 'CTRL' + 'C' at the same time..."
        }
        elseif($timer -ge 4)
        {
            write-host -nonewline "`rIf you wish to cancel you have "; write-host -nonewline -foregroundcolor yellow "$timer"; write-host  -nonewline " seconds to press 'CTRL' + 'C' at the same time..."
        }
        else
        {
            write-host -nonewline "`rIf you wish to cancel you have "; write-host -nonewline -foregroundcolor red "$timer"; write-host  -nonewline " seconds to press 'CTRL' + 'C' at the same time..."
        }
        start-sleep -seconds 1
        $timer = $timer - 1
    }
    
    write-host "`nOkay, I'll start deleting the users listed now! Please make the changes requested on your CSV or wait at least 10 minutes and run the script again. `n"

    #Where the users are deleted
    $counter = 0
    write-host "The following individuals have been deleted (the alternating colors are solely for ease of reading):"
    foreach($terminatedUser in $toBeremovedList)
    {
        if($counter % 2 -eq 0)
        {
            write-host $terminatedUser -foregroundcolor yellow
        }
        else
        {
            write-host $terminatedUser 
        }
        get-azureaduser -searchstring "$terminatedUser" | remove-azureaduser
        $counter += 1
        write-progress -percentcomplete ($counter/($toBeremovedList.length)*100) -activity "Deleting Users Marked True in the Returned CSV" -status "Working..."
        
    }
    
    write-host -nonewline "`nAll "; write-host -nonewline  "$counter" -foregroundcolor green; write-host -nonewline " users have been deleted."
}
else    #At any point answer, "no" they don't want the users to be deleted
{
    write-host "`nNot a problem, if you wish for me to delete them all after manually checking the CSV please run the script again."
}

#Goodbye
write-host "The script is finished, you may now close the terminal. Have a great rest of your day!`n" -ForegroundColor green

<#
Notes:

To check the emails you need EXO V2 installed, check the link below for more info on how to install it...
https://docs.microsoft.com/en-us/powershell/exchange/exchange-online-powershell-v2?view=exchange-ps#install-and-maintain-the-exo-v2-module

https://docs.microsoft.com/en-us/microsoft-365/compliance/identify-a-hold-on-an-exchange-online-mailbox?view=o365-worldwide
- AccountEnable = false, then if country = terminated, then if litigationhold = true (maybe print three lists?)
- Need to check the ones with litigation hold
- Need to format the string output

https://www.ntweekly.com/2019/06/10/exchange-online-find-mailboxes-with-specific-domain/
https://docs.microsoft.com/en-us/powershell/exchange/connect-to-exchange-servers-using-remote-powershell?view=exchange-ps
https://social.technet.microsoft.com/Forums/en-US/eff078bc-d911-4afe-9f1e-2c84e1fa3389/getuser-only-returns-my-own-user-and-getmailbox-returns-nothing?forum=onlineservicesexchange
https://stackoverflow.com/questions/28839685/how-to-get-all-mailbox-details-using-get-mailbox-cmdlet

#>