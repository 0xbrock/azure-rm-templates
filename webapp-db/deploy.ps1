param (
	$BaseName = "webapp-db",
	$ResourceGroupName = "$BaseName-RG",
	$ResourceGroupLocation = "East US",
	$TemplateFile = "webapp-db.json",
	$TemplateParameterFile = "webapp-db-parameters.json",
	$DefaultStorage = "$($BaseName.ToLower())storage",
	$SubscriptionFile = "Azure.publishsettings"
)

function Main {
	Import-Module Azure;
	
	Setup-AzureEnvironment $SubscriptionFile;

	Switch-ToResourceManager;

	$rg = Get-AzureResourceGroup | ? { $_.ResourceGroupName -eq $ResourceGroupName };
	if ($rg -eq $null) {
		New-AzureResourceGroup -Name $ResourceGroupName -Location $ResourceGroupLocation;
	}

	$results = New-AzureResourceGroupDeployment `
					-Name WebAppDeployment `
					-ResourceGroupName $ResourceGroupName `
					-TemplateFile $TemplateFile `
					-TemplateParameterFile $TemplateParameterFile;
	Write-Output $results;

	Switch-ToServiceManagement;

	#Remove-AzureResource $ResourceGroupName;
	#Get-AzureResourceGroupLog -ResourceGroup $ResourceGroupName -Status Failed -DetailedOutput
}

function Setup-AzureEnvironment($PublishSettings) {
	$subscription = Import-AzurePublishSettingsFile $PublishSettings;
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


& Main;