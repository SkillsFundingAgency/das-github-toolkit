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

_Add a description of how the project works technically, this should give new developers an insight into the how the project hangs together, the core concepts in-use and the high-level features that it provides_

_For Example_
```
The ServiceBus Utility is a combination of website and background processor that enumerates Azure Service Bus queues within a namespace using the error queue naming convention and presents them to the user as a selectable list, allowing messages on a queue to be retrieved for investigation. Once a queue has been selected the website will retrieve the messages from the error queue and place them into a CosmosDB under the exclusive possession of the logged in user. Once the messages have been moved into the CosmosDB the background processor will ensure that those messages are held for a maximum sliding time period of 24 hours. If messages are still present after this period expires the background processer will move them back to the error queue automatically so that they aren't held indefinitely.

Depending on the action performed by the user the messages will follow one of three paths. In the event that the user Aborts the process, the messages are moved back to the error queue they came from, if the user replays the messages they will be placed back onto the "processing queue" they were on prior to ending up in the error queue and will be removed from the CosmosDB. If the user deletes the messages then they will be removed from the CosmosDB and will be gone forever.
```

## 🚀 Installation

### Pre-Requisites

* A clone of this repository
* A code editor that supports PowerShell
* PowerShell Core
* A GitHub account and a [PAT](https://docs.github.com/en/github/authenticating-to-github/keeping-your-account-and-data-secure/creating-a-personal-access-token) token with the relevant permissions for the cmdlet(s) you're working on

## 🔗 External Dependencies

None

## Technologies

* PowerShell Core
* GitHub Rest API
* GitHub Graph API

## 🐛 Known Issues

None
