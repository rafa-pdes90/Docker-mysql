[CmdletBinding()]
param(
  [Parameter(Mandatory=$True)]
  [AllowEmptyString()][string]
  $MYSQL_ROOT_PASSWORD,
  
  [Parameter(Mandatory=$True)]
  [AllowEmptyString()][string]
  $MYSQL_ROOT_HOST,
  
  [Parameter(Mandatory=$True)]
  [AllowEmptyString()][string]
  $MYSQL_DATABASE,
  
  [Parameter(Mandatory=$True)]
  [AllowEmptyString()][string]
  $MYSQL_USER,
  
  [Parameter(Mandatory=$True)]
  [AllowEmptyString()][string]
  $MYSQL_PASSWORD,
  
  [Parameter(Mandatory=$True)]
  [AllowEmptyString()][string]
  $MYSQL_ALLOW_EMPTY_PASSWORD,
  
  [Parameter(Mandatory=$True)]
  [AllowEmptyString()][string]
  $MYSQL_RANDOM_ROOT_PASSWORD,
  
  [Parameter(Mandatory=$True)]
  [AllowEmptyString()][string]
  $MYSQL_ONETIME_PASSWORD,
  
  [Parameter(Mandatory=$True)]
  [AllowEmptyString()][string]
  $DOCKER_NEW_RUN
)

function Load-Init {
  $sqlcmd = ""

  if ($MYSQL_ROOT_HOST -And $MYSQL_ROOT_HOST -ne "localhost") {
    $sqlcmd += "GRANT ALL PRIVILEGES ON *.* TO 'root'@'" + $MYSQL_ROOT_HOST + "' IDENTIFIED BY '" + $MYSQL_ROOT_PASSWORD + "' WITH GRANT OPTION; "
  
    if ($MYSQL_ONETIME_PASSWORD -eq "yes") {
      $sqlcmd += "ALTER USER 'root'@'" + $MYSQL_ROOT_HOST + "' PASSWORD EXPIRE; "
    }
  }

  if ($MYSQL_DATABASE) {
    $sqlcmd += "CREATE DATABASE IF NOT EXISTS " + $MYSQL_DATABASE + "; USE " + $MYSQL_DATABASE + "; "
  }

  if ($MYSQL_USER -And $MYSQL_PASSWORD) {  
    if ($MYSQL_DATABASE) {
      $tempcmd = "GRANT ALL PRIVILEGES ON ``" + $MYSQL_DATABASE + "`` . * TO '"
    }
    else {
      $tempcmd = "GRANT USAGE ON *.* TO '"
    }
    
    $sqlcmd += $tempcmd + $MYSQL_USER + "'@'localhost' IDENTIFIED BY '" + $MYSQL_PASSWORD + "'; "
    
    if ($MYSQL_ROOT_HOST -And $MYSQL_ROOT_HOST -ne "localhost") {
      $sqlcmd += $tempcmd + $MYSQL_USER + "'@'" + $MYSQL_ROOT_HOST + "' IDENTIFIED BY '" + $MYSQL_PASSWORD + "'; "
    }
  }
  
  return $sqlcmd
}

function Load-Extra {
  $sqlcmd = ""

  Get-ChildItem -Path .\\docker-entrypoint-initdb.d\* -Include *ps1, *.sql | Foreach-Object -Process {
    $extn = [IO.Path]::GetExtension($_.FullName)
    if ($extn -eq ".ps1")
    {
      Write-Verbose "Running $($_.Name)"
      Invoke-Expression "& `"$_`" -Verbose"
    }
    elseif ($extn -eq ".sql")
    {
      Write-Verbose "Loading $($_.Name)"
      $sqlcmd += "source c:/docker-entrypoint-initdb.d/$($_.Name); "
    }
  }
  
  return $sqlcmd
}

if (! $MYSQL_ROOT_PASSWORD -And $MYSQL_ALLOW_EMPTY_PASSWORD -ne "yes" -And $MYSQL_RANDOM_ROOT_PASSWORD -ne "yes" ) {
  Write-Verbose 'error: database is uninitialized and password option is not specified'
  Write-Verbose 'You need to specify one of MYSQL_ROOT_PASSWORD, MYSQL_ALLOW_EMPTY_PASSWORD and MYSQL_RANDOM_ROOT_PASSWORD'
  return
}

# attach data files if they don't exist:
if ((Test-Path 'c:\mysql\data\*') -eq $false) {
  Copy-Item -Recurse -Path 'c:\mysql\data-default\*' -Destination 'c:\mysql\data'
  
  # start the service
  Write-Verbose 'Starting MySQL Server'
  Start-Service MySQL
  
  if ($MYSQL_RANDOM_ROOT_PASSWORD -eq "yes") {
    Add-Type -AssemblyName System.Web
    $MYSQL_ROOT_PASSWORD = [System.Web.Security.Membership]::GeneratePassword(12,3)
    Write-Verbose "GENERATED ROOT PASSWORD: $($MYSQL_ROOT_PASSWORD)"
  }
  
  $sqlcmd = Load-Init
  $sqlcmd += Load-Extra

  if ($MYSQL_ROOT_PASSWORD){
    $sqlcmd += "SET PASSWORD FOR 'root'@'localhost' = PASSWORD('" + $MYSQL_ROOT_PASSWORD + "'); "
    
    if($MYSQL_ROOT_PASSWORD -eq "root") {
      Write-Verbose 'WARN: Using default root password'
    }
    else {
      Write-Verbose 'Changing SA login credentials'
    }
  
    if ($MYSQL_ONETIME_PASSWORD -eq "yes") {
      Write-Verbose 'Setting current root password as expired. Use SET PASSWORD to reset it'
      $sqlcmd += "ALTER USER 'root'@'localhost' PASSWORD EXPIRE; "
    }
  }
  
  if ($sqlcmd){
    MySQL --user=root --skip-password -e $sqlcmd
  }
}
else {
  # start the service
  Write-Verbose 'Starting MySQL Server'
  Start-Service MySQL

  $sqlcmd = ""
  
  if ($DOCKER_NEW_RUN -eq "yes" -And (Test-Path 'c:\firstrun') -eq $false) {
    $sqlcmd += Load-Init
  }
  $sqlcmd += Load-Extra
  
  if ($sqlcmd){
    MySQL --user=root -p -e $sqlcmd
  }
}

# Prevents Load-Init from being called when using docker start (...)
echo "" > firstrun
