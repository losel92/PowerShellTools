<# # #
#
# This script will create an OU with 2 DL groups.
# One for RX and one for M. Also creates a global
# group and links to the DLs. It will add a user
# to the global group. Additionally, it will create
# a folder with the appropriate permissions
#
# # #>

Write-Host "Create new Group"

$group_name = Read-Host "Name"
$group_desc = Read-Host "Description"

$domain = (Get-ADDomain).NetBIOSName
$domain_string = (Get-ADDomain).DistinguishedName

$OU_Path = ("OU=$group_name,OU=firm," + $domain_string)

# Check if OU Exists
if ((Get-ADOrganizationalUnit -Filter "Name -like '$group_name'")) {
    Write-Output "An Organizational unit with the name '$group_name' already exists..."
    Exit 1
}

# Create OU
New-ADOrganizationalUnit `
 -Name "$group_name" `
 -Path ("OU=firm," + $domain_string) `
 -ProtectedFromAccidentalDeletion $False

 
# Create Modify group
New-ADGroup -Name ("DL-$group_name-M") `
 -GroupCategory Security -GroupScope DomainLocal -DisplayName  `
 ($group_name + " - Modify") -Path $OU_Path -Description $group_desc
 
# Create Read & Execute group
New-ADGroup -Name ("DL-$group_name-RX") `
 -GroupCategory Security -GroupScope DomainLocal -DisplayName  `
 ("$group_name - Read & Execute") -Path $OU_Path -Description $group_desc
 
# Create global group
New-ADGroup -Name "G-$group_name" `
  -GroupCategory Security `
  -GroupScope Global `
  -DisplayName ("$group_name - Global") `
  -Path "$OU_Path" `
  -Description "$group_desc"

# Add Global to both DLs
Add-ADGroupMember -Identity "DL-$group_name-M" -Members "G-$group_name"
Add-ADGroupMember -Identity "DL-$group_name-RX" -Members "G-$group_name"

# Create user and link to global group M
New-ADUser -Name ("USR-$group_name") -Path $OU_Path
Add-ADGroupMember -Identity ("G-$group_name") -Members ("USR-$group_name")
 
 
# Create folder if it doesn't exist
if ((Test-Path "D:\Firm\$group_name")) { # Folder exists, permissions not set
    Write-Output "A folder with the name '$group_name' already exists under 'Firm'. Folder permissions were not set."
}
else {
    mkdir "D:\Firm\$group_name"

    # Config permissions
    icacls "D:\Firm\$group_name" /grant $domain\DL-$group_name-M:`(OI`)`(CI`)M
    icacls "D:\Firm\$group_name" /grant $domain\DL-$group_name-RX:`(OI`)`(CI`)RX

    Write-Output "Script ran successfully!"
}