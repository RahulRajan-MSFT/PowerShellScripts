################# Azure AD PIM Role assignment Export ############################
##################################################################################


function get-outputfilename{
 
[cmdletbinding()]
param([parameter(Mandatory=$true,Position=1,HelpMessage="Please enter folder Name to which data should be exported")][string]$foldername)
 
process{
$date=get-date
$time=$date.ToLongTimeString()
$time=$time.Replace(" ","-")
$time=$time.Replace(":","-")
$day=$date.ToShortDateString()
$day=$day.replace("/","-")
$tocheck="$($env:homedrive)$($env:homepath)\documents"
set-location $tocheck
try{
Get-Item $foldername -ErrorAction Stop
}
catch{
New-Item -ItemType Directory -Name $foldername | Out-Null
}
$finalpath="$($tocheck)\$($foldername)\"
$filenameprefix="$($tocheck)\$($foldername)\$($foldername)-$($day)day-$($time)time"
Write-Host "Logs are writtern to $finalpath" -ForegroundColor Green
return $finalpath,$filenameprefix
}
}
$path=get-outputfilename -foldername PIMAssignmentstate

$roleassignmentPIM=Get-AzureADMSPrivilegedRoleAssignment -ProviderId aadroles -ResourceId (Get-AzureADTenantDetail).objectid
$tenantid=(Get-AzureADTenantDetail).objectid.tostring()
$finaloutput=@()
$start=0
$remaining=0
foreach($entry in $roleassignmentPIM)
{
    $user=Get-AzureADUser -ObjectId $entry.SubjectId
    $roledefinationid=Get-AzureADMSPrivilegedRoleDefinition -ProviderId aadroles -ResourceId $tenantid -id $entry.RoleDefinitionId.ToString()
    $hashtableoutput=[ordered]@{
    ResourceId=$entry.ResourceId
    RoleDefinitionId=$entry.RoleDefinitionId
    RoleDefinitionIdName=$roledefinationid.DisplayName
    Subjectid=$entry.SubjectId
    UserUPN=$user.UserPrincipalName
    LinkedEligibleRoleAssignmentId=$entry.LinkedEligibleRoleAssignmentId
    StartDateTime=$entry.StartDateTime
    EndDateTime=$entry.EndDateTime
    AssignmentState=$entry.AssignmentState
    MemberType=$entry.MemberType
    }
    $output=New-Object -TypeName psobject -Property $hashtableoutput
    $finaloutput+=$output
    Clear-Variable -Name output
    $start++
    $remaining=$roleassignmentPIM.count - $start
    Write-host "Processed $start, remaining $remaining out of total $($roleassignmentPIM.count)" -ForegroundColor Yellow
}
cls
$finaloutput | more
if ($finaloutput)
{
    $filename="$($path[-1]).csv"
    $finaloutput | Export-Csv -Path $filename -NoClobber -NoTypeInformation
    Write-Host "Role assignment is exported to $($filename)" -ForegroundColor Green
}
else
{
    Write-Host "No PIM Role assignment found"
}
