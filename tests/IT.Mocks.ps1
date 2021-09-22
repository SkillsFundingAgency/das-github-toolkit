# Mock Invoke-RestMethod and Invoke-WebRequest cmdlets with any Method parameter value other than Get to prevent potentially destructive API calls during tests
Mock Invoke-RestMethod -ModuleName GitHubToolKit -ParameterFilter { $Method -notmatch "get" }
Mock Invoke-WebRequest -ModuleName GitHubToolKit -ParameterFilter { $Method -notmatch "get" }