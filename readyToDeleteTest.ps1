write-host "`nAll the users displayed have credentials blocked, the checks include..."
write-host "Country field reads 'Terminated', litigation hold is 'TRUE', length of litigation hold is 'UNLIMITED', and E3 license is 'FALSE'"

$allTheabove = @("User's", "Display", "Name", "Will", "Appear", "Here","Unless","There","Are","More","Than","Twenty","Marked","TRUE","In","PassedAllChecks")

#Asking the user if they wish for the listed users to be deleted
if($allTheabove.length -le 20 )
{
    write-host "`nThe users who passed all these checks, and can be deleted are..."
    foreach($checkedUser in $allTheabove)
    {
        write-host $checkedUser
    }
}
else
{
    write-host "`nThere are more than 20 people that passed all the checks, please look at them in the CSV and return here."
}

#Deleting users
$theAnswercontinue = $false
while($theAnswercontinue -eq $false)
{
    write-host "`nDo you want me to delete these users now? [Yes] or [No]"
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
            write-host "If you are certain of your choice to delete these users please enter 'Proceed' now, if not please enter 'No': " -nonewline -foregroundcolor yellow
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


$timer = 10
if($theAnswer -eq 'proceed')
{
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
    write-host "`nOkay, I'll start deleting the users listed now!`n"

    <#Where the users would be deleted
    foreach($terminatedUser in $allOftheAbove)
    {
        write-host $terminatedUser
    }
    #>
    
    write-host "`nAll of the users have been deleted."
}
else
{
    write-host "`nNot a problem, if you wish for me to delete them all after manually checking the CSV please run the script again."
}
write-host "The script is finished, you may now close the terminal. Have a great rest of your day!`n"