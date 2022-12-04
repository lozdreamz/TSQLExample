# T-SQL Example

Simple application that demonstrates how to work with MS SQL Server from Delphi program.

## Basic information

This application collect initial data from test database and periodically checks for updates.
At present the following updates are supported:
* Inserting new object to ObjectsTable and new values to ValuesTable

Application store configuration in config.ini and write log to log.txt

## How it works
Used classes and components:
* dbGo (TADOConnection, TADOQuery) for working with database
* TVirtualStringView (3rd party) for nice data display
* TThread to perform operation in thread

To start data collection you should click "Start" button.
Next requests are made automatically according to the settings

## Delphi version
Written in version 10.4, must compile in XE2 and newer.
