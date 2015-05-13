xquery version "1.0-ml";

import module namespace ingest = "http://marklogic.com/roxy/lib/ingest" at "/app/lib/ingest.xqy";

declare namespace ssml    = "http://schemas.openxmlformats.org/spreadsheetml/2006/main";

declare variable $metaUri        as xs:string external;
declare variable $wkSheet        as item()    external;
declare variable $wkSheetType    as xs:string external;
declare variable $client         as xs:string external;
declare variable $userFullName   as xs:string external;
declare variable $user           as xs:string external;
declare variable $version        as xs:string external;
declare variable $workPaperId    as xs:string external;
declare variable $binFileUri     as xs:string external;
declare variable $origTemplateId as xs:string external;
declare variable $wkBook         as item()    external;
declare variable $rels           as item()    external;
declare variable $table          as map:map   external;

declare variable $NS := "http://tax.thomsonreuters.com";

let $sheetName  := $wkSheet/@name/fn:string()

let $log := xdmp:log(" 1............. $sheetName:    "||$sheetName)

let $doc := ingest:createWorkSheetMetadoc(
              $wkSheet,
              $wkSheetType,
              $client,
              $userFullName,
              $user,
              $version,
              $workPaperId,
              $binFileUri,
              $origTemplateId,
              $wkBook,
              $rels,
              $table
            )

let $docInsert := xdmp:document-insert($metaUri, $doc, xdmp:default-permissions(), ("worksheet"))

let $retDoc :=
  element { fn:QName($NS, "status") }
  {
    element { fn:QName($NS, "elapsedTime") } { xdmp:elapsed-time() },
    element { fn:QName($NS, "metaDocUri") } { $metaUri }
  }
  
return $retDoc

