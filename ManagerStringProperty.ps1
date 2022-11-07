#https://learn.microsoft.com/en-us/powershell/azure/active-directory/using-extension-attributes-sample?view=azureadps-2.0
#https://learn.microsoft.com/en-us/powershell/module/microsoft.graph.directoryobjects/get-mgdirectoryobject?view=graph-powershell-1.0
#https://learn.microsoft.com/en-us/powershell/module/microsoft.graph.users/get-mguser?view=graph-powershell-1.0

<#Three steps to creating an extension property
    1. Create an application
    2. Create a service principal
    3. Create the extension property
#>

if($null -eq (get-azureadapplication -SearchString "managerString").ObjectId)   #Checks to see if the app exists (if so, assumes so is the rest and doesn't recreate)
{
    $NewApp = (New-AzureADApplication -DisplayName "managerString").ObjectId    #Builds app and collects the object ID for later
    New-AzureADServicePrincipal -AppId (get-azureadapplication -SearchString "managerString").AppId     #Builds the service principal
    New-AzureADApplicationExtensionProperty -ObjectId $NewApp -Name "managerLNameString" -DataType "String" -TargetObjects "User"   #Builds the extension property with the object ID
}

#https://www.reddit.com/r/PowerShell/comments/sc70f5/help_with_getmguser_graph_sdk/
$Users = Get-MgUser -ExpandProperty Manager  | select-object ID,@{Name = 'Manager'; Expression = {$_.Manager.AdditionalProperties.displayName}}
#The hash table is required at the end to acquire the manager's display name otherwise only an object is referenced
#The above takes users' IDs and Manager names to add as a new extension property

$Users | ForEach-Object {Set-AzureADUserExtension -ExtensionName (get-azureadmsapplicationextensionproperty -objectid `
    (get-azureadapplication -searchstring "managerString").objectid).Name -ExtensionValue $_.Manager -objectId $_.id}
#^ adds the extension to users (Uses FULL MANAGER NAME so regex only needs to be changed in the mapping, not re-built here)
#I feel comfortable referencing the extension by name because the name consists of some 20+ (seemingly/ possibly) random characters

<#
+ If you want to retry this you need to remove (in this order)...
    - The group...
        + remove-azureadmsgroup -id (get-azureadmsgroup -searchstring "Employees_Hired_After_20XX").Id
    - The service principal...
        + remove-azureadserviceprincipal -objectid (get-azureadserviceprincipal -searchstring "Grouping").objectid
    - The application...
        + remove-azureadapplication -objectid (get-azureadapplication -searchstring "Grouping").objectid
    - Then run the script below. If you receive only an error you can re-run this script to re-build the group, application, custom extension, add the custom extension 
        to applicable users, etc.
        + get-azureadapplication -searchstring "manager"
            get-azureadserviceprincipal -searchstring "manager"
            (get-azureadmsapplicationextensionproperty -objectid (get-azureadapplication -searchstring "managerString").objectid).Name

What the regex looks like
[A-z]*.*[A-z]* *[A-z]+ +([A-z]*-*[A-z]*)    <--- selects the last name
[A-z]*.*[A-z]* *[A-z]+ +    <--- selects everything but the last name (What was used since I'm "replacing" it all with a "")

What it was tested on...
First Middle Last
Jr. First Middle Last
First Last
Jr. First Last
Fi-rst La-st
Jr. Fi-rst La-st
Fi-rst Mid-dle La-st
Jr. Fi-rst Mid-dle La-st
First Mid-dle La-st
Jr. First Mid-dle La-st
Fi-rst Middle La-st
Jr. Fi-rst Middle La-st
Use to test: https://regexr.com/3c0lf
#>