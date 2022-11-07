<#
What is this script doing?:
    1. Checking if the group is created
        1.a. If it isn't it will build the placeholder application
        1.b. The service principal
        1.c. The extension property that will be added to the users of type BOOl (although it will only ever be True because False users won't be given the extension)
    2. Find the user ids if their CreatedDateTime is greater than January 1st of that year
    3. Give the users above the extension property
What do you need to know about it?:
    Dynamic Groups work in a way such that, when created they are always checking their parameters, so any user created after 1,1,XXXX will be given
    the extension property marked as True that, when checked by the dynamic group, will add them almost as soon as they're given the extension.
    CreatedDateTime is not a measure in the GUI version of group creation, given this method.
    Dates measurements measure the number of days (perhaps in UNIX seconds) the date the user is created and the date above which changes every year from XXXX,1,1 to XXXX+1,1,1.
    Becuase UNIX seconds start on 1970,1,1 and XXXX,2,1 is further away than XXXX,1,1 this is measured as greater than or -GE.
#>

#Creating the Extension Property
if($null -eq (get-azureadapplication -searchstring "Grouping_Based_On_Creation_Date").objectid)
{   #Checks if the application exists; if not the below recreates the app, the service prinicipal, and the custom extension property over again

    $DateTimeGrouping = (new-azureadapplication -DisplayName "Grouping_Based_On_Creation_Date").ObjectId
        #Creating a placeholder application
    new-azureadserviceprincipal -appid (get-azureadapplication -searchstring "Grouping_Based_On_Creation_Date").AppId
        #Creating a service principal
    New-AzureADMSApplicationExtensionProperty -objectid $DateTimeGrouping -name "DateTimeGrouping" -DataType "Boolean" -TargetObjects "User"
        #Creating the extension property itself
}

#Finding users with a creation date greater than XXXX,1,1
$Users = get-mguser -select Id,createdDateTime | where-object -property createdDateTime -GE ([Datetime]::new(2022,1,1))
    #Finding users so long as their creation date was created after XXXX,1,1 (Year, Month, Day) which should be true for everyone created after the script runs once
$Users | ForEach-Object {Set-AzureADUserExtension -ExtensionName (get-azureadmsapplicationextensionproperty -objectid `
    (get-azureadapplication -searchstring "Grouping_Based_On_Creation_Date").objectid).Name -ExtensionValue true -objectId $_.id}
    #Adding the extension property to each user for which the above in script line is TRUE


#Creating a dynamic group
if($null -eq (get-azureadmsgroup -searchstring "Employees_Hired_After_20XX").Id)
{   #Checks to see if the group exists, if not it is created below
    $ExtensionPropertyName = (get-azureadmsapplicationextensionproperty -objectid (get-azureadapplication -searchstring "Grouping_Based_On_Creation_Date").objectid).Name
    #Acquires the name of the extensionproperty to put into the membership rule

    new-azureadmsgroup -DisplayName "Employees_Hired_After_20XX" `
    -Description "Groups people based on their account creation date to easily manage who receives new layouts and who doesn't." `
    -MailEnabled $False `
    -MailNickName "EmployeesHiredAfter20XX" `
    -SecurityEnabled $True `
    -GroupTypes "DynamicMembership" `
    -MembershipRule "(user.$ExtensionPropertyName -eq true)" `
    -MembershipRuleProcessingState "On"
    #Builds the Dynamic Group, " ` " splits what would have been one line into many for readability
}

<#
Guide used: https://learn.microsoft.com/en-us/answers/questions/942942/how-to-create-a-dynamic-group-based-upon-date-the.html

Some minor changes were made based on the information received from...
+ Creating apps, service principals, and the extension property: 
    - https://learn.microsoft.com/en-us/powershell/azure/active-directory/using-extension-attributes-sample?view=azureadps-2.0
+ As of writing MGGraph docs are slim so this proved invaluable in teaching how the search function works, since select (or properties) must be specified twice
    - https://github.com/microsoftgraph/msgraph-sdk-powershell/issues/1377
    - Ex.: get-mguser -userid XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX -select DisplayName,createdDateTime | select DisplayName,createdDateTime
+ Creating the Dynamic Group in powershell:
    - https://stackoverflow.com/questions/62030759/how-to-create-dynamic-groups-in-azure-ad-through-powershell
    - https://helloitsliam.com/2021/01/25/note-to-self-powershell-create-dynamic-azure-ad-group/

Adding (info, perhaps for reference later)...
+ write-host($Users | Format-Table | Out-String)
    - Will output the users that have a CreatedDateTime greater than the listed year
+ Rebuilding the extension would be best done with removing the app, service principal, and extension property from last created to first
+ When using MGGrah try not to forget sometimes you need to add a consitency level
    -Ex.: get-mguser -ConsistencyLevel eventual -search '"DisplayName:NameyTheName"'
+ Tool to help figure out the intricacies of MGGraph
    - https://developer.microsoft.com/en-us/graph/graph-explorer
+ If you want to retry this you need to remove (in this order)...
    - The group...
        + remove-azureadmsgroup -id (get-azureadmsgroup -searchstring "Employees_Hired_After_20XX").Id
    - The service principal...
        + remove-azureadserviceprincipal -objectid (get-azureadserviceprincipal -searchstring "Grouping").objectid
    - The application...
        + remove-azureadapplication -objectid (get-azureadapplication -searchstring "Grouping").objectid
    - Then run the script below. If you receive only an error you can re-run this script to re-build the group, application, custom extension, add the custom extension 
        to applicable users, etc.
        + get-azureadapplication -searchstring "Grouping"
            get-azureadserviceprincipal -searchstring "grouping"
            (get-azureadmsapplicationextensionproperty -objectid (get-azureadapplication -searchstring "Grouping_Based_On_Creation_Date").objectid).Name
#> 