# Web application with staging slot and MANY types of resources configured

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2F0xbrock%2Fazure-rm-templates%2Fmaster%2Fkitchen-sink%2Fkitchen-sink.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>

This template creates an Azure Web App with a Staging slot and configures the connection strings accordingly.

This template also deploys Production and Stage resources for the following:
. Storage Account
. DocumentDb
. Redis (Prod only)
