-- Check if the 'sa' account exists and retrieve its type description
SELECT name, type_desc FROM sys.server_principals WHERE name = 'sa';

-- Switch to the master database
USE [master];
GO

-- Create a new login '<NewUserName>' with a specified password and disable password policy checks
CREATE LOGIN [<NewUserName>] 
WITH PASSWORD = '<Password>',
CHECK_POLICY = OFF;
GO

-- Add the '<NewUserName>' login to the sysadmin server role
ALTER SERVER ROLE sysadmin ADD MEMBER [<NewUserName>];
GO

-- Login with the newly created user
-- Verify if the '<NewUserName>' login is a member of the sysadmin role
SELECT IS_SRVROLEMEMBER('sysadmin') as 'IsAdmin';
