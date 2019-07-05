Function getACH
{
    param($line)

    $routingNum = $line.substring(0,9);
    $OfficeCode = $line.substring(9,1);
    $serviceFRBNumber = $line.substring(10,9);
    $recordTypeCode = $line.substring(19,1);
    $changeDate = $line.substring(20,6);
    $newRoutingNum = $line.substring(26,9);
    $bankName = $line.substring(35,36);
    $address = $line.substring(71,36);
    $city = $line.substring(107,20);
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

Function getWire
{
    param($line)

    $routingNum = $line.substring(0,9);
    $telgraphicName = $line.substring(9,18);
    $bankName = $line.substring(27,36);
    $state = $line.substring(63,2);
    $city = $line.substring(65,25);
    $fundsTransferStatus = $line.substring(90,1);
    $fundsSettledon = $line.substring(91,1);
    $bookEntry = $line.substring(92,1);
    $dateofLastRev = $line.substring(93,8);
    $Type='Wire';
    $BankRouteName=$routingNum + "-Wire";
    $Name = $BankRouteName;
    $lastUpdate=Get-Date -Format "MM/dd/yyyy"; #'7/5/2019';

    [psobject] $newEntry = (New-Object psobject -Property ([ordered] @{Type=$Type; "Bank Route Name"=$BankRouteName; Name=$Name; "Routing Number"=$routingNum; "Telegraphic Name"=$telgraphicName; "Bank Name"=$bankName; State=$state; City=$city; "Funds Transfer Status"=$fundsTransferStatus; "Funds settlement-Only Status"=$fundsSettledon; "Book-Entry"=$bookEntry; "Date of Last Revision"=$dateofLastRev; "Last Update"=$lastUpdate})); 

    return $newEntry;
}

Function Generate-BankNumber
{
    param(
        $folderPath,
        $output
    )
    [System.Collections.ArrayList] $csvOfBankRoutes = @();

    foreach($line in Get-Content $folderPath)
    {
        $firstTwentyThreeChar = $line.substring(0,35);
        If($line -match "\d{9}\w\d{25}")
        {
            #ach
            $newEntry = getACH $line;
            $csvOfBankRoutes.add($newEntry)>$null;
        }else
        {
            #wire
            $newEntry = getWire $line;
            $csvOfBankRoutes.add($newEntry)>$null;
        }

        #echo $line
        
        #$lastupdates = '7/2/2019';
        #echo $telgraphicName;
        
        #$csvOfBankRoutes.add($newEntry) >$null;
    }
    $csvOfBankRoutes | Export-Csv -Path $output -NoTypeInformation
    echo "Complete"
    #return $csvOfBankRoutes;
}