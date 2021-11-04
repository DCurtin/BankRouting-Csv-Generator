Function getACHSF
{
    param($line)

    $routingNum = $line.substring(0,9);
    $OfficeCode = $line.substring(9,1);
    $serviceFRBNumber = $line.substring(10,9);
    $recordTypeCode = $line.substring(19,1);
    $changeDate = $line.substring(20,6);
    $newRoutingNum = $line.substring(26,9);
    $bankName = $line.substring(35,36).trim();
    $address = $line.substring(71,36).trim();
    $city = $line.substring(107,20).trim();
    $state = $line.substring(127,2);
    $zip = $line.substring(129,5);
    $zipExt = $line.substring(134,4);
    $phoneNumber = $line.substring(138,10);
    $instStatusCode = $line.substring(148,1);
    $dataView = $line.substring(149,1);
    $Type='ACH';
    $BankRouteName=$routingNum + "-" + $Type;
    $Name = $BankRouteName;
    $lastUpdate= Get-Date -Format "MM/dd/yyyy"; #'7/5/2019';

    [psobject] $newEntry = (New-Object psobject -Property ([ordered] @{Type=$Type; "Bank Route Name"=$BankRouteName; Name=$Name; "Routing Number"=$routingNum; "Office Code"=$OfficeCode; "Servicing FRB Number"=$serviceFRBNumber; "Record Type Code"=$recordTypeCode; "Change Date"=$changeDate; "New Routing Number"=$newRoutingNum; "Bank Name"=$bankName; "Address"=$address; City=$city; State=$state; Zipcode=$zip; "Zipcode Extension"=$zipExt; "Telephone Number"=$phoneNumber; "Institution Status Code"=$instStatusCode; "Data View"=$dataView; "Last Update"=$lastUpdate})); 

    return $newEntry;
}

Function getACHPSQL{
    param($line)
    $routingNum = $line.substring(0,9);
    $bankName = $line.substring(35,36).Trim();
    $route_and_type = $routingNum + "-" + "ACH";

    return "`'$routingNum`',`'$($bankName -replace "'", "''")`',`'$route_and_type`'"
}

Function getWireSF
{
    param($line)

    $routingNum = $line.substring(0,9);
    $telgraphicName = $line.substring(9,18).trim();
    $bankName = $line.substring(27,36).trim();
    $state = $line.substring(63,2).trim();
    $city = $line.substring(65,25).trim();
    $fundsTransferStatus = $line.substring(90,1);
    $fundsSettledon = $line.substring(91,1);
    $bookEntry = $line.substring(92,1);
    $dateofLastRev = $line.substring(93,8).trim();
    $Type='Wire';
    $BankRouteName=$routingNum + "-Wire";
    $Name = $BankRouteName;
    $lastUpdate=Get-Date -Format "MM/dd/yyyy"; #'7/5/2019';

    [psobject] $newEntry = (New-Object psobject -Property ([ordered] @{Type=$Type; "Bank Route Name"=$BankRouteName; Name=$Name; "Routing Number"=$routingNum; "Telegraphic Name"=$telgraphicName; "Bank Name"=$bankName; State=$state; City=$city; "Funds Transfer Status"=$fundsTransferStatus; "Funds settlement-Only Status"=$fundsSettledon; "Book-Entry"=$bookEntry; "Date of Last Revision"=$dateofLastRev; "Last Update"=$lastUpdate})); 

    return $newEntry;
}

Function getWirePSQL{
    param($line)
    $routingNum = $line.substring(0,9);
    $bankName = $line.substring(27,36).Trim();
    $route_and_type = $routingNum + "-" + "Wire";

    return "`'$routingNum`',`'$($bankName -replace "'", "''")`',`'$route_and_type`'"
}

function ConvertFrom-BankRouteFiles
{
    param(
        [Parameter(Mandatory=$true, Position=0, ParameterSetName="Path", 
                   ValueFromPipeline=$true, 
                   ValueFromPipelineByPropertyName=$true,
                   HelpMessage="Path to ACH file provided by bank")]
        [ValidateNotNullOrEmpty()]
        [String]
        $ACHPath,
        [Parameter(Mandatory=$true, Position=1, ParameterSetName="Path", 
                   ValueFromPipeline=$true, 
                   ValueFromPipelineByPropertyName=$true,
                   HelpMessage="Path to Wire file provided by bank")]
        [ValidateNotNullOrEmpty()]
        [String]
        $WirePath,
        [Parameter(Mandatory=$true, Position=2, ParameterSetName="Path", 
                   ValueFromPipeline=$true, 
                   ValueFromPipelineByPropertyName=$true,
                   HelpMessage="Output directory where the CSV's and psql update files will be saved")]
        [ValidateNotNullOrEmpty()]
        [String]
        $output,
        $fileNameDate = $(Get-Date)
    )
    
    $dateFormated = "$($fileNameDate.year)-$($fileNameDate.Month.ToString().PadLeft(2,'0'))-$($fileNameDate.Day.ToString().PadLeft(2,'0'))"

    [System.Collections.ArrayList] $csvOfACHRoutes = @();
    [System.Collections.ArrayList] $csvOfWireRoutes = @();
    [System.Collections.ArrayList] $psqlOfBankRoutes = @();
    
    $psqlHeader = 'INSERT INTO salesforce.bank_route (routing_number,name,route_and_type) VALUES'
    
    $dataLines = ($(Get-Content $ACHPath)+$(Get-Content $WirePath))
    foreach($line in $dataLines)
    {
        If($line -match "\d{9}\w\d{25}")
        {
            #ach
            $newEntry = getACHSF $line;
            $null = $csvOfACHRoutes.add($newEntry);

            $psqlEntry = "($(getACHPSQL $line))"
            $null = $psqlOfBankRoutes.Add($psqlEntry)
        }else
        {
            #wire
            $newEntry = getWireSF $line;
            $null = $csvOfWireRoutes.add($newEntry);

            $psqlEntry = "($(getWirePSQL $line))"
            $null = $psqlOfBankRoutes.Add($psqlEntry)
        }
    }
    if(-not $(Test-Path $output)){
        mkdir $output
    }

    $csvOfACHRoutes | Export-Csv -Path "$output\ACH - $dateFormated.csv" -NoTypeInformation
    $csvOfWireRoutes| Export-Csv -Path "$output\Wire - $dateFormated.csv" -NoTypeInformation

    $psqlString = "$psqlHeader`r`n" + $($psqlOfBankRoutes -join ",`r`n") + "`r`n" + "ON CONFLICT (route_and_type) DO UPDATE SET (name,routing_number)=(EXCLUDED.name,EXCLUDED.routing_number);"

    $psqlString | Out-File -Encoding utf8 -FilePath "$output\ServerUpdate.psql"

    Write-Host "Complete"
}

Export-ModuleMember -Function ConvertFrom-BankRouteFiles