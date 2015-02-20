xquery version "1.0-ml";

import module namespace ingest = "http://marklogic.com/roxy/lib/ingest" at "/app/lib/ingest.xqy";
import module namespace ssheet = "http://marklogic.com/roxy/lib/ssheet" at "/app/lib/spreadsheet.xqy";

declare variable $page       as xs:string external;
declare variable $pagesize   as xs:string external;
declare variable $userid     as xs:string external;


let $pg      := xs:integer($page)
let $ps      := xs:integer($pagesize)
let $userNum := xs:integer($userid)

let $start := (($pg - 1) * $ps) + 1
let $end   := $pg * $ps

let $userDir := "/tmp/users/template/"
let $zipFile := ingest:loadDirectory($userDir) [1]

let $padUserNum := ingest:padNum($userNum)

let $docs :=
  for $nDoc in ($start to $end)
    let $user := "janedoe"||$padUserNum
    let $userFullName := "Jane Doe "||$padUserNum
    let $dir     := "/user/"||$user||"/"
    
    let $fileUri := ingest:generateFileUri($user, $zipFile, $nDoc)
    let $filingDate := ingest:getFilingDate()
    let $binDoc  := ssheet:createSpreadsheetFile($userFullName, $filingDate/days/text(), $fileUri)
    let $newDoc  := ingest:extractSpreadsheetData($user, $binDoc, $fileUri)

(:
    let $binDoc  := ssheet:createSpreadsheetFile($userFullName, $filingDate/days/text(), $fileUri, $taxPlanDoc)
    let $newDoc  := ingest:extractSpreadsheetData($userFullName, $user, $binDoc, $taxRate, $deductionPct, $totalGrossInc, $taxableInc, $filingDate/isoDate/text(), $fileUri)
:)

    let $uri     := $dir||xdmp:hash64($newDoc)||".xml"
    let $log     := xdmp:log("111 ------ $fileUri: "||$fileUri)
    
      return
      (
        $fileUri,
        xdmp:document-insert($uri, $newDoc, xdmp:default-permissions(), ("spreadsheet")),
        xdmp:document-insert($fileUri, $binDoc, xdmp:default-permissions(), ("binary"))
      (:
        xdmp:document-insert($uri, $doc, xdmp:default-permissions(), ("spreadsheet")),
        xdmp:document-insert($fileUri, $binDoc, xdmp:default-permissions(), ("binary"))
      :)
      )

return fn:count($docs)
