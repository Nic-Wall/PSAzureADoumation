#Convenience of user and tester declaration
$timerTolimit = 0 #use to run tests over a small number of employees just input "if($timerTolimit -eq number-you-want-to-end-on){break}" before $timerTolimit += 1

#Scipt necessary declarations
$cityList = @()
$masterList = @()

write-host "`nNOTE: If you receive an error you must call 'connect-msolservice', 'connect-azuread', and sign into both before re-running this script!" -Foregroundcolor Yellow
write-host "`If you receive an error attempting to call these commands, follow the steps from this link:" -Foregroundcolor Yellow
write-host "https://docs.microsoft.com/en-us/microsoft-365/enterprise/connect-to-microsoft-365-powershell?view=o365-worldwide" -Foregroundcolor darkblue -backgroundcolor darkgray
write-host "Or check the Zendesk article 'Manager Audit'. " -foregroundcolor Yellow
write-host "`nPulling each employee from Admin Center with an Office 365, or 'enterprisepack', license. This won't take much time..."

$null = $userWithlicenseList = get-msoluser -all | where-object {($_.licenses.accountskuid -match "enterprisepack")}
$totalNumberofUsers = $userWithlicenseList.count

write-host "`nThere are currently $totalNumberofUsers users with an Office 365 License."
write-host "Recording each user, their manager, and the city in which they work. This step usually takes the most time..."

#Script that runs through each user, finds their manager and city and puts them into a dictionary, then list, then another list (also creates lists if necessary)
foreach ($user in $userWithlicenseList)
{
	#Re/Declaring variables used to keep track of things
    $holdingList = @() #For why I declare it here instead of using .clear() see this forum https://stackoverflow.com/questions/13296031/powershell-array-is-not-cleared
    $myCounter = 0    #Refreshers counter

    #Aquiring the users city, name, and manager
	$cityHolder = ($user).city	#Grabs city
	$theUsersdisplayName = ($user).displayname	#Users display name
	$theManagersdisplayName = (get-azureaduser -searchstring $theUsersdisplayName | get-azureadusermanager).displayname	#Managers display name
	
    if($null -eq $theManagersdisplayName){$theManagersdisplayName = " "}    #Prevents manager name from being null (causes issues when converting to CSV)

	if($null -eq $cityHolder){}		#ignores users without a city
    else
    {
        if($cityList.length -eq 0)  #Checks to see if the first cityList variable has been added. If not it's added here, presumably with the first user also being added to the masterList
        {
            $cityList += , $cityHolder
            $holdingList = @([pscustomobject]@{usersName = "$cityHolder"; managersName = "  "}, [pscustomobject]@{usersName = "$theUsersdisplayName"; managersName = "$theManagersdisplayName"})
            #I have to make each of these a pscustomobject or else it returns "#TYPE System.Collections.Hashtable" and then the count, readonly, fixedsize, etc. of the hashtable
            $masterList += , $holdingList
        }
        else
        {
            $checker = $true    #Using a checker, otherwise the first user to have their own city, after the first, would cause a never ending loop and an ever increasing $cityList
            foreach($city in $cityList)
            {
                if($cityHolder -eq $city)   #returns True to checker, which is used below
                {
                    $checker = $true
                    break
                }
                else    #returns False to checker and adds one to the $myCounter so the correct city can be accessed from the $masterList and $cityList below
                {
                    $checker = $false
                    $myCounter += 1
                }
            }
            if($checker -eq $true) #if a user's city already exists in #cityList for the user is sent here to be added to the position in the $masterList that coincides with their city in $cityList
            {
                $holdingList = @([pscustomobject]@{usersName = "$theusersdisplayName"; managersName = "$theManagersdisplayName"})
                $masterList[$myCounter] += $holdingList
            }
            else    #In the same way for the first user, this creates a new city in the $cityList and adds the cityName and user/manager to the holding list so it can added to the correct positon in the $masterList
            {
                $cityList += , $cityHolder
                $holdingList = @([pscustomobject]@{usersName = "$cityHolder"; managersName = "  "}, [pscustomobject]@{usersName = "$theUsersdisplayName"; managersName = "$theManagersdisplayName"})
                $masterList += , $holdingList
            }
        }
    }
    
    write-progress -percentcomplete ($timerTolimit/$totalNumberofUsers*100) -activity "Finding Users, their Manager, and sorting by City" -status "In Progress..."
    $timerTolimit += 1

}

write-host "`nFinished recording.`nArranging results into the CSV format..."

$myCounter = 0 #clearing the counter to access the correct list in $masterList

#This takes each city from the $citylist and it's associate in the $masterList cleans up their format to the csv and adds it to the sheet
foreach($city in $cityList)
{
    $holdingList = @() #clearing the $holdingList so...
    $holdingList = $masterList[$myCounter]  #$holdingList can hold the cities list of dictionaries and conver them into CSV format

    if($myCounter -eq 0)
    {
        $holdingList | convertTo-csv -NoTypeInformation | foreach-object {$_ -replace '"',''} | out-file -filepath ".\managerAuditresults.csv" -encoding UTF8
    }
    else
    {
        $holdingList | convertTo-csv -NoTypeInformation | foreach-object {$_ -replace '"',''} | foreach-object {$_ -replace 'usersName',' '} | foreach-object {$_ -replace 'managersName'," "} | out-file -filepath ".\managerAuditresults.csv" -append -encoding UTF8
    }
    $myCounter += 1
}
write-host "`nFinished! `nPlease check your current directory for a CSV titled: " -NoNewline; write-host "managerAuditresults.csv " -ForegroundColor DarkGreen
write-host "Have a good rest of your day!`n`n"

<# 
How variables are organized
    + $cityList contains only a list of the cities
    + $masterList contains list of the users in each city
        - these lists contain a list of dictionaries starting with the city name and a blank space and then each users and their manager

Things to work on
    + alphabetizing the cities
    + alphabetizing the users in each city
    + if cities get big enough putting them in a sheet of their own (probably need to know convertto-xls for that :/ )
#>