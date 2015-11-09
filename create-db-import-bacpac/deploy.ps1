param (
  $BaseName = "db-bacpac",
	$ResourceGroupName = "$BaseName-RG",
	$ResourceGroupLocation = "East US",
	$TemplateFile = "create-db-import-bacpac.json",
	$TemplateParameterFile = "create-db-import-bacpac-parameters.json",
	$DefaultStorage = "$($BaseName.ToLower())storage",
	$BacpacFilename = "BrockIntPon.bacpac",
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
	$resourceOutputs = $results.Outputs;
  
	Switch-ToServiceManagement;
	
	Restore-Database $BacpacFilename $resourceOutputs["storageAccountName"].Value $resourceOutputs["storageKey"].Value $resourceOutputs["sqlServerName"].Value $resourceOutputs["sqlDatabaseName"].Value $resourceOutputs["sqlLogin"].Value $resourceOutputs["sqlPassword"].Value;

	Write-Output $results;

	#Remove-AzureResource $ResourceGroupName;
	#Get-AzureResourceGroupLog -ResourceGroup $ResourceGroupName -Status Failed -DetailedOutput
}


function Restore-Database ($BacpacFilename, $StorageName, $StorageKey, $ServerName, $DatabaseName, $SqlLogin, $SqlPassword) {
	$containerName = "BACPAC".ToLower();
	$serverCredential = New-Object System.Management.Automation.PSCredential($SqlLogin, ($SqlPassword | ConvertTo-SecureString -asPlainText -Force));
	$sqlCtx = New-AzureSqlDatabaseServerContext -ServerName $ServerName -Credential $serverCredential;
	$storageCtx = New-AzureStorageContext -StorageAccountName $StorageName -StorageAccountKey $StorageKey;

	# Upload BACPAC to Storage Account
	$newContainer = New-AzureStorageContainer -Name $containerName -Context $storageCtx -Permission Blob;
	$blobName = gi $BacpacFilename | select Name;
	Set-AzureStorageBlobContent -File $BacpacFilename -Container $containerName `
        -Blob $blobName -Context $storageCtx -Force;

	# Restore Database
	$container = Get-AzureStorageContainer -Name $containerName -Context $storageCtx;
	$importRequest = Start-AzureSqlDatabaseImport -SqlConnectionContext $sqlCtx -StorageContainer $container -DatabaseName $DatabaseName -BlobName $blobName;

	Get-AzureSqlDatabaseImportExportStatus -RequestId $importRequest.RequestGuid -ServerName $ServerName -Username $serverCredential.UserName;
}

function Create-AzureResources {
	[CmdletBinding()]
	[OutputType([Nullable])]
	Param
	(
		$ResourceGroupName,
		$ResourceGroupLocation,
		$TemplateFile,
		$TemplateParameterFile,
		$DefaultStorage,
		$SubscriptionFile
	)
	Import-Module Azure;
	Setup-AzureEnvironment $SubscriptionFile;
	Switch-ToResourceManager;

	$rg = Get-AzureResourceGroup | ? { $_.ResourceGroupName -eq $ResourceGroupName };
	if ($rg -eq $null) {
		New-AzureResourceGroup -Name $ResourceGroupName -Location $ResourceGroupLocation;
	}

	$results = New-AzureResourceGroupDeployment `
					-Name WebAppAUITDeployment `
					-ResourceGroupName $ResourceGroupName `
					-TemplateFile $TemplateFile `
					-TemplateParameterFile $TemplateParameterFile; #  `
					#-storageAccountName $DefaultStorageFromTemplate

	#Get-AzureResourceGroupLog -ResourceGroup $ResourceGroupName -Status Failed -DetailedOutput
	Switch-ToServiceManagement;

	return $results;
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

& Main;
