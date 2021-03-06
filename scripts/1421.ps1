#BASEPATH variable should be explicitly set in every 
#build script. It represents the "root"
#of the project folder, underneath which all tools, source, config settings,
#and deployment folder lie.
$global:basepath = (resolve-path ..).path
function Set-BasePath([string]$path)
{
	$global:basepath = $path
}



function Clean-DeploymentFolder
{
	Clean-Path -dir (Get-FullPath 'deployment')
}

function Compile-Project
{
	Run-MSBuild -msBuildArgs @(
		((Get-FirstSolutionFile).Fullname), 
		"/target:Clean", 
		"/target:Build", 
		"/p:Configuration=Release")
}

function Create-DeploymentBatchFilesWithSolutionOnly
{
	#similar to Create-DeploymentBatchFilesWithFeatureActivation, but WITHOUT Feature activation/deactivation
	#Convention: project name == project folder name == Feature name == Solution name
	$projectName = (Get-FirstDirectoryUnderneathSrc).name

	Create-DeploymentBatchFile -filename (Get-FullPath "deployment\deploy-any-environment.bat") -solutionName "$($projectName).wsp"
	Create-UpgradeBatchFile -filename (Get-FullPath "deployment\upgrade-any-environment.bat") -solutionName "$($projectName).wsp"
	Create-RetractionBatchFile -filename (Get-FullPath "deployment\z-retract-any-environment.bat") -solutionName "$($projectName).wsp"
}

function Create-DeploymentBatchFilesWithFeatureActivation($siteUrls)
{
	#Convention: project name == project folder name == Feature name == Solution name
	$projectName = (Get-FirstDirectoryUnderneathSrc).name
	$siteUrls.Keys | foreach {
		Create-DeploymentBatchFile -url $siteUrls[$_] -filename (Get-FullPath "deployment\deploy-$($_).bat") -featureName $projectName -solutionName "$($projectName).wsp" -hasFeature
		Create-UpgradeBatchFile -url $siteUrls[$_] -filename (Get-FullPath "deployment\upgrade-$($_).bat") -featureName $projectName -solutionName "$($projectName).wsp" -hasFeature
		Create-RetractionBatchFile -url $siteUrls[$_] -filename (Get-FullPath "deployment\z-retract-$($_).bat") -featureName $projectName -solutionName "$($projectName).wsp" -hasFeature
	}
}

function Get-FirstDirectoryUnderneathSrc
{
	dir (Get-FullPath "src") | where { $_.PSIsContainer -eq $true } | select -first 1
}

function Get-FirstSolutionFile
{
	dir (Get-FullPath "\*") -include "*.sln" -recurse | select -first 1
}

#BASEPATH variable should be explicitly set in every 
#build script. It represents the "root"
#of the project folder, underneath which all tools, source, config settings,
#and deployment folder lie.
$global:basepath = (resolve-path ..).path
function Set-BasePath([string]$path)
{
	$global:basepath = $path
}

function Get-FullPath($localPath)
{
	return join-path -path $global:basepath -childPath $localPath
}

function Run-DosCommand($program, [string[]]$programArgs)
{
	write-host "Running command: $program";
	write-host " Args:"
	0..($programArgs.Count-1) | foreach { Write-Host " $($_+1): $($programArgs[$_])" }
	& $program $programArgs
}

$wspbuilder = Get-FullPath "tools\WSPBuilder.exe"
function Run-WspBuilder()
{
	$rootDirectory = (Get-FirstDirectoryUnderneathSrc).fullname
	pushd
	cd $rootDirectory
	Run-DosCommand -program $WSPBuilder -programArgs @("-BuildWSP", 
		"true", 
		"-OutputPath", 
		(Get-FullPath "deployment"), 
		"-ExcludePaths",
		([string]::Join(";", @( 
			(Join-Path -path $rootDirectory -childPath "bin\Debug"),
			(Join-Path -path $rootDirectory -childPath "bin\deploy") 
			))))
	popd
}

$msbuild = "C:\Windows\Microsoft.NET\Framework\v3.5\msbuild.exe"
function Run-MSBuild([string[]]$msBuildArgs)
{
	Run-DosCommand $msbuild $msBuildArgs
}

function Clean-Path($dir)
{
	#I don't like the SilentlyContinue option, but we need to ignore the case
	#where there is no directory to delete (in this situation, an error is thrown)
	del $dir -recurse -force -erroraction SilentlyContinue
	mkdir $dir -erroraction SilentlyContinue | out-null
}

function Create-DeploymentBatchFile($filename, $featureName, $solutionName, $url, [switch]$allcontenturls, [switch]$hasFeature)
{
	if ($hasFeature) {
		$contents = [string]::Join("`n", @(`
			(Emit-FeatureDeactivationBatchScript -featureName $featureName -url $url -allcontenturls:$allcontenturls), `
			(Emit-SolutionRetractionBatchScript -solutionName $solutionName -allcontenturls:$allcontenturls), `
			(Emit-SolutionDeploymentBatchScript -solutionName $solutionName -allcontenturls:$allcontenturls), `
			(Emit-FeatureActivationBatchScript -featureName $featureName -url $url -allcontenturls:$allcontenturls)))
	} else {
		$contents = [string]::Join("`n", @(`
			(Emit-SolutionRetractionBatchScript -solutionName $solutionName -allcontenturls:$allcontenturls), `
			(Emit-SolutionDeploymentBatchScript -solutionName $solutionName -allcontenturls:$allcontenturls)))
	}
		
	Create-StsadmBatchFile -filename $filename -contents $contents
}

function Create-UpgradeBatchFile($filename, $featureName, $solutionName, $url, [switch]$hasFeature)
{
	if ($hasFeature) {
		$contents = [string]::Join("`n", @(`
			(Emit-FeatureDeactivationBatchScript -featureName $featureName -url $url -allcontenturls:$allcontenturls), `
			(Emit-SolutionUpgradeBatchScript -solutionName $solutionName -allcontenturls:$allcontenturls), `
			(Emit-FeatureActivationBatchScript -featureName $featureName -url $url -allcontenturls:$allcontenturls)))
	} else {
		$contents = [string]::Join("`n", @(`
			(Emit-SolutionUpgradeBatchScript -solutionName $solutionName -allcontenturls:$allcontenturls)))
	}
	
	Create-StsadmBatchFile -filename $filename -contents $contents
}


function Create-RetractionBatchFile($filename, $featureName, $solutionName, $url, [switch]$allcontenturls, [switch]$hasFeature)
{
	if ($hasFeature) {
		$contents = [string]::Join("`n", @(`
			(Emit-EchoMessage -message "RETRACTING solution--press any key to continue, or CTRL+C to cancel"), `
			(Emit-FeatureDeactivationBatchScript -featureName $featureName -url $url -allcontenturls:$allcontenturls), `
			(Emit-SolutionRetractionBatchScript -solutionName $solutionName -allcontenturls:$allcontenturls)))
	} else {		 
		$contents = [string]::Join("`n", @(`
			(Emit-EchoMessage -message "RETRACTING solution--press any key to continue, or CTRL+C to cancel"), `
			(Emit-SolutionRetractionBatchScript -solutionName $solutionName -allcontenturls:$allcontenturls)))
	}
	
	Create-StsadmBatchFile -filename $filename -contents $contents
}

function Emit-EchoMessage($message)
{
	return "echo $($message)`npause"
}

function Emit-FeatureDeactivationBatchScript($featureName, $url, [switch]$allcontenturls)
{
	$script = @"
%STSADM% -o deactivatefeature -name $featureName -url $url
"@

	return $script	
}

function Emit-FeatureActivationBatchScript($featureName, $url, [switch]$allcontenturls)
{
	$script = @"
%STSADM% -o activatefeature -name $featureName -url $url
"@

	return $script	
}

function Emit-SolutionRetractionBatchScript($solutionName, [switch]$allcontenturls)
{
	$script = @"
%STSADM% -o retractsolution $(if ($allcontenturls) { "-allcontenturls" }) -immediate -name $solutionName
%STSADM% -o execadmsvcjobs
%STSADM% -o deletesolution -name $solutionName -override
%STSADM% -o execadmsvcjobs
"@

	return $script
}

function Emit-SolutionDeploymentBatchScript($solutionName, [switch]$allcontenturls)
{
	$script = @"
%STSADM% -o addsolution -filename $solutionName
%STSADM% -o deploysolution $(if ($allcontenturls) { "-allcontenturls" }) -immediate -allowgacdeployment -name $solutionName
%STSADM% -o execadmsvcjobs
REM second call to execadmsvcjobs allows for a little more delay. Shouldn't be necessary, but is.
%STSADM% -o execadmsvcjobs
"@

	return $script
}

function Emit-SolutionUpgradeBatchScript($solutionName, [switch]$allcontenturls)
{
	$script = @"
%STSADM% -o upgradesolution -immediate -allowgacdeployment -name $solutionName -filename $solutionName
%STSADM% -o execadmsvcjobs
REM second call to execadmsvcjobs allows for a little more delay. Shouldn't be necessary, but is.
%STSADM% -o execadmsvcjobs
"@

	return $script
}

function Create-StsadmBatchFile($filename, $contents)
{
	$header= @"
SET STSADM="%PROGRAMFILES%\Common Files\Microsoft Shared\web server extensions\12\BIN\stsadm.exe"
"@

	$footer = @"
echo off
ECHO -------------------------------------------------------------
%STSADM% -o displaysolution -name $solutionName
pause
"@

	$wholeFileContents = $header + "`n" + $contents + "`n" + $footer
	Out-File -inputObject $wholeFileContents -filePath $filename -encoding ASCII
}


@@#USAGE
@@. ./helper-functions.ps1
@@
@@	Set-BasePath -path ((resolve-path ..).path)
@@	Clean-DeploymentFolder
@@	Compile-Project	
@@	Run-WspBuilder
@@	Create-DeploymentBatchFilesWithSolutionOnly
@@#
@@#
@@#
