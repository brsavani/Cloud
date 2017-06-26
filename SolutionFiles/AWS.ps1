#Install-Module AWSPowerShell
Import-Module AWSPowerShell

$ErrorActionPreference = "Stop"


## LOGIN
$region    = "sa-east-1" #São Paulo
$AccessKey = "Access_Key"
$SecretKey = "Secret_Key"

Set-AWSCredential -AccessKey $AccessKey -SecretKey $SecretKey

#Execs
$msbuild = 'C:\Program Files (x86)\MSBuild\14.0\Bin\msbuild.exe'

#VARIABLES
    #ENVIRONMENT
    $applicationName = "GrosvenorApp"
    $environmentName = "GrosvenorEnv" 

    #DATABASE
    $mysqluser = "us1"
    $mysqlpass = "pass13434"
    $mySqlInstanceName = "mySqlGrosvenor"

    #BUILD/PACKAGE
    $projPath = $psscriptroot + "\..\Grosvenor.WebSite\Grosvenor.WebSite.csproj"
    $outputPath = $psscriptroot + "\package\"
    $outputPathFile = $psscriptroot + "\package\_PublishedWebsites\Grosvenor.WebSite_Package\Grosvenor.WebSite.zip"
    
## BUILD / CREATE PACKAGE
& $msbuild $projPath /T:Package "/P:Configuration=GrosvenorCloud;OutDir=$outputPath"

if ($LastExitCode -ne 0)
{
    write-host "Error on build application" -foregroundcolor "RED"
    Return
}

## CREATE MYSQL DATABASE
$dbInstance = New-RDSDBInstance -DBInstanceIdentifier $mySqlInstanceName -Region   $region -Engine mysql -DBInstanceClass "db.t1.micro" -MasterUsername $mysqluser -MasterUserPassword $mysqlpass -AllocatedStorage 5
while ($dbInstance.DBInstanceStatus -eq "creating" -or $dbInstance.DBInstanceStatus -eq "backing-up")
{
    Write-Host "DataBase: " + $dbInstance.DBInstanceStatus -ForegroundColor Yellow
    sleep 30
    $dbInstance = Get-RDSDBInstance -Region $region -DBInstanceIdentifier $mySqlInstanceName
}
if($dbInstance.DBInstanceStatus -eq "available")
{    Write-Host "DataBase Created" -ForegroundColor Green}
else
{    
    Write-Host "Error on create database: Status " + $dbInstance.DBInstanceStatus -ForegroundColor Red
    return
}


##CREATE APPLICATION
$application = New-EBApplication -ApplicationName $applicationName -Region $region

## CREATE APPCONFIG FOR DATABASE ENDPOINT
$option = New-Object Amazon.ElasticBeanstalk.Model.ConfigurationOptionSetting -Property @{
    Namespace = "aws:elasticbeanstalk:application:environment"
    OptionName = "MysqlServer"
    Value = $dbInstance.Endpoint.Address
}

## CREATE ENVIRONMENT
$EBEnvironment = New-EBEnvironment -OptionSetting $option -EnvironmentName $environmentName -Region $region -ApplicationName $applicationName -SolutionStackName '64bit Windows Server 2012 R2 v1.2.0 running IIS 8.5'
while ($EBEnvironment.Status -eq "Launching")
{
    Write-Host "Creating Environment..." -ForegroundColor Yellow
    sleep 30
    $EBEnvironment = Get-EBEnvironment  -EnvironmentName $environmentName -Region $region -ApplicationName $applicationName
}
if($EBEnvironment.Status -eq "Ready")
{    Write-Host "Environment Created" -ForegroundColor Green}
else
{    
    Write-Host "Error on create Environment: Status " + $EBEnvironment.Status -ForegroundColor Red
    return
}


##PUBLISH
$random = Get-Random
$versionLabel = "version-" + $random

$s3Bucket = New-EBStorageLocation -Region $region
Write-S3Object -BucketName $s3Bucket -File $outputPathFile

$applicationVersion = New-EBApplicationVersion -ApplicationName $applicationName -Region $region -VersionLabel $versionLabel -SourceBundle_S3Bucket $s3Bucket -SourceBundle_S3Key Grosvenor.WebSite.zip
$UpdateVersion = Update-EBEnvironment -ApplicationName $applicationName -Region $region -EnvironmentName $environmentName -VersionLabel $versionLabel

while ($UpdateVersion.Status -eq "Updating" -or $UpdateVersion.Status -eq "Launching")
{
    Write-Host "Updating Environment..." -ForegroundColor Yellow
    sleep 30
    $UpdateVersion = Get-EBEnvironment -ApplicationName $applicationName -Region $region -EnvironmentName $environmentName
}
 
if($UpdateVersion.Status -eq "Ready")
{    Write-Host "Environment Updated" -ForegroundColor Green}
else
{    
    Write-Host "Error on update environment: Status " + $UpdateVersion.Status -ForegroundColor Red
    return
}


## GRANT PERMITION TO MYSQL PORT 
$newIpRule = New-Object Amazon.EC2.Model.IpPermission -Property @{IpProtocol= "6"; FromPort='3306'; ToPort='3306'; IpRange = "0.0.0.0/0"; } 
Grant-EC2SecurityGroupIngress  -Region $region -GroupId $dbInstance.VpcSecurityGroups.VpcSecurityGroupId -IpPermission $newIpRule


Write-Host "DONE, URL =>" $EBEnvironment.EndpointURL -ForegroundColor Black -BackgroundColor Green

