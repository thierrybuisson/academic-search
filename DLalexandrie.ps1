
# https://stackoverflow.com/questions/16575419/powershell-retrieve-json-object-by-field-value
$jsonConfigFile = "alexandrie.json"
$jsoncontent = $(Get-Content $jsonConfigFile).Replace('\"','"')
$JSON = $jsoncontent  | ConvertFrom-Json
foreach( $book in $JSON.entities ) {
    $bcontent = $book.E 

   $i = $bcontent[0]
   $i
   write-host ""
    # foreach ($c in $bcontent){
    #     $c.DN
    #     $t = $c  | ConvertFrom-Json
    #     # $t

    # }
    # write-host $bcontent
    
    # $bcontent.DN 
}