#Function(s)
function test-SAInstall    #If Support Assist does not exist, this script installs and launches it for the user
{
    $user = get-childitem -path "C:\Users\" -Name       #Pulling list of users to find the downloads path
    foreach($item in $user)
    {
        if($item -eq "defaultuser0" -or $item -eq "Public" -or $item -eq "defaultuser") #Going through the three others that may or may not be present with the user
        {
            continue
        }
        else
        {
            $user = $item   #Taking the users name to add to the path
            break
        }
    }
    $url = "downloads.dell.com/serviceability/catalog/SupportAssistInstaller.exe"   #Download link
    $todayIs = get-date -format "dd_MM_yyyy"                                        #Today's date, to append to the path
    $OutPath = "C:\Users\$user\Downloads\Dell_SAI_$todayIs.exe"                     #Where I want the download to go, or "the path"

    #Invoke-Webrequest Attempt
    try
    {
        invoke-webrequest -URI $URL -OutFile $OutPath -UseBasicParsing      #Downloading the SupportAssist.exe
    }
    catch
    {
        write-host("Failed to find download link or organize the Path to send the executable. You'll have to install SupportAssist manually.")
    }

    #Starting the Executable installed from the Web-Request
    start-sleep -seconds 2
    Start-Process -Filepath $OutPath -Verb RunAs    #Start the executable as an admin
    #https://stackoverflow.com/questions/14071012/how-do-i-automatically-answer-yes-to-a-prompt-in-powershell
}





#Main Script
function test-ToSaveOutput
{
#Sets the UAC (User Account Control) to 0. This allows the script to uninsall packages without being stopped by pop-ups/confirmations
set-ItemProperty -Path REGISTRY::HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Policies\System -Name ConsentPromptBehaviorAdmin -Value 0

#Removing apps with their MSI removal string
#$UninstallStrApps = @(get-itemproperty "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*" | where-object {$_.DisplayName -like "*dell*" -and $_.DisplayName -notlike "*dell*supportassist*"})
$UninstallStrApps = @(get-itemproperty "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*" | where-object {$_.DisplayName -like "*dell*remediation*"})
#^ Finding all apps that have an uninstall string and contain Dell in their display name
foreach($EP in $UninstallStrApps)
{
    try
    {
        $UninstallEXE = $EP.QuietUninstallString
    }
    catch
    {
        $UninstallEXE = $EP.UninstallString
    }
    $isEXEOnly = test-path -literalpath $UninstallEXE   #Tests the path of the uninstallstring, if it's not a literal path (because of switches at the end)...
    if($isEXEOnly)                                      #This if statement removes the switches
    {
        $UninstallEXE = "`"$uninstallEXE`""
    }
    & "C:\Windows\SYSTEM32\cmd.exe" /c $uninstallEXE        #Runs the uninstall string
    #could also do start-process but you'd have to seperate the switches and the string and it's easier to just add ' " '
}
#https://stackoverflow.com/questions/66771008/appending-switch-to-a-custom-uninstaller

#Uninstalling packages
$XOrNot = @("get-package", "get-appxpackage")
foreach($Cmdlet in $XOrNot)
{
    #$PackagesToRemove = & $Cmdlet | where-object {$_.name -like "*dell*" -and $_.name -notlike "*Dell*SupportAssist*" -and $_.name -notlike "*dell*-*"}
    $PackagesToRemove = & $Cmdlet | where-object {$_.name -like "*dell*remediation*"}
    #^ Gets packages to remove that don't contain "-"(since they're likely drivers) or "SupportAssist"
    if($null -eq $PackagesToRemove) #Doesn't attempt to uninstall anything if there's nothing to uninstall
    {
        continue
    }
    else
    {
        if($Cmdlet -eq "get-package")
        {
            foreach($IndPackage in $PackagesToRemove)
            {
                uninstall-package -name $IndPackage.name -confirm:$False -force
            }
        }
        elseif($Cmdlet -eq "get-appxpackage")
        {
            foreach($IndPackage in $PackagesToRemove)
            {
                Remove-AppxPackage -package $IndPackage.PackageFullName -confirm:$False -force
            }
        }
    }
}
#Installing SupportAssist if it doesn't exist
if($null -eq ((get-package).name | where-object {$_ -ceq "Dell SupportAssist"}))    #If SupportAssist isn't installed it will attempt to install it from the function above
{
    test-SAInstall
}
else{continue}

#Resetting the UAC for safety reasons
set-ItemProperty -Path REGISTRY::HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Policies\System -Name ConsentPromptBehaviorAdmin -Value 5
}

<#Runs the mainscript without creating a log
test-ToSaveOutput
#>

#Creates a log to document console outputs, especially useful if errors occur
#All of this below is simply for logging purposes
$theuser = get-childitem -path "C:\Users\" -Name
foreach($theitem in $theuser)
{
    if($theitem -eq "defaultuser0" -or $theitem -eq "Public" -or $theitem -eq "defaultuser") 
    {
        continue
    }
    else
    {
        $theuser = $theitem
        break
    }
}
$DateTime = get-date -format "HH_mm"
$outfile = "C:\Users\$theuser\Downloads\DBWR$DateTime.txt"
test-ToSaveOutput | out-file -filepath $outfile


<#Notes
+ Removing Apps with PowerShell
    - https://learn.microsoft.com/en-us/answers/questions/883028/need-help-unable-to-uninstall-app-through-powershe.html
+ Creating MSI files
    - https://www.dell.com/support/kbdoc/en-us/000177292/how-to-create-a-dell-command-update-msi-installer-package
+ Changing UAC
    - https://stackoverflow.com/questions/44409006/disabling-uac-with-powershell
    - https://learn.microsoft.com/en-us/openspecs/windows_protocols/ms-gpsb/341747f5-6b5d-4d30-85fc-fa1cc04038d4
+ Purpose of confirm and force switches
    - https://learn.microsoft.com/en-us/exchange/whatif-confirm-and-validateonly-switches-exchange-2013-help
    - https://devblogs.microsoft.com/scripting/powertip-use-the-force-switch-in-powershell/
#>