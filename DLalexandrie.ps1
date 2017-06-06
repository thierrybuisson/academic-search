
# https://stackoverflow.com/questions/16575419/powershell-retrieve-json-object-by-field-value
$jsonConfigFile = "alexandrie.json"

$JSON = Get-Content $jsonConfigFile | Out-String | ConvertFrom-Json
foreach( $book in $JSON.entities ) {
    $bcontent = $book.E 
    foreach ($c in $bcontent){
$c
        $t = $c.DN
        $t

    }
    # write-host $bcontent
    
    # $bcontent.DN 
}