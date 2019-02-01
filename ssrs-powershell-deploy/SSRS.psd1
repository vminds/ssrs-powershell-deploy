@{
	RootModule = "SSRSdeploy"
	ModuleVersion = '1.0.0'
	GUID = '58a90a5a-fba6-464c-8906-65d78d08d398'
	Author = 'Tim Abell and others'
	Description = 'PowerShell module to deploy SQL Server Reporting Services project(s) (`.rptproj`) to a Reporting Server based on https://github.com/timabell/ssrs-powershell-deploy'
	HelpInfoURI = 'https://github.com/vminds/SSRSdeploy'
	FunctionsToExport = @("Publish-SSRSProject", "Publish-SSRSSolution")
}

