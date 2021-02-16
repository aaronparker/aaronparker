<#
    .SYNOPSIS
        Public Pester function tests.
#>
[OutputType()]
Param()

# Set variables
If (Test-Path "env:APPVEYOR_BUILD_FOLDER") {
    # AppVeyor Testing
    $projectRoot = Resolve-Path -Path $env:APPVEYOR_BUILD_FOLDER
    $module = $env:Module
}
Else {
    # Local Testing 
    $projectRoot = Resolve-Path -Path (((Get-Item (Split-Path -Parent -Path $MyInvocation.MyCommand.Definition)).Parent).FullName)
    $module = Split-Path -Path $projectRoot -Leaf
}
$moduleParent = Join-Path -Path $projectRoot -ChildPath $module
$manifestPath = Join-Path -Path $moduleParent -ChildPath "$module.psd1"

# Import module
Write-Host ""
Write-Host "Importing module." -ForegroundColor Cyan
Import-Module $manifestPath -Force

# Create download path
$Path = Join-Path -Path $env:Temp -ChildPath "Downloads"
New-Item -Path $Path -ItemType Directory -Force -ErrorAction SilentlyContinue

Describe -Tag "AppVeyor" -Name "Test" {

    $commands = Get-Command -Module Evergreen
    ForEach ($command in $commands) {

        Context "Validate $($command.Name)" {
            # Run each command and capture output in a variable
            New-Variable -Name "tempOutput" -Value (. $command.Name )
            $Output = (Get-Variable -Name "tempOutput").Value
            Remove-Variable -Name tempOutput
            
            # Test that the function returns something
            It "$($command.Name): Fuction returns something" {
                ($Output | Measure-Object).Count | Should -BeGreaterThan 0
            }

            # Test that the function output matches OutputType in the function
            It "$($command.Name): Function returns the expected output type" {
                $Output | Should -BeOfType ((Get-Command -Name $command.Name).OutputType.Type.Name)
            }
        }
    }
}
