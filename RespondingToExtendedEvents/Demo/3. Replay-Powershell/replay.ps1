cls
sl $Env:Temp


Add-Type -Path 'C:\Program Files\Microsoft SQL Server\150\Shared\Microsoft.SqlServer.XE.Core.dll'
Add-Type -Path 'C:\Program Files\Microsoft SQL Server\150\Shared\Microsoft.SqlServer.XEvent.Linq.dll'


$sourceConnectionString = "Data Source = SQL2019; Initial Catalog = master; Integrated Security = SSPI"
$targetConnectionString = "Data Source = SQL2016; Initial Catalog = master; Integrated Security = SSPI"
$SessionName = "XERMLCapture"

[Microsoft.SqlServer.XEvent.Linq.QueryableXEventData] $events = New-Object -TypeName Microsoft.SqlServer.XEvent.Linq.QueryableXEventData `
	-ArgumentList @($sourceConnectionString, $SessionName, [Microsoft.SqlServer.XEvent.Linq.EventStreamSourceOptions]::EventStream, [Microsoft.SqlServer.XEvent.Linq.EventStreamCacheOptions]::DoNotCache)

$events | % {
	$currentEvent = $_
	
	$dbName = $currentEvent.Actions["database_name"].Value

    if ($currentEvent.Name -eq "rpc_completed") {
		$commandText = $currentEvent.Fields["statement"].Value
	}
    if ($currentEvent.Name -eq "sql_batch_completed"){
        $commandText = $currentEvent.Fields["batch_text"].Value
	}
	
	if (-not ($dbName -eq "") -and -not ($commandText -eq "")){
	
		Write-Host $(Get-Date) $commandText
	
		$conn = New-Object -TypeName System.Data.SqlClient.SqlConnection -ArgumentList $targetConnectionString
		$cmd = New-Object -TypeName System.Data.SqlClient.SqlCommand
        $cmd.CommandText = $commandText
		$cmd.Connection = $conn
        $conn.Open()
        $conn.ChangeDatabase($dbName)
        [Void]$cmd.ExecuteNonQuery()
	}
}