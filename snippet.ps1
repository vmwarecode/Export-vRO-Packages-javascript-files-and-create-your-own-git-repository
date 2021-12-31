<#
Original website: https://vra4u.com/2021/11/19/export-vro-packages-to-actions-configuration-elements-js-files-create-your-own-git-repository/
    Version 2.0
    Created by:
        - Jose Cavalheri
    Contributed by:
        - Michael Van de gaer
 
    Description:
    - Skip Workflows and Resource Elements 
    - Get all content from exported vRO package Elements folder
    - Run through each folder and read categories (Modules)
    - Run through each folder and read data (Action name, parameters and content)
    - Create a new file *.js with the correct syntax for javascript
    - Create new folders as Actions or Configuration Elements
    - Export Configuration Elements as Commented Parameters + add inputs& descriptions
    - Export to c:\uploadVRO folder    
 
#>
## Inputs: 
#Element Folder Path after package unziped
$ElementsFolder = $(Write-Host "Where is your unzipped vRO Package stored? (provide full path - e.g.: C:\vRA4U\com.vro.some.module\elements)-- " -NoNewLine -ForegroundColor yellow; Read-Host)
 
# Path to save all new Modules and Actions
$savePath = $(Write-Host "Where would you like to save all Modules and Actions? (provide full path) -- " -NoNewLine -ForegroundColor yellow; Read-Host)
 
#Ask if Script is being executed on a Mac (for forwards slash vs backslash in folders)
$defaultOSType = 'windows' 
if (!($osType = $(Write-Host "What is your OS Version? [windows|mac] - default: windows -- " -NoNewLine -ForegroundColor yellow; Read-Host))){$osType = $defaultOSType}
$osType = $osType.ToLower()
 
#Set Slash / BackSlash
$slash = "\"
if ($osType -eq 'mac'){$slash = "/"}
 
# Enter the folder path
cd $ElementsFolder
 
$dir = dir $ElementsFolder | ?{$_.PSISContainer}
foreach ($d in $dir){
    # Enter subfolder path
    cd $d
     
    ## Do Tasks copying from Element folder and formatting to javascript with Parameters commented/scripts to .js
 
    #Get the categories file to determine vRO Module
        Select-Xml -Path .\categories -XPath 'categories'
        [xml]$xmlElm = Get-Content -Path .\categories
        #this getthe action name
        $catNameFolder = $xmlElm.categories.category.name.'#cdata-section'
        $catNameFolder = $catNameFolder.ToLower()
        write-host "Module name: " $catNameFolder
 
        [xml]$xmlElm = Get-Content -Path .\info
        $elementType = $xmlElm.properties.entry.'#text'
         
        if ($elementType -contains "ConfigurationElement") {
 
            #Create module folder
 
            if ($catNameFolder.Count -eq 1){
                $newPath = ($savePath + $slash+'ConfigurationElements'+$slash + $catNameFolder)
            } else {
                $newPath = ($savePath + $slash+'ConfigurationElements'+$slash + $catNameFolder[0] + $slash + $catNameFolder)
            }
 
 
            if ($osType -eq 'mac'){
                #mkdir -p $savePath$slash'ConfigurationElements'$slash$catNameFolder[0]$slash$catNameFolder
                mkdir -p $newPath
            } else {
                #mkdir $savePath$slash'ConfigurationElements'$slash$catNameFolder[0]$slash$catNameFolder
                mkdir $newPath
            }
             
 
            #Get the data file to determine vRO Action
            [xml]$xmlElm = Get-Content -Path .\data
 
            #Get Name of Config Element
            $configElementName = $xmlElm.'config-element'.'display-name'.'#cdata-section'
            $configElementName = $configElementName+".js"
 
            #Get Attributes / Parameters of Configuration Element
            $descriptions = @($xmlElm.'config-element'.atts.att.description.'#cdata-section')
            $attributes = @($xmlElm.'config-element'.atts.att)
 
            $myArray = @()
 
            $index = 0
            forEach ($att1 in $attributes){
                $object = New-Object -TypeName psobject
                $object | Add-Member -MemberType NoteProperty -Name "Name" -Value $att1.name 
                $object | Add-Member -MemberType NoteProperty -Name "Type" -Value $att1.type 
                $object | Add-Member -MemberType NoteProperty -Name "Description" -Value $descriptions[$index]
 
                $myArray += $Object
                $index = $index + 1
            }
 
            # creating file javascript
            New-Item -Name  $configElementName -ItemType File
 
            # adding parameters as description
            echo "/*" >> $configElementName
            echo "@Auto Export Created by VRA4U.COM:" >> $configElementName
            echo "Attributes:" >> $configElementName
            echo $myArray >> $configElementName
            echo "*/" >> $configElementName
 
            # Copy to final upload location
            #mv $configElementName $savePath$slash'ConfigurationElements'$slash$catNameFolder$slash$configElementName
            mv $configElementName $newPath
 
        } elseif ($elementType -contains "ScriptModule") {
 
            ## if module contains space or more than 1 categorie  = It's a  workflow Folder or Configuration Element type 
             #Create module folder
             if ($osType -eq 'mac'){
                mkdir -p $savePath$slash'Actions'$slash$catNameFolder
             } else {
                mkdir $savePath$slash'Actions'$slash$catNameFolder
             }
              
 
             #Get the data file to determine vRO Action
             Select-Xml -Path .\data -XPath 'dunes-script-module/script'
             [xml]$xmlElm = Get-Content -Path .\data
 
             #this get the action name
             $actionName = $xmlElm.'dunes-script-module'.name
             $actionName = $actionName+".js"
 
             # This returns all parameters
             $actionParams = $xmlElm.'dunes-script-module'.param
 
             #This return all script part
             $actionScript = $xmlElm.'dunes-script-module'.script.'#cdata-section'
 
             # creating file javascript
             New-Item -Name  $actionName -ItemType File
 
             # adding parameters as description
             echo "/*" >> $actionName
             echo "@Auto Export Created by VRA4U.COM:" >> $actionName
             echo "Input Parameters:" >> $actionName
             echo $actionParams >> $actionName
             echo "*/" >> $actionName
     
             # adding script content
             echo $actionScript >> $actionName
 
             # Copy to final upload location
             mv $actionName $savePath$slash'Actions'$slash$catNameFolder$slash$actionName
 
        }else{
            write-host "skipping Workflows & Resource Elements"
         
        }
 
    #Go back root level
    cd ..
 
}