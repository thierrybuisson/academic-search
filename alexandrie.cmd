@ECHO OFF
SET %subscriptionkey%="009ce6119a62464cbadd741eeb9b5a8f"
SET %exportfile%="output.json"

curl -v "https://westus.api.cognitive.microsoft.com/academic/v1.0/evaluate?expr=Or(W='astronomy',W='anatomy',W='animals',W='mathematics',W='physics',W='geometry',W='engineering',W='geography',W='physiology',W='medicine')&offset=0&count=100&attributes=Ti,Y,AA.AuN,C.CN,J.JN,E" -o "alexandrie.json" -H "Ocp-Apim-Subscription-Key:009ce6119a62464cbadd741eeb9b5a8f" 
