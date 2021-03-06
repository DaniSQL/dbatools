function Read-DbaTransactionLog
{
<# 
.SYNOPSIS 
Reads the live Transaction log from specied SQL Server Database

.DESCRIPTION 
Using the fn_dblog function, the live transaction log is read and returned as a PowerShell object

This function returns the whole of the log. The information is presented in the format that the logging subsystem uses.

A soft limit of 0.5GB of log as been implemented. This is based on testing. This limit can be overidden
at the users request, but please be aware that this may have an impact on your target databases and on the 
system running this function

.PARAMETER SqlInstace
A SQL Server instance to connect to

.PARAMETER SqlCredential
A credeial to use to conect to the SQL Instance rather than using Windows Authentication

.PARAMETER Database
Database to read the transaction log of

.PARAMETER IgnoreLimit
Switch to indicate that you wish to bypass the recommended limits of the function

.PARAMETER Silent 
Use this switch to disable any kind of verbose messages

.NOTES
Original Author: Stuart Moore (@napalmgram), stuart-moore.com

dbatools PowerShell module (https://dbatools.io, clemaire@gmail.com)
Copyright (C) 2016 Chrissy LeMaire

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program.  If not, see <http://www.gnu.org/licenses/>.

.EXAMPLE
$Log = Read-DbaTransactionLog -SqlInstance sql2016 -Database MyDatabase

Will read the contents of the transaction log of MyDatabase on SQL Server Instance sql2016 into the local PowerShell object $Log

.EXAMPLE
$Log = Read-DbaTransactionLog -SqlInstance sql2016 -Database MyDatabase -IgnoreLimit

Will read the contents of the transaction log of MyDatabase on SQL Server Instance sql2016 into the local PowerShell object $Log, ignoring the recommnedation of not returning more that 0.5GB of log

#>
	[CmdletBinding(DefaultParameterSetName = "Default")]
	Param (
		[parameter(Position = 0, Mandatory = $true)]
		[Alias("ServerInstance", "SqlServer")]
		[object]$SqlInstance,
		[System.Management.Automation.PSCredential]$SqlCredential,
		[parameter(Mandatory = $true)]
		[string]$Database,
		[Switch]$IgnoreLimit,
		[switch]$Silent
	)
	
	END
	{
		try
		{
			$server = Connect-SqlServer -SqlServer $SqlInstance -SqlCredential $SqlCredential
		}
		catch
		{
			Stop-Function -Message "Failed to connect to: $instance"
			return
		}
		
		if (-not $server.databases[$Database])
		{
			Stop-Function -Message "$Database does not exist"
			return
		}
		
		if ($server.databases[$Database].Status -ne 'Normal')
		{
			Stop-Function -Message "$Database is not in a normal State, command will not run."
			return
		}
		
		if ($IgnoreLimit)
		{
			Write-Message -Level Verbose -Message "Please be aware that ignoring the recommended limits may impact on the performance of the SQL Server database and the calling system"
		}
		else
		{
			#Warn if more than 0.5GB of live log. Dodgy conversion as SMO returns the value in an unhelpful format :(
			if ($server.databases[$Database].LogFiles.usedspace/1000 -ge 500) # this will cause enumeration and needs to be addressed
			{
				Stop-Function -Message "$Database has more than 0.5 Gb of live log data, returning this may have an impact on the database and the calling system. If you wish to proceed please rerun with the -IgnoreLimit switch"
				return
			}
		}
		
		$sql = "select * from fn_dblog(NULL,NULL)"
		Write-Message -Level Debug -Message $sql
		Write-Message -Level Verbose -Message "Starting Log retrieval"
		Invoke-SqlCmd2 -ServerInstance $server -Query $sql -Database $Database
	}
}
