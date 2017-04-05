# monitoring-api
Some basic Powershell calls to the ScienceLogic API services

This particular **Powershell** script has been designed to be a simple daily scheduled task pull of monitoring data into a single .csv file located in the project folder.

Once the .csv file has been created it could quite simply be integrated into a database of some sort for rendering into graphs and other dashboards.

Usage: powershell.exe -file main-query.ps1 -customerUsername "***MCPUSERNAME***" -customerPassword "***MCPPassword***"
