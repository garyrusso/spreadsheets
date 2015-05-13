xquery version "1.0-ml";

module namespace slib = "http://marklogic.com/roxy/lib/search-lib";

import module namespace ssheet = "http://marklogic.com/roxy/lib/ssheet" at "/app/lib/spreadsheet.xqy";
import module namespace ingest = "http://marklogic.com/roxy/lib/ingest" at "/app/lib/ingest.xqy";
import module namespace mem    = "http://xqdev.com/in-mem-update" at '/MarkLogic/appservices/utils/in-mem-update.xqy';
(: import module namespace json   = "http://marklogic.com/xdmp/json" at "/MarkLogic/json/json.xqy"; :)

import module namespace search = "http://marklogic.com/appservices/search" at "/MarkLogic/appservices/search/search.xqy";
import module namespace c      = "http://marklogic.com/roxy/config" at "/app/config/config.xqy";

declare namespace tax  = "http://tax.thomsonreuters.com";

declare namespace zip     = "xdmp:zip";

declare variable $NS := "http://tax.thomsonreuters.com";

declare variable $OPTIONS as element () :=
                 <options xmlns="xdmp:zip-get">
                   <format>xml</format>
                 </options>;

(:
 :)
declare function slib:createUserDataDoc($client as xs:string, $user as xs:string, $templateId as xs:string, $origUserDataID as xs:string, $jDnames as item()*)
{
  let $dnames      := () (: json:transform-from-json($jDnames) :)

  let $templateUri := slib:getTemplateUriByTemplateId($client, $templateId)/metadataUri/text()

  let $fullName         := ingest:getUserFullName()
  let $userFullName     := $fullName/firstName/text()||" "||$fullName/lastName/text()
  
  let $doc :=
    element { fn:QName($NS, "userData") }
    {
      element { fn:QName($NS, "meta") }
      {
        element { fn:QName($NS, "type") }        { "user data" },
        element { fn:QName($NS, "client") }      { $client },
        element { fn:QName($NS, "user") }        { $userFullName },
        element { fn:QName($NS, "userDataId") }  { $origUserDataID },
        element { fn:QName($NS, "templateId") }  { $templateId },
        element { fn:QName($NS, "templateUri") } { $templateUri },
        element { fn:QName($NS, "modified") }    { fn:current-dateTime() }
      },
      element { fn:QName($NS, "feed") }
      {
        element { fn:QName($NS, "dnames") }
        {
          for $dn in $dnames/*:dnames/*:json
            return
              element { fn:QName($NS, "dname") }
              {
                element { fn:QName($NS, "name") }  { $dn/*:name/text() },
                element { fn:QName($NS, "value") } { $dn/*:value/text() }
              }
        }
      }
    }

  let $userDataId :=
    if (fn:string-length($origUserDataID) gt 0) then
      $origUserDataID
    else
      xdmp:hash64($doc)

  let $newUserDataIdNode  := element {fn:QName($NS, "userDataId")} { $userDataId }
  
  let $newDoc := mem:node-replace($doc/tax:meta/tax:userDataId, $newUserDataIdNode)
  
  return $newDoc
};

(:
 :)
declare function slib:getTemplateUriByTemplateId($client as xs:string, $templateId as xs:string)
{
  let $query := cts:and-query((
                  cts:collection-query(("spreadsheet")),
                  cts:element-value-query(fn:QName($NS, "type"), "template"),
                  cts:element-value-query(fn:QName($NS, "client"), $client),
                  cts:element-value-query(fn:QName($NS, "templateId"), $templateId)
                ))
                
  let $results := cts:search(fn:doc(), $query)

  let $doc := slib:formatResults($results)

  return $doc
};

(:
 :)
declare function slib:getWorkpaperByWorkpaperId($client as xs:string, $workPaperId as xs:string)
{
  let $query := cts:and-query((
                  cts:collection-query(("workbook")),
                  cts:element-value-query(fn:QName($NS, "type"), "wpaper"),
                  cts:element-value-query(fn:QName($NS, "client"), $client),
                  cts:element-value-query(fn:QName($NS, "workPaperId"), $workPaperId)
                ))

  let $results := cts:search(fn:doc(), $query)
  
  let $doc := slib:formatResults($results)

  return $doc
};

(:
 :)
declare function slib:formatResults($results)
{
  let $doc :=
    if (fn:count($results) gt 0) then
      element { "info" }
      {
        element { "templateId" }    { $results[1]/tax:workbook/tax:meta/tax:templateId/text() },
        element { "workPaperId" }   { $results[1]/tax:workbook/tax:meta/tax:workPaperId/text() },
        element { "client" }        { $results[1]/tax:workbook/tax:meta/tax:client/text() },
        element { "userFullName" }  { $results[1]/tax:workbook/tax:meta/tax:userFullName/text() },
        element { "user" }          { $results[1]/tax:workbook/tax:meta/tax:user/text() },
        element { "fileName" }      { $results[1]/tax:workbook/tax:meta/tax:fileName/text() },
        element { "version" }       { $results[1]/tax:workbook/tax:meta/tax:version/text() },
        element { "binFileUri" }    { $results[1]/tax:workbook/tax:meta/tax:file/text() },
        element { "metadataUri" }   { xdmp:node-uri($results[1]) },
        element { "workSheetUris" } {
          for $uri in $results[1]/tax:workbook/tax:workBookMap/tax:workSheet
            return
              element { "workSheet" } {
                element { "name" } { $uri/tax:name/text() },
                element { "uri" } { $uri/tax:uri/text() }
              }
        }
      }
    else
      element { "info" }
      {
        element { "templateId" }    { "No document found" },
        element { "workPaperId" }   { "" },
        element { "client" }        { "" },
        element { "userFullName" }  { "" },
        element { "user" }          { "" },
        element { "fileName" }      { "" },
        element { "version" }       { "" },
        element { "binFileUri" }    { "" },
        element { "metadataUri" }   { "" },
        element { "workSheetUris" } { "" }
      }
      
  return $doc
};

(:
 :)
declare function slib:formatSearchResults($response)
{
  let $results := $response/search:result

  let $doc :=
    element { "list" }
    {
      element { "count" } { xs:string($response/@total) },
      for $result in $results
        return
          element { "workPaper" }
          {
            element { "workPaperId" } { $result/search:snippet/tax:workPaperId/text() },
            element { "user" }        { $result/search:snippet/tax:user/text() },
            element { "type" }        { $result/search:snippet/tax:type/text() },
            element { "uri" }         { xs:string($result/@uri) }
          }
    }

  return $doc
};

(:
 :)
declare function slib:formatListResults($results as document-node()*)
{
  let $doc :=
    element { "list" }
    {
      element { "count" } { fn:count($results/tax:worksheet) },
      for $result in $results
        return
          element { "result" }
          {
            element { "templateId" }          { $result/tax:worksheet/tax:meta/tax:templateId/text() },
            element { "workPaperId" }         { $result/tax:worksheet/tax:meta/tax:workPaperId/text() },
            element { "templateUri" }         { $result/tax:worksheet/tax:meta/tax:file/text() },
            element { "templateMetadataUri" } { xdmp:node-uri($result) },
            element { "client" }              { $result/tax:worksheet/tax:meta/tax:client/text() },
            element { "user" }                { $result/tax:worksheet/tax:meta/tax:user/text() },
            element { "version" }             { $result/tax:worksheet/tax:meta/tax:version/text() }
          }
    }

  return $doc
};

(:
 :)
declare function slib:getTemplateName($templateId as xs:string)
{
  let $query := cts:and-query((
                  cts:collection-query(("spreadsheet")),
                  cts:element-value-query(fn:QName($NS, "templateId"), $templateId)
                ))
                
  let $results := cts:search(fn:doc(), $query)
  
  return
    fn:tokenize($results[1]/*:workbook/*:meta/*:file/text(), "/")[fn:last()-1]
};

(:
 :)
declare function slib:getFullTemplateList()
{
  let $query := cts:and-query((
                  cts:collection-query(("spreadsheet"))
                ))
                
  let $results := cts:search(fn:doc(), $query)
  
  return slib:formatListResults($results)
};

(:
 :)
declare function slib:getTemplateListByClient($client as xs:string)
{
  let $results := slib:getSpreadsheetListByClient($client, "template")
  
  return slib:formatListResults($results)
};

(:
 :)
declare function slib:getWorkpaperListByClient($client as xs:string)
{
  let $results := slib:getSpreadsheetListByClient($client, "wsheet")
  
  return slib:formatListResults($results)
};

(:
 :)
declare function slib:getSpreadsheetListByClient($client as xs:string, $type)
{
  let $query := cts:and-query((
                  cts:collection-query(("worksheet")),
                  cts:element-value-query(fn:QName($NS, "type"), $type),
                  cts:element-value-query(fn:QName($NS, "client"), $client)
                ))
                
  let $results := cts:search(fn:doc(), $query)

  return $results
};

declare function slib:getWorkpaperListByClientByQstring1($client as xs:string, $q as xs:string)
{
  let $query := cts:and-query((
                  cts:collection-query(("spreadsheet")),
                  cts:element-value-query(fn:QName($NS, "type"), "wpaper"),
                  cts:element-value-query(fn:QName($NS, "client"), $client),
                  cts:word-query($q)
                ))
                
  let $results := cts:search(fn:doc(), $query)
  
  return slib:formatListResults($results)
};

declare function slib:getWorkpaperListByClientByQstring($client as xs:string, $q as xs:string, $start as xs:unsignedLong?, $pageLength as xs:unsignedLong?)
{
  let $options := $c:REST-SEARCH-OPTIONS

  let $response := search:search($q, $options, $start, $pageLength)

  return
    slib:formatSearchResults($response)
};

(:
declare function slib:searchTemplates($q as xs:string, $client as xs:string)
{
  let $query := cts:and-query((
                  cts:collection-query(("spreadsheet")),
                  cts:element-value-query(fn:QName($NS, "client"), $client),
                  cts:word-query($q)
                ))
                
  let $results := cts:search(fn:doc(), $query)
  
  return slib:formatListResults($results)
};
 :)

