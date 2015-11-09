# Created an Azure SQL Database and restores a BACPAC file

<!--<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2F0xbrock%2Fazure-rm-templates%2Fmaster%2Fkitchen-sink%2Fkitchen-sink.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>-->

This template creates an Azure SQL Database and imports a BACPAC file.

## Issues
There is an issue with Start-AzureSqlDatabaseImport sometimes prompting for the database user password despite it being used to create the SQL context.