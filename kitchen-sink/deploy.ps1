param (
  $BaseName = "BrockIntPon",
	$ResourceGroupName = "$BaseName-RG",
	$ResourceGroupLocation = "East US",
	$TemplateFile = "kitchen-sink.json",
	$TemplateParameterFile = "kitchen-sink-parameters.json",
	$ServiceBusName = "$($BaseName.ToLower())sb",
	$DefaultStorage = "$($BaseName.ToLower())storage",
	$SubscriptionFile = "$env:userprofile\Downloads\SubscriptionProfile-credentials.publishsettings"
)

function Main {
	Import-Module Azure;

	Setup-AzureEnvironment $SubscriptionFile;

	$serviceBusConnectionStrings = @{"Prod"=$(Create-AzureServiceBusQueue $ServiceBusName $ResourceGroupLocation);
									"Stage"=$(Create-AzureServiceBusQueue "$($ServiceBusName)stage" $ResourceGroupLocation);
									"Dev"=$(Create-AzureServiceBusQueue "$($ServiceBusName)dev" $ResourceGroupLocation);}

	Switch-ToResourceManager;

	$rg = Get-AzureResourceGroup | ? { $_.ResourceGroupName -eq $ResourceGroupName };
	if ($rg -eq $null) {
		New-AzureResourceGroup -Name $ResourceGroupName -Location $ResourceGroupLocation;
	}

	$results = New-AzureResourceGroupDeployment `
					-Name WebAppDeployment `
					-ResourceGroupName $ResourceGroupName `
					-TemplateFile $TemplateFile `
					-TemplateParameterFile $TemplateParameterFile `
					-serviceBusConnectionString $($serviceBusConnectionStrings.Prod) `
					-serviceBusConnectionStringStage $($serviceBusConnectionStrings.Stage);
                    # Removed because of SDK change
                    #-storageAccountNameFromTemplate $DefaultStorage `
	Write-Output $results;
	Write-Output "ServiceBus Prod: $($serviceBusConnectionStrings.Prod)";
	Write-Output "ServiceBus Stage: $($serviceBusConnectionStrings.Stage)";
	Write-Output "ServiceBus Dev: $($serviceBusConnectionStrings.Dev)";

	Show-InExplorer $SubscriptionFile;

	Switch-ToServiceManagement;

	#Remove-AzureResource $ResourceGroupName;
	#Get-AzureResourceGroupLog -ResourceGroup $ResourceGroupName -Status Failed -DetailedOutput
}

function Setup-AzureEnvironment($PublishSettings) {
    # This code will be required in for automated Resource Manager access
    #	$securepassword = ConvertTo-SecureString -string "<YourPasswordGoesHere>" -AsPlainText -Force;
    #	$cred = new-object System.Management.Automation.PSCredential ("service@tomhollanderhotmail.onmicrosoft.com", $securepassword);
    #	Add-AzureAccount -Credential $cred;
    
	$subscription = Import-AzurePublishSettingsFile $PublishSettings
	$SubscriptionID = $subscription.Id;
	Set-AzureSubscription -SubscriptionID $SubscriptionID -CurrentStorageAccount $DefaultStorage;
	Select-AzureSubscription -SubscriptionID $SubscriptionID;
}

function Switch-ToResourceManager() {
	Switch-AzureMode AzureResourceManager -Verbose:$false | Out-Null;
	Register-AzureProvider -ProviderNamespace Microsoft.DocumentDb -Force | Out-Null;
	Register-AzureProvider -ProviderNamespace Microsoft.Web -Force | Out-Null;
	Register-AzureProvider -ProviderNamespace Sendgrid.Email -Force | Out-Null;
	Register-AzureProvider -ProviderNamespace Microsoft.ServiceBus -Force | Out-Null;
	Register-AzureProvider -ProviderNamespace Microsoft.Insights -Force | Out-Null;
}

function Switch-ToServiceManagement() {
	Switch-AzureMode -Name AzureServiceManagement -Verbose:$false | Out-Null;
}

function Show-InExplorer($file) {
	$explorerArgs = "/select, $file";
	[System.Diagnostics.Process]::Start("explorer.exe", $explorerArgs) | Out-Null;
}

function Create-AzureServiceBusQueue($Namespace, $Location) {
	# Query to see if the namespace currently exists
	$CurrentNamespace = Get-AzureSBNamespace -Name $Namespace;

	# Check if the namespace already exists or needs to be created
	if ($CurrentNamespace)
	{
		Write-Host "The namespace [$Namespace] already exists in the [$($CurrentNamespace.Region)] region.";
	}
	else
	{
		Write-Host "The [$Namespace] namespace does not exist.";
		Write-Host "Creating the [$Namespace] namespace in the [$Location] region...";
		New-AzureSBNamespace -Name $Namespace -Location $Location -CreateACSNamespace $false -NamespaceType Messaging;
		$CurrentNamespace = Get-AzureSBNamespace -Name $Namespace;
		Write-Host "The [$Namespace] namespace in the [$Location] region has been successfully created.";
	}
	return $CurrentNamespace.ConnectionString;
}

& Main;
