# das-github-toolkit

<img src="https://avatars.githubusercontent.com/u/9841374?s=200&v=4" align="right" alt="UK Government logo">

_Update these badges with the correct information for this project. These give the status of the project at a glance and also sign-post developers to the appropriate resources they will need to get up and running_

[![Build Status](https://dev.azure.com/sfa-gov-uk/Digital%20Apprenticeship%20Service/_apis/build/status/_projectname_?branchName=master)](https://dev.azure.com/sfa-gov-uk/Digital%20Apprenticeship%20Service/_build/latest?definitionId=_projectid_&branchName=master)
[![Quality Gate Status](https://sonarcloud.io/api/project_badges/measure?project=_projectId_&metric=alert_status)](https://sonarcloud.io/dashboard?id=_projectId_)
[![Jira Project](https://img.shields.io/badge/Jira-Project-blue)](https://skillsfundingagency.atlassian.net/secure/RapidBoard.jspa?rapidView=564&projectKey=_projectKey_)
[![Confluence Project](https://img.shields.io/badge/Confluence-Project-blue)](https://skillsfundingagency.atlassian.net/wiki/spaces/_pageurl_)
[![License](https://img.shields.io/badge/license-MIT-lightgrey.svg?longCache=true&style=flat-square)](https://en.wikipedia.org/wiki/MIT_License)

The DAS GitHub Toolkit PowerShell module provides cmdlets useful for scheduled and ad hoc auditing of repos in the SkillsFundingAgency GitHub organisation and will eventually contain cmdlets to allow for bulk updates and config and automated fixing of config drift.

## How It Works

### Project Structure

The [project module](./GitHubToolKit.psm1) file has 2 responsibilities, to load the cmdlets by dot sourcing them and to export those cmdlets as module members.  The former responsibility is offloaded to the [Invoke-DotSourceFiles](./Invoke-DotSourceFiles.ps1) cmdlet, all cmdlets and classes should be loaded via this cmdlet.  Maintaining this pattern ensures that the module is easy to maintain, extend and troubleshoot.

The module is made up of collections of classes and public and private cmdlets (currently no private cmdlets have been implemented,  but it is anticipated that these may be requried in the future to maintain readability and to ensure that cmdlets that call the REST and GraphQL APIs are not directly exposed).  These classes and cmdlets are grouped in folders using the following structure:

```
.
|--GitHubAudit
|  |--Classes
|  |  |--GitHubAuditResult.ps1
|  |--Functions
|     |--Private
|     |--Public
|        |--Get-GitHubAudit.ps1
|--GitHubCore
|  |--Functions
|     |--Public
...
```

At the root of the projects are 3 folders containing special collections of functions plus a number of other folders that contain collections of cmdlets that provide related functionality.  The 3 special folders are:
- GitHubCore: cmdlets that provide basic functionality that is shared across many cmdlets, eg `Invoke-GitHubRestMethod` and `Set-GitHubSessionInformation`
- GitHubGraphQL: cmdlets for interacting with the GitHub v4 GraphQL API
- GitHubRestApi: cmdlets for interacting with the GitHub v3 REST API

## 🚀 Installation

### Pre-Requisites

* A clone of this repository
* A code editor that supports PowerShell
* PowerShell Core
* A GitHub account and a [PAT](https://docs.github.com/en/github/authenticating-to-github/keeping-your-account-and-data-secure/creating-a-personal-access-token) token with the relevant permissions for the cmdlet(s) you're working on

### Local Development

To load the scripts in the VS Code PowerShell Integrated Console open GitHubToolKit\Invoke-DotSourceFiles.ps1 and debug it.  Rerunning this will load any changes to functions but may not load changes to classes.  If errors occur that relate to classes kill the PowerShell Integrated Console, if that doesn't fix the problem close all open PS sessions and VS Code and reopen them.

After loading the scripts run Set-GitHubSessionInformation in the PowerShell Integrated Console.  To debug a function you will need to add a line after the function in the .ps1 file to call the function.

If you have `powershell.debugging.createTemporaryIntegratedConsole` set to `true` this debugging approach will not work.

To load the module in a PowerShell console run `Import-Module .\GitHubToolKit\GitHubToolKit.psm1 -Force`, force is required to ensure changes to functions are imported.

## 🔗 External Dependencies

None

## Technologies

* PowerShell Core
* GitHub Rest API
* GitHub Graph API

## 🐛 Known Issues

None
