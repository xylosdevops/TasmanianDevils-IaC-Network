#Requires -Modules Pester
<#
.SYNOPSIS
    Tests a specific ARM template
.EXAMPLE
    Invoke-Pester 
.NOTES
    This file has been created as an example of using Pester to evaluate ARM templates
#>

$scriptPath = "$env:BUILD_SOURCESDIRECTORY\Common\Network"
$templateFileName = "Xylos-Common-Network.json"
$templateFileLocation = "$scriptPath\$templateFileName"
$templateMetadataFileName = "metadata.json"
$templateMetadataFileLocation = "$scriptPath\$templateMetadataFileName"
$templatePrdParameterFileName = "Xylos-Common-Network.prd.parameters.json"
$templatePrdParemeterFileLocation = "$scriptPath\$templatePrdParameterFileName" 
$templateAccParameterFileName = "Xylos-Common-Network.acc.parameters.json"
$templateAccParemeterFileLocation = "$scriptPath\$templateAccParameterFileName" 
$templateTstParameterFileName = "Xylos-Common-Network.tst.parameters.json"
$templateTstParemeterFileLocation = "$scriptPath\$templateTstParameterFileName" 
$templateDevParameterFileName = "Xylos-Common-Network.dev.parameters.json"
$templateDevParemeterFileLocation = "$scriptPath\$templateDevParameterFileName" 


Describe 'ARM Templates Test : Validation & Test Deployment' {
    
    Context 'Template Validation' {
        
        It 'Has a JSON template' {        
            $templateFileLocation | Should Exist
        }
        
        It 'Has a production parameters file' {        
            $templatePrdParemeterFileLocation | Should Exist
        }
		
        It 'Has a acceptance parameters file' {        
            $templateAccParemeterFileLocation | Should Exist
        }

        It 'Has a test parameters file' {        
            $templateTstParemeterFileLocation | Should Exist
        }

        It 'Has a development parameters file' {        
            $templateDevParemeterFileLocation | Should Exist
        }
        
        It 'Has a metadata file' {        
            $templateMetadataFileLocation | Should Exist
        }

        It 'Converts from JSON and has the expected properties' {
            $expectedProperties = '$schema',
                                  'contentVersion',
                                  'parameters',
                                  'variables',
                                  'resources',                                
                                  'outputs'
            $templateProperties = (get-content $templateFileLocation | ConvertFrom-Json -ErrorAction SilentlyContinue) | Get-Member -MemberType NoteProperty | % Name
            $templateProperties | Should Be $expectedProperties
        }
        
        It 'Creates the expected Azure resources' {
            $expectedResources = 'Microsoft.Network/virtualNetworks',
                                 'Microsoft.Network/virtualNetworks/subnets'
            $templateResources = (get-content $templateFileLocation | ConvertFrom-Json -ErrorAction SilentlyContinue).Resources.type
            $templateResources | Should Be $expectedResources
        }
        
        It 'Contains the expected parameters' {
            $expectedTemplateParameters = 'vnetName',
                                          'vnetLocation',
                                          'vnetPrefix',
                                          'virtualNetworkDns01',
                                          'virtualNetworkDns02',
                                          'subnetCount',
                                          'subnetMask'
            $templateParameters = (get-content $templateFileLocation | ConvertFrom-Json -ErrorAction SilentlyContinue).Parameters | Get-Member -MemberType NoteProperty | % Name
            $templateParameters | Should Be $expectedTemplateParameters
        }

    }


    Context 'Template Test Deployment' {

        # Basic Variables
        $testsRandom = Get-Random 10001
        $testsResourceGroupName = "tests-tplval-xylosnetwork-$testsRandom"
        $testsResourceGroupLocation = "West Europe"

        # List of all scripts + parameter files
        $testsTemplateList=@()
        ## dummy parameter file to test default parameters
        $testsTemplateList += ,@("Xylos-Common-Network.json","Xylos-Common-Network.parameters.json")
        $testsTemplateList += ,@("Xylos-Common-Network.json","Xylos-Common-Network.prd.parameters.json")
		$testsTemplateList += ,@("Xylos-Common-Network.json","Xylos-Common-Network.acc.parameters.json")
        $testsTemplateList += ,@("Xylos-Common-Network.json","Xylos-Common-Network.tst.parameters.json")
        $testsTemplateList += ,@("Xylos-Common-Network.json","Xylos-Common-Network.dev.parameters.json")

        # Set working directory & create resource group
        Set-Location $scriptPath
        New-AzureRmResourceGroup -Name $testsResourceGroupName -Location "$testsResourceGroupLocation"

        # Validate all ARM templates one by one
        $testsErrorFound = $false
        foreach ($template in $testsTemplateList.GetEnumerator()) {
            $testsTemplateFile = $template[0]
            $testsTemplateParemeterFile = $template[1]
            It "Test Deployment of ARM template $testsTemplateFile with parameter file $testsTemplateParemeterFile" {
                (Test-AzureRmResourceGroupDeployment -ResourceGroupName $testsResourceGroupName -TemplateFile $testsTemplateFile -TemplateParameterFile $testsTemplateParemeterFile).Count | Should not BeGreaterThan 0
            }
        }
        Remove-AzureRmResourceGroup -Name $testsResourceGroupName -Force

    }

}