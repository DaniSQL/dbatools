﻿
#region Test whether the module had already been imported
$ImportLibrary = $true
try
{
    $null = New-Object sqlcollective.dbatools.Configuration.Config
    
    # No need to load the library again, if the module was once already imported.
    $ImportLibrary = $false
}
catch
{
    
}
#endregion Test whether the module had already been imported

if ($ImportLibrary)
{
    #region Source Code
    $source = @'
using System;

namespace sqlcollective.dbatools
{
    namespace Configuration
    {
        using System.Collections;

        /// <summary>
        /// Configuration Manager as well as individual configuration object.
        /// </summary>
        [Serializable]
        public class Config
        {
            /// <summary>
            /// The central configuration store 
            /// </summary>
            public static Hashtable Cfg = new Hashtable();

            /// <summary>
            /// The hashtable containing the configuration handler scriptblocks.
            /// When registering a value to a configuration element, that value is stored in a hashtable.
            /// However these lookups can be expensive when done repeatedly.
            /// For greater performance, the most frequently stored values are stored in static fields instead.
            /// In order to facilitate this, an event can be reigstered - which is stored in this hashtable - that will accept the input value and copy it to the target field.
            /// </summary>
            public static Hashtable ConfigHandler = new Hashtable();

            /// <summary>
            /// The Name of the setting
            /// </summary>
            public string Name;

            /// <summary>
            /// The module of the setting. Helps being able to group configurations.
            /// </summary>
            public string Module;

            /// <summary>
            /// A description of the specific setting
            /// </summary>
            public string Description;

            /// <summary>
            /// The data type of the value stored in the configuration element.
            /// </summary>
            public string Type
            {
                get
                {
                    try { return Value.GetType().FullName; }
                    catch { return null; }
                }
                set { }
            }

            /// <summary>
            /// The value stored in the configuration element
            /// </summary>
            public Object Value;

            /// <summary>
            /// Setting this to true will cause the element to not be discovered unless using the '-Force' parameter on "Get-DbaConfig"
            /// </summary>
            public bool Hidden = false;
        }
    }

    namespace Connection
    {
        using System.Collections.Generic;
        using System.Management.Automation;

        /// <summary>
        /// Provides static tools for managing connections
        /// </summary>
        public static class ConnectionHost
        {
            /// <summary>
            /// List of all registered connections.
            /// </summary>
            public static Dictionary<string, ManagementConnection> Connections = new Dictionary<string, ManagementConnection>();
        }

        /// <summary>
        /// Contains management connection information for a windows server
        /// </summary>
        [Serializable]
        public class ManagementConnection
        {
            /// <summary>
            /// The computer to connect to
            /// </summary>
            public string ComputerName;

            #region Connection Stats
            /// <summary>
            /// Did the last connection attempt using CimRM work?
            /// </summary>
            public bool CimRM;

            /// <summary>
            /// When was the last connection attempt using CimRM?
            /// </summary>
            public DateTime LastCimRM;

            /// <summary>
            /// Did the last connection attempt using CimDCOM work?
            /// </summary>
            public bool CimDCOM;

            /// <summary>
            /// When was the last connection attempt using CimRM?
            /// </summary>
            public DateTime LastCimDCOM;

            /// <summary>
            /// Did the last connection attempt using Wmi work?
            /// </summary>
            public bool Wmi;

            /// <summary>
            /// When was the last connection attempt using CimRM?
            /// </summary>
            public DateTime LastWmi;

            /// <summary>
            /// Did the last connection attempt using PowerShellRemoting work?
            /// </summary>
            public bool PowerShellRemoting;

            /// <summary>
            /// When was the last connection attempt using CimRM?
            /// </summary>
            public DateTime LastPowerShellRemoting;
            #endregion Connection Stats

            #region Credential Management
            /// <summary>
            /// Any registered credentials to use on the connection.
            /// </summary>
            public PSCredential Credentials;

            /// <summary>
            /// Whether the default credentials override explicitly specified credentials
            /// </summary>
            public bool OverrideInputCredentials;

            /// <summary>
            /// Credentials known to not work. They will not be used when specified.
            /// </summary>
            public List<PSCredential> KnownBadCredentials = new List<PSCredential>();

            /// <summary>
            /// Adds a credentials object to the list of credentials known to not work.
            /// </summary>
            /// <param name="Credential">The bad credential that must be punished</param>
            public void AddBadCredential(PSCredential Credential)
            {
                if (Credential == null) { return; }
                foreach (PSCredential cred in KnownBadCredentials)
                {
                    if (cred.UserName.ToLower() == Credential.UserName.ToLower())
                    {
                        if (cred.GetNetworkCredential().Password == Credential.GetNetworkCredential().Password)
                            return;
                    }
                }
                KnownBadCredentials.Add(Credential);
            }

            /// <summary>
            /// Calculates, which credentials to use. Will consider input, compare it with know not-working credentials or use the configured working credentials for that.
            /// </summary>
            /// <param name="Credential">Any credential object a user may have explicitly specified.</param>
            /// <returns>The Credentials to use</returns>
            public PSCredential GetCredential(PSCredential Credential)
            {
                if (OverrideInputCredentials) { return Credentials; }
                if (Credential == null) { return null; }

                foreach (PSCredential cred in KnownBadCredentials)
                {
                    if (cred.UserName.ToLower() == Credential.UserName.ToLower())
                    {
                        if (cred.GetNetworkCredential().Password == Credential.GetNetworkCredential().Password)
                            return Credentials;
                    }
                }

                return Credential;
            }

            /// <summary>
            /// Tests whether the input credential is on the list known, bad credentials
            /// </summary>
            /// <param name="Credential">The credential to test</param>
            /// <returns>True if the credential is known to not work, False if it is not yet known to not work</returns>
            public bool IsBadCredential(PSCredential Credential)
            {
                if (Credential == null) { return false; }

                foreach (PSCredential cred in KnownBadCredentials)
                {
                    if (cred.UserName.ToLower() == Credential.UserName.ToLower())
                    {
                        if (cred.GetNetworkCredential().Password == Credential.GetNetworkCredential().Password)
                            return true;
                    }
                }

                return false;
            }

            /// <summary>
            /// Removes an item from the list of known bad credentials
            /// </summary>
            /// <param name="Credential">The credential to remove</param>
            public void RemoveBadCredential(PSCredential Credential)
            {
                if (Credential == null) { return; }

                foreach (PSCredential cred in KnownBadCredentials)
                {
                    if (cred.UserName.ToLower() == Credential.UserName.ToLower())
                    {
                        if (cred.GetNetworkCredential().Password == Credential.GetNetworkCredential().Password)
                        {
                            KnownBadCredentials.Remove(cred);
                        }
                    }
                }

                return;
            }
            #endregion Credential Management

            #region Connection Types
            /// <summary>
            /// Connectiontypes that will never be used
            /// </summary>
            public ManagementConnectionType DisabledConnectionTypes = ManagementConnectionType.None;
            
            /// <summary>
            /// Returns the next connection type to try.
            /// </summary>
            /// <param name="ExcludedTypes">Exclude any type already tried and failed</param>
            /// <returns>The next type to try.</returns>
            public ManagementConnectionType GetConnectionType(ManagementConnectionType ExcludedTypes)
            {
                ManagementConnectionType temp = ExcludedTypes | DisabledConnectionTypes;

                if ((ManagementConnectionType.CimRM & temp) == 0)
                    return ManagementConnectionType.CimRM;

                if ((ManagementConnectionType.CimDCOM & temp) == 0)
                    return ManagementConnectionType.CimDCOM;

                if ((ManagementConnectionType.Wmi & temp) == 0)
                    return ManagementConnectionType.Wmi;

                if ((ManagementConnectionType.PowerShellRemoting & temp) == 0)
                    return ManagementConnectionType.PowerShellRemoting;

                throw new PSInvalidOperationException("No connectiontypes left to try!");
            }

            /// <summary>
            /// Returns a list of all available connection types whose inherent timeout has expired.
            /// </summary>
            /// <param name="Timestamp">All last connection failures older than this point in time are considered to be expired</param>
            /// <returns>A list of all valid connection types</returns>
            public List<ManagementConnectionType> GetConnectionTypesTimed(DateTime Timestamp)
            {
                List<ManagementConnectionType> types = new List<ManagementConnectionType>();

                if (((DisabledConnectionTypes & ManagementConnectionType.CimRM) == 0) && ((CimRM) || (LastCimRM < Timestamp)))
                    types.Add(ManagementConnectionType.CimRM);

                if (((DisabledConnectionTypes & ManagementConnectionType.CimDCOM) == 0) && ((CimDCOM) || (LastCimDCOM < Timestamp)))
                    types.Add(ManagementConnectionType.CimDCOM);

                if (((DisabledConnectionTypes & ManagementConnectionType.Wmi) == 0) && ((Wmi) || (LastWmi < Timestamp)))
                    types.Add(ManagementConnectionType.Wmi);

                if (((DisabledConnectionTypes & ManagementConnectionType.PowerShellRemoting) == 0) && ((PowerShellRemoting) || (LastPowerShellRemoting < Timestamp)))
                    types.Add(ManagementConnectionType.PowerShellRemoting);

                return types;
            }

            /// <summary>
            /// Returns a list of all available connection types whose inherent timeout has expired.
            /// </summary>
            /// <param name="Timespan">All last connection failures older than this far back into the past are considered to be expired</param>
            /// <returns>A list of all valid connection types</returns>
            public List<ManagementConnectionType> GetConnectionTypesTimed(TimeSpan Timespan)
            {
                return GetConnectionTypesTimed(DateTime.Now - Timespan);
            }
            #endregion Connection Types
        }

        /// <summary>
        /// The various ways to connect to a windows server fopr management purposes.
        /// </summary>
        [Flags]
        public enum ManagementConnectionType
        {
            /// <summary>
            /// No Connection-Type
            /// </summary>
            None = 0,

            /// <summary>
            /// Cim over a WinRM connection
            /// </summary>
            CimRM = 1,

            /// <summary>
            /// Cim over a DCOM connection
            /// </summary>
            CimDCOM = 2,

            /// <summary>
            /// WMI Connection
            /// </summary>
            Wmi = 4,

            /// <summary>
            /// Connecting with PowerShell remoting and performing WMI queries locally
            /// </summary>
            PowerShellRemoting = 8
        }
    }

    namespace Database
    {
        /// <summary>
        /// Class containing all dependency information over a database object
        /// </summary>
        [Serializable]
        public class Dependency
        {
            /// <summary>
            /// The name of the SQL server from whence the query came
            /// </summary>
            public string ComputerName;

            /// <summary>
            /// Name of the service running the database containing the dependency
            /// </summary>
            public string ServiceName;

            /// <summary>
            /// The Instance the database containing the dependency is running in.
            /// </summary>
            public string SqlInstance;

            /// <summary>
            /// The name of the dependent
            /// </summary>
            public string Dependent;

            /// <summary>
            /// The kind of object the dependent is
            /// </summary>
            public string Type;

            /// <summary>
            /// The owner of the dependent (usually the Database)
            /// </summary>
            public string Owner;

            /// <summary>
            /// Whether the dependency is Schemabound. If it is, then the creation statement order is of utmost importance.
            /// </summary>
            public bool IsSchemaBound;

            /// <summary>
            /// The immediate parent of the dependent. Useful in multi-tier dependencies.
            /// </summary>
            public string Parent;

            /// <summary>
            /// The type of object the immediate parent is.
            /// </summary>
            public string ParentType;

            /// <summary>
            /// The script used to create the object.
            /// </summary>
            public string Script;

            /// <summary>
            /// The tier in the dependency hierarchy tree. Used to determine, which dependency must be applied in which order.
            /// </summary>
            public int Tier;

            /// <summary>
            /// The smo object of the dependent.
            /// </summary>
            public object Object;

            /// <summary>
            /// The Uniform Resource Name of the dependent.
            /// </summary>
            public object Urn;

            /// <summary>
            /// The object of the original resource, from which the dependency hierachy has been calculated.
            /// </summary>
            public object OriginalResource;
        }
    }

    namespace dbaSystem
    {
        using System.Collections.Concurrent;
        using System.Management.Automation;
        using System.Threading;
        
        /// <summary>
        /// An error record written by dbatools
        /// </summary>
        [Serializable]
        public class DbaErrorRecord
        {
            /// <summary>
            /// The category of the error
            /// </summary>
            public ErrorCategoryInfo CategoryInfo;

            /// <summary>
            /// The details on the error
            /// </summary>
            public ErrorDetails ErrorDetails;

            /// <summary>
            /// The actual exception thrown
            /// </summary>
            public Exception Exception;

            /// <summary>
            /// The specific error identity, used to identify the target
            /// </summary>
            public string FullyQualifiedErrorId;

            /// <summary>
            /// The details of how this was called.
            /// </summary>
            public object InvocationInfo;

            /// <summary>
            /// The script's stacktrace
            /// </summary>
            public string ScriptStackTrace;

            /// <summary>
            /// The object being processed
            /// </summary>
            public object TargetObject;

            /// <summary>
            /// The name of the function throwing the error
            /// </summary>
            public string FunctionName;

            /// <summary>
            /// When was the error thrown
            /// </summary>
            public DateTime Timestamp;

            /// <summary>
            /// The message that was written in a userfriendly manner
            /// </summary>
            public string Message;

            /// <summary>
            /// Create an empty record
            /// </summary>
            public DbaErrorRecord()
            {

            }

            /// <summary>
            /// Create a filled out error record
            /// </summary>
            /// <param name="Record">The original error record</param>
            /// <param name="FunctionName">The function that wrote the error</param>
            /// <param name="Timestamp">When was the error generated</param>
            /// <param name="Message">What message was passed when writing the error</param>
            public DbaErrorRecord(ErrorRecord Record, string FunctionName, DateTime Timestamp, string Message)
            {
                this.FunctionName = FunctionName;
                this.Timestamp = Timestamp;
                this.Message = Message;

                CategoryInfo = Record.CategoryInfo;
                ErrorDetails = Record.ErrorDetails;
                Exception = Record.Exception;
                FullyQualifiedErrorId = Record.FullyQualifiedErrorId;
                InvocationInfo = Record.InvocationInfo;
                ScriptStackTrace = Record.ScriptStackTrace;
                TargetObject = Record.TargetObject;
            }
        }

        /// <summary>
        /// Hosts static debugging values and methods
        /// </summary>
        public static class DebugHost
        {
            #region Defines
            /// <summary>
            /// The maximum numbers of error records maintained in-memory.
            /// </summary>
            public static int MaxErrorCount = 128;

            /// <summary>
            /// The maximum number of messages that can be maintained in the in-memory message queue
            /// </summary>
            public static int MaxMessageCount = 1024;

            /// <summary>
            /// The maximum size of a given logfile. When reaching this limit, the file will be abandoned and a new log created. Set to 0 to not limit the size.
            /// </summary>
            public static int MaxMessagefileBytes = 5242880; // 5MB

            /// <summary>
            /// The maximum number of logfiles maintained at a time. Exceeding this number will cause the oldest to be culled. Set to 0 to disable the limit.
            /// </summary>
            public static int MaxMessagefileCount = 5;

            /// <summary>
            /// The maximum size all error files combined may have. When this number is exceeded, the oldest entry is culled.
            /// </summary>
            public static int MaxErrorFileBytes = 20971520; // 20MB

            /// <summary>
            /// This is the upper limit of length all items in the log folder may have combined across all processes.
            /// </summary>
            public static int MaxTotalFolderSize = 104857600; // 100MB

            /// <summary>
            /// Path to where the logfiles live.
            /// </summary>
            public static string LoggingPath;

            /// <summary>
            /// Any logfile older than this will automatically be cleansed
            /// </summary>
            public static TimeSpan MaxLogFileAge = new TimeSpan(7, 0, 0, 0);

            /// <summary>
            /// Governs, whether a log file for the system messages is written
            /// </summary>
            public static bool MessageLogFileEnabled = true;

            /// <summary>
            /// Governs, whether a log of recent messages is kept in memory
            /// </summary>
            public static bool MessageLogEnabled = true;

            /// <summary>
            /// Governs, whether log files for errors are written
            /// </summary>
            public static bool ErrorLogFileEnabled = true;

            /// <summary>
            /// Governs, whether a log of recent errors is kept in memory
            /// </summary>
            public static bool ErrorLogEnabled = true;
            #endregion Defines

            #region Queues
            private static ConcurrentQueue<DbaErrorRecord> ErrorRecords = new ConcurrentQueue<DbaErrorRecord>();

            private static ConcurrentQueue<LogEntry> LogEntries = new ConcurrentQueue<LogEntry>();

            /// <summary>
            /// The outbound queue for errors. These will be processed and written to xml
            /// </summary>
            public static ConcurrentQueue<DbaErrorRecord> OutQueueError = new ConcurrentQueue<DbaErrorRecord>();

            /// <summary>
            /// The outbound queue for logs. These will be processed and written to logfile
            /// </summary>
            public static ConcurrentQueue<LogEntry> OutQueueLog = new ConcurrentQueue<LogEntry>();
            #endregion Queues

            #region Access Queues
            /// <summary>
            /// Retrieves a copy of the Error stack
            /// </summary>
            /// <returns>All errors thrown by dbatools functions</returns>
            public static DbaErrorRecord[] GetErrors()
            {
                DbaErrorRecord[] temp = new DbaErrorRecord[ErrorRecords.Count];
                ErrorRecords.CopyTo(temp, 0);
                return temp;
            }

            /// <summary>
            /// Retrieves a copy of the message log
            /// </summary>
            /// <returns>All messages logged this session.</returns>
            public static LogEntry[] GetLog()
            {
                LogEntry[] temp = new LogEntry[LogEntries.Count];
                LogEntries.CopyTo(temp, 0);
                return temp;
            }

            /// <summary>
            /// Write an error record to the log
            /// </summary>
            /// <param name="Record">The actual error record as powershell wrote it</param>
            /// <param name="FunctionName">The name of the function writing the error</param>
            /// <param name="Timestamp">When was the error written</param>
            /// <param name="Message">What message was passed to the user</param>
            public static void WriteErrorEntry(ErrorRecord Record, string FunctionName, DateTime Timestamp, string Message)
            {
                DbaErrorRecord temp = new DbaErrorRecord(Record, FunctionName, Timestamp, Message);
                if (ErrorLogFileEnabled) { OutQueueError.Enqueue(temp); }
                if (ErrorLogEnabled) { ErrorRecords.Enqueue(temp); }

                DbaErrorRecord tmp;
                while ((MaxErrorCount > 0) && (ErrorRecords.Count > MaxErrorCount))
                {
                    ErrorRecords.TryDequeue(out tmp);
                }
            }

            /// <summary>
            /// Write a new entry to the log
            /// </summary>
            /// <param name="Message">The message to log</param>
            /// <param name="Type">The type of the message logged</param>
            /// <param name="Timestamp">When was the message generated</param>
            /// <param name="FunctionName">What function wrote the message</param>
            /// <param name="Level">At what level was the function written</param>
            public static void WriteLogEntry(string Message, LogEntryType Type, DateTime Timestamp, string FunctionName, MessageLevel Level)
            {
                LogEntry temp = new LogEntry(Message, Type, Timestamp, FunctionName, Level);
                if (MessageLogFileEnabled) { OutQueueLog.Enqueue(temp); }
                if (MessageLogEnabled) { LogEntries.Enqueue(temp); }

                LogEntry tmp;
                while ((MaxMessageCount > 0) && (LogEntries.Count > MaxMessageCount))
                {
                    LogEntries.TryDequeue(out tmp);
                }
            }
            #endregion Access Queues
        }

        /// <summary>
        /// An individual entry for the message log
        /// </summary>
        [Serializable]
        public class LogEntry
        {
            /// <summary>
            /// The message logged
            /// </summary>
            public string Message;

            /// <summary>
            /// What kind of entry was this?
            /// </summary>
            public LogEntryType Type;

            /// <summary>
            /// When was the message logged?
            /// </summary>
            public DateTime Timestamp;

            /// <summary>
            /// What function wrote the message
            /// </summary>
            public string FunctionName;

            /// <summary>
            /// What level was the message?
            /// </summary>
            public MessageLevel Level;

            /// <summary>
            /// Creates an empty log entry
            /// </summary>
            public LogEntry()
            {

            }

            /// <summary>
            /// Creates a filled out log entry
            /// </summary>
            /// <param name="Message">The message that was logged</param>
            /// <param name="Type">The type(s) of message written</param>
            /// <param name="Timestamp">When was the message logged</param>
            /// <param name="FunctionName">What function wrote the message</param>
            /// <param name="Level">What level was the message written at.</param>
            public LogEntry(string Message, LogEntryType Type, DateTime Timestamp, string FunctionName, MessageLevel Level)
            {
                this.Message = Message;
                this.Type = Type;
                this.Timestamp = Timestamp;
                this.FunctionName = FunctionName;
                this.Level = Level;
            }
        }

        /// <summary>
        /// The kind of information the logged entry was.
        /// </summary>
        [Flags]
        public enum LogEntryType
        {
            /// <summary>
            /// A message that was written to the current host equivalent, if available to the information stream instead
            /// </summary>
            Information = 1,

            /// <summary>
            /// A message that was written to the verbose stream
            /// </summary>
            Verbose = 2,

            /// <summary>
            /// A message that was written to the Debug stream
            /// </summary>
            Debug = 4,

            /// <summary>
            /// A message written to the warning stream
            /// </summary>
            Warning = 8
        }

        /// <summary>
        /// Hosts all functionality of the log writer
        /// </summary>
        public static class LogWriterHost
        {
            #region Logwriter
            private static ScriptBlock LogWritingScript;

            private static PowerShell LogWriter;

            /// <summary>
            /// Setting this to true should cause the script running in the runspace to selfterminate, allowing a graceful selftermination.
            /// </summary>
            public static bool LogWriterStopper
            {
                get { return _LogWriterStopper; }
            }
            private static bool _LogWriterStopper = false;

            /// <summary>
            /// Set the script to use as part of the log writer
            /// </summary>
            /// <param name="Script">The script to use</param>
            public static void SetScript(ScriptBlock Script)
            {
                LogWritingScript = Script;
            }

            /// <summary>
            /// Starts the logwriter.
            /// </summary>
            public static void Start()
            {
                if ((DebugHost.ErrorLogFileEnabled || DebugHost.MessageLogFileEnabled) && (LogWriter == null))
                {
                    _LogWriterStopper = false;
                    LogWriter = PowerShell.Create();
                    LogWriter.AddScript(LogWritingScript.ToString());
                    LogWriter.BeginInvoke();
                }
            }

            /// <summary>
            /// Gracefully stops the logwriter
            /// </summary>
            public static void Stop()
            {
                _LogWriterStopper = true;

                int i = 0;

                // Wait up to 30 seconds for the running script to notice and kill itself
                while ((LogWriter.Runspace.RunspaceAvailability != System.Management.Automation.Runspaces.RunspaceAvailability.Available) && (i < 300))
                {
                    i++;
                    Thread.Sleep(100);
                }

                Kill();
            }

            /// <summary>
            /// Very ungracefully kills the logwriter. Use only in the most dire emergency.
            /// </summary>
            public static void Kill()
            {
                LogWriter.Runspace.Close();
                LogWriter.Dispose();
                LogWriter = null;
            }
            #endregion Logwriter
        }

        /// <summary>
        /// Provides static resources to the messaging subsystem
        /// </summary>
        public static class MessageHost
        {
            #region Defines
            /// <summary>
            /// The maximum message level to still display to the user directly.
            /// </summary>
            public static int MaximumInformation = 3;

            /// <summary>
            /// The maxium message level where verbose information is still written.
            /// </summary>
            public static int MaximumVerbose = 6;

            /// <summary>
            /// The maximum message level where debug information is still written.
            /// </summary>
            public static int MaximumDebug = 9;

            /// <summary>
            /// The minimum required message level for messages that will be shown to the user.
            /// </summary>
            public static int MinimumInformation = 1;

            /// <summary>
            /// The minimum required message level where verbose information is written.
            /// </summary>
            public static int MinimumVerbose = 4;

            /// <summary>
            /// The minimum required message level where debug information is written.
            /// </summary>
            public static int MinimumDebug = 1;

            #endregion Defines
        }

        /// <summary>
        /// The various levels of verbosity available.
        /// </summary>
        public enum MessageLevel
        {
            /// <summary>
            /// Very important message, should be shown to the user as a high priority
            /// </summary>
            Critical = 1,

            /// <summary>
            /// Important message, the user should read this
            /// </summary>
            Important = 2,

            /// <summary>
            /// Important message, the user should read this
            /// </summary>
            Output = 2,

            /// <summary>
            /// Message relevant to the user.
            /// </summary>
            Significant = 3,

            /// <summary>
            /// Not important to the regular user, still of some interest to the curious
            /// </summary>
            VeryVerbose = 4,

            /// <summary>
            /// Background process information, in case the user wants some detailed information on what is currently happening.
            /// </summary>
            Verbose = 5,

            /// <summary>
            /// A footnote in current processing, rarely of interest to the user
            /// </summary>
            SomewhatVerbose = 6,

            /// <summary>
            /// A message of some interest from an internal system persepctive, but largely irrelevant to the user.
            /// </summary>
            System = 7,

            /// <summary>
            /// Something only of interest to a debugger
            /// </summary>
            Debug = 8,

            /// <summary>
            /// This message barely made the cut from being culled. Of purely development internal interest, and even there is 'interest' a strong word for it.
            /// </summary>
            InternalComment = 9,

            /// <summary>
            /// This message is a warning, sure sign something went badly wrong
            /// </summary>
            Warning = 666
        }
    }
}
'@
    #endregion Source Code
    
    try
    {
        Add-Type $source -ErrorAction Stop
    }
    catch
    {
        #region Warning
        Write-Warning @'
Dear User,

in the name of the dbatools team I apologize for the inconvenience.
Generally, when something goes wrong we try to handle it for you and interpret
it for you in a way you can understand. Unfortunately, something went wrong with
importing our main library, so all the systems making this possible don't work
yet. This really shouldn't happen in any PowerShell environment imaginable, but
... well, it hapend and you are reading this message.

Please, in order to help us prevent this from happening again, visit us at:
https://github.com/sqlcollaborative/dbatools/issues
and tell us about this failure. All information will be appreciated, but 
especially valuable are:
- Exports of the exception: $Error | Export-Clixml error.xml -Depth 4
- Screenshots
- Environment information (Operating System, Hardware Stats, .NET Version,
  PowerShell Version and whatever else you may consider of potential impact.)

Again, I apologize for the inconvenience and hope we will be able to speedily
resolve the issue.

Best Regards,
Friedrich Weinmann
aka "The guy who made most of The Library that Failed to import"

'@
        throw
        #endregion Warning
    }
}
