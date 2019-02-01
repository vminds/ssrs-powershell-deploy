# SSRS Powershell Deploy

* https://github.com/vminds/ssrs-powershell-deploy

PowerShell module to publish SQL Server Reporting Services solution(s) and project(s)
to a Microsoft SSRS Reporting Server

## This fork

This repository was forked from:

* https://github.com/timabell/ssrs-powershell-deploy


Added features are: 
* Logging integration using ScriptLogger module
* Fix for project xml node navigation when only one RDL/DS (https://github.com/timabell/ssrs-powershell-deploy/issues/26)
* Log dump of reportfolder hierarchy  
* Caller script (DeploySSRSSolution.ps1) which will call the solution deploy.
* Remove of RDL/datasource which are no longer in the project.
* Hash compare of RDL files (OverwriteReports  param)
* Support for database based credentials on datasources

Longer goal is a complete refactor to the ReportingServicesTools lib provided by Microsoft:
https://github.com/Microsoft/ReportingServicesTools

Usage: call DeploySSRSSolution.ps1 with desired parameters.

