1.Introduction

PII information is scattered everywhere. In fact, if you were to go through your garbage, you would probably find some PII quite easily. Protecting this information requires diligence and a bit of care. I recommend that everyone invest in a good paper shredder and shred anything that has personal information on it.
But what about the PII lurking about on your PC? Finding this data can be as challenging as storing it securely. [Source](https://technet.microsoft.com/en-us/library/2008.04.securitywatch.aspx)

This script is designed to help you find important PII that is stored on the target computers drive. I have done my best to describe how the script works with comments in the script itself so please take a peek inside and see for yourself.

Feedback is always welcome since I am pretty new to the PowerShell game :)

2.Adapting the script

Adapting the script is very easy and the usage can be explained rather easy.
Here are the most important things you can adapt in order to use the script for your IT environment:

$OutputPath Variable
This variable needs to be changed to the location where you want the results of the script to be stored

How does the output look like ?

Here is an example on how the output might look like:

Path: C:\data\Payroll.csv Row: 56 Type: IBAN

Basically you will find a list where you can see the path where the script has made a match using the regex patterns and in which row the data was found. Additionally you will see what type of data was found to give you an overview over what the user potentially stores on his/her drive.

This can be a great indicator whether the user might potentially store PII on his device without having permission to do so - For example if someone from finance has a bunch of IBANs on their device that is understandable and no further action is required but if you find out that your janitor has multiple files with IBANs or social security numbers that might be an indicator that something shady is going on and needs to be checked.

######What kind of PII can be checked using this script out of the box ?
Currently there are working regex patterns to search for IBANs, Creditcards and US - Social Security Numbers.

Please note that there will most likely be false positives but I have tested those regex patterns and the amount of false positives should not be a factor while scanning for PII.

How do I add patterns ?

In the GetPIIResults function there is a switch-statement where you can find the regex patterns. Simply add a new row with your pattern.

```swift
switch($TypeToCheck){

        "IBAN" {$RegexPattern = "REGEX"}
        "Creditcard" {$RegexPattern = "REGEX"}
        "US-SSN" {$RegexPattern = "REGEX"}
	"New" {$RegexPattern = "YOURNEWREGEX"}
}
```

The only thing you have to do now is to call the GetPIIResults function in the for-loop at the end of the script with the $TypeToCheck string you have set - In this example that string would be “New”

```
GetPIIResults $TargetedPath "New"
```

Which files get checked ?

The file types that are being scanned are defined in the variable $ExtensionsToFilter
You can always remove or add file extensions to this variable in order to adapt the script to your needs. 

All folders on the C: drive that are not excluded in the $FoldersToCheck no match pattern will be screened (All folders and subfolders).

So make sure to also adapt the folders you do NOT want to screen in the $FoldersToCheck variable. The default folders which will not be checked are:

```
"Intel|Dell|Program Files|Program Files (x86)|Windows|Windows.old|backup|Drivers|Perflogs"
```

