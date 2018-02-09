#Developer: Jacob Suchorabski
#Based on Microsoft's article about PII
#https://technet.microsoft.com/en-us/library/2008.04.securitywatch.aspx
#Version: 1.0.1

#Name:			OutputPath
#Type:			Variable
#Purpose:		Location of the textfile where the results will be stored
$OutputPath = "C:\temp\PII-Results.txt"

#Name:			FoldersToCheck
#Type:			Variable
#Purpose:		Contains all folders located on the C: drive that are not excluded in the Select-String exclude pattern
$FoldersToCheck = Get-ChildItem -Path C:\ | Select-String -pattern "Intel|Dell|Program Files|Program Files (x86)|Windows|Windows.old|backup|Drivers|Perflogs" -notmatch

#Name:			ExtensionsToFilter
#Type:			Variable
#Purpose:		List of all extensions that should be scanned - you can add extensions to the array by simply adding ,'*.ext'
$ExtensionsToFilter = '*.doc','*.docx','*.txt','*.csv','*.pdf'

#Purpose:		On some machines this script seems to trigger a beep sound - This line should disable this ¯\_(ツ)_/¯
Set-PSReadlineOption -BellStyle None

#Name:			Test-Path
#Type:			If-Condition
#Purpose:		Simple validation if the output textfile exists - If it exists it will be cleared
#						If it doesn't exist it will be created to avoid issues when writing to the file later
if(Test-Path $OutputPath){
	"" | Out-File -filepath $OutputPath
}else{
	New-Item $OutputPath -ItemType File
}

#Name:			GetPIIResults
#Type:			Function
#Purpose:		This function will search through all files in every folders subfolder fetched by the FoldersToCheck variable
#				The regex pattern which will determine whether the information might be valuable or not will be selected by the input variable TypeToCheck
#				The results will then be written into the output textfile in the following format:
#				Path: <PathOfTheFileWhereAMatchWasMade> Row: <RowInTheFileWhereTheMatchWasMade> Type: <MatchType (e.g. IBAN)>
function GetPIIResults($PathToCheck, $TypeToCheck){

		#Selection of the desired regex pattern using the input variable TypeToCheck - Only input values below are accepted
        switch($TypeToCheck){
            "IBAN" {$RegexPattern = "^[a-zA-Z]{2}[0-9]{2}\s?[a-zA-Z0-9]{4}\s?[0-9]{4}\s?[0-9]{3}([a-zA-Z0-9]\s?[a-zA-Z0-9]{0,4}\s?[a-zA-Z0-9]{0,4}\s?[a-zA-Z0-9]{0,4}\s?[a-zA-Z0-9]{0,3})?$"}
            "Creditcard" {$RegexPattern = "^(?:4[0-9]{12}(?:[0-9]{3})?|(?:5[1-5][0-9]{2}|222[1-9]|22[3-9][0-9]|2[3-6][0-9]{2}|27[01][0-9]|2720)[0-9]{12}|3[47][0-9]{13}|3(?:0[0-5]|[68][0-9])[0-9]{11}|6(?:011|5[0-9]{2})[0-9]{12}|(?:2131|1800|35\d{3})\d{11})$"}
            "US-SSN" {$RegexPattern = "^\d{3}-\d{2}-\d{4}$"}
        }

		#This command will scan all items in each folder and subfolder input by the variable PathToCheck using findstr.exe and the selected regex pattern
		#In this example all log files have been excluded from the search to minimize false positives
        $RegexResults = Get-childitem $PathToCheck -Include $ExtensionsToFilter -Recurse | ?{ findstr.exe /mprc:. $_.FullName } | select-string $RegexPattern

		#Splits the data so that we can remove the content string and structure the output string
		$SplittedData = $RegexResults -split ':'

		#OutputData will be the string that will be written to the textfile
		$OutputData = "Path: "

		#This for-loop goes through all the elements in SplittedData It will not cycle through the last element since it cointains the matched string which we do not want to save
		#The first cycle will add the path to the file
		#The second cycle will add the row number where the match was made
        For($j=0;$j -lt ($SplittedData.Length - 1);$j++){
            if($j -ne ($SplittedData.Length - 2)){
                
                $OutputData += $SplittedData[$j]

            }else{

                $OutputData += " Row: " + $SplittedData[$j]
                break;
		    }
        }

		#Finally we will add the type that has been found (e.g. IBAN)
        $OutputData += " Type: " + $TypeToCheck

		#Now we will append the OutputData string to the OutputPath file as long as all the neccessary information could be stored using Add-Content
        if($SplittedData.Length -eq 4){
            Add-Content $OutputPath $OutputData
        }
}

#Name:			FoldersToCheck - Loop
#Type:			For-Loop
#Purpose:		This loop calls the GetPIIResults funtion for every non excluded folder found on the C: drive
for($i=0;$i -lt $FoldersToCheck.Length;$i++){
    $TargetedPath = "C:\" + $FoldersToCheck[$i] + "\"

    Write-Output "`nSearching for IBANs... in $($TargetedPath) `n"
    GetPIIResults $TargetedPath "IBAN"

    Write-Output "`nSearching for Creditcards... in $($TargetedPath) `n"
    GetPIIResults $TargetedPath "Creditcard"

	 	Write-Output "`nSearching for US-Social Security Numbers... in $($TargetedPath) `n"
    GetPIIResults $TargetedPath "US-SSN"
}
