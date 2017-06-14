

function CleanJsonFlux($strin){
    $sout = $strin.ToString().Replace("The","_The")
    $sout = $sout.ToString().Replace("We","_We")
    $sout = $sout.ToString().Replace("Oriented","_Oriented")
    $sout = $sout.ToString().Replace("This","_This")
    
    return $sout

}

# https://stackoverflow.com/questions/16575419/powershell-retrieve-json-object-by-field-value
$jsonConfigFile = "alexandrie.json"
$JSON = $(Get-Content $jsonConfigFile) | Out-string | ConvertFrom-Json
foreach( $book in $JSON.entities ) {
    $bcontent = $book
    $year = $bcontent.Y
    $title = $bcontent.Ti
$title
    $description = $bcontent.E
#   $description
[regex]::Matches([string]$description,'(?<=")(.+)(?=":)') |
foreach {
    $_.groups[1].value
}
# $description 
    # $description 
 
#  $description  | ConvertFrom-Json
     
    # $bcontent.DN 
}

