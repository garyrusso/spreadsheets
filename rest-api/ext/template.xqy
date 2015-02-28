xquery version "1.0-ml";

module namespace tr = "http://marklogic.com/rest-api/resource/template";

import module namespace ingest = "http://marklogic.com/roxy/lib/ingest" at "/app/lib/ingest.xqy";

declare namespace roxy = "http://marklogic.com/roxy";

declare namespace tax = "http://tax.thomsonreuters.com";

declare variable $NS := "http://tax.thomsonreuters.com";

declare variable $OPTIONS as element () :=
                 <options xmlns="xdmp:zip-get">
                   <format>xml</format>
                 </options>;

(:
 :)
declare function tr:getTemplateUri($client as xs:string, $id as xs:string)
{
  let $query := cts:and-query((
                  cts:collection-query(("spreadsheet")),
                  cts:element-value-query(fn:QName($NS, "templateId"), $id)
                ))
                
  let $results := cts:search(fn:doc(), $query)
  
  return
    element { "templateInfo" }
    {
      element { "binFileUri" } { $results[1]/tax:workbook/tax:meta/tax:file/text() },
      element { "metadataUri" } { xdmp:node-uri($results[1]) }
    }
};

(:
 :)
declare function tr:formatResults($results as document-node()*)
{
  let $doc :=
    element { "templates" }
    {
      element { "count" } { fn:count($results/tax:workbook) },
      for $result in $results
        return
          element { "template" }
          {
            element { "templateId" } { $result/tax:workbook/tax:meta/tax:templateId/text() },
            element { "templateUri" } { $result/tax:workbook/tax:meta/tax:file/text() },
            element { "templateMetadataUri" } { xdmp:node-uri($result) },
            element { "user" } { $result/tax:workbook/tax:meta/tax:user/text() }
          }
    }

  return $doc
};

(:
 :)
declare function tr:getFullTemplateList()
{
  let $query := cts:and-query((
                  cts:collection-query(("spreadsheet"))
                ))
                
  let $results := cts:search(fn:doc(), $query)
  
  return tr:formatResults($results)
};

(:
 :)
declare function tr:getTemplateListByClient($client as xs:string)
{
  let $query := cts:and-query((
                  cts:collection-query(("spreadsheet")),
                  cts:element-value-query(fn:QName($NS, "client"), $client)
                ))
                
  let $results := cts:search(fn:doc(), $query)
  
  return tr:formatResults($results)
};

(:
 :)
declare function tr:getTemplateListUsingSearch($q as xs:string, $client as xs:string)
{
  let $query := cts:and-query((
                  cts:collection-query(("spreadsheet")),
                  cts:element-value-query(fn:QName($NS, "client"), $client),
                  cts:word-query($q)
                ))
                
  let $results := cts:search(fn:doc(), $query)
  
  return tr:formatResults($results)
};

(: 
 : To add parameters to the functions, specify them in the params annotations. 
 : Example
 :   declare %roxy:params("uri=xs:string", "priority=xs:int") tr:get(...)
 : This means that the get function will take two parameters, a string and an int.
 :)

(:
 :)
declare 
%roxy:params("id=xs:string", "q=xs:string", "start=xs:integer", "pageLength=xs:integer")
function tr:get(
  $context as map:map,
  $params  as map:map
) as document-node()*
{
  let $contentDisposition := xdmp:add-response-header("Content-Disposition", 'attachment; filename="workpaper.xlsx"')
  let $responseCode       := xdmp:set-response-code(300, "OK")

  let $id := map:get($params, "id")
  let $q  := map:get($params, "q")
  
  let $client := "ey001"  (: pull this from the auth token :)

  let $returnDoc :=
    if (fn:string-length($q) gt 0) then
      tr:getTemplateListUsingSearch($q, $client)
    else
    if (fn:string-length($id) gt 0) then
    (
      let $uri := tr:getTemplateUri($client, $id)/binFileUri/text()
      return
        if (fn:string-length($uri) gt 0) then
          fn:doc($uri)
        else
          <status>Invalid Template Id</status>
    )
    else
      tr:getTemplateListByClient($client)
  
  return
    document {
      try {
        $returnDoc
      } catch ($e) {
        element error { $e/error:message }
      }
    }
};

(:
 :)
declare 
%roxy:params("")
function tr:put(
    $context as map:map,
    $params  as map:map,
    $input   as document-node()*
) as document-node()?
{
  let $contentTypes := xdmp:add-response-header("output-types", 'application/xml')
  let $responseCode := xdmp:set-response-code(200, "OK")

  let $id := map:get($params, "id")

  (: pull this from the auth token :)
  let $client       := "ey001"
  let $userNum      := 42
  let $userPadNum   := ingest:padNum($userNum)
  let $user         := "janedoe"||$userPadNum
  let $userFullName := "Jane Doe "||$userNum

  let $binDocNew    :=  document { $input }

  let $templateInfo        := tr:getTemplateUri($client, $id)
  let $templateUri         := $templateInfo/binFileUri/text()
  let $templateMetadataUri := $templateInfo/metadataUri/text()

  let $binDocOrig          := fn:doc($templateUri)
  let $docOrig             := fn:doc($templateMetadataUri)
  let $origTemplateId      := $docOrig/tax:workbook/tax:meta/tax:templateId/text()
  let $docNew              := ingest:extractSpreadsheetData($client, $userFullName, $user, $templateUri, $origTemplateId, $binDocNew)

  let $__ := xdmp:node-replace($docOrig/tax:workbook, $docNew)
  let $__ := xdmp:node-replace($binDocOrig, $binDocNew)

(:
  let $evalCmd :=
    fn:concat
    (
      'declare variable $metaUri external;
       declare variable $doc external;
       declare variable $uri external;
       declare variable $binDoc external;
       xdmp:document-insert($metaUri, $doc, xdmp:default-permissions(), ("spreadsheet")),
       xdmp:document-insert($uri, $binDoc, xdmp:default-permissions(), ("binary"))'
    )

  let $doc :=
    xdmp:eval(
      $evalCmd,
      (xs:QName("metaUri"), $templateMetadataUri, xs:QName("doc"), $doc, xs:QName("uri"), $templateUri, xs:QName("binDoc"), $binDoc)
	  )
:)

  let $response :=
    element { "response" }
    {
      element { "input" }
      {
        element { "requestId" }  { $id }
        (: element { "dnameCount" } { fn:count($docNew/tax:feed/tax:definedNames/tax:definedName) } :)
      },
      element { "status" }
      {
        element { "notes" }               { "template and metadata has been updated" },
        element { "elapsedTime" }         { xdmp:elapsed-time() },
        element { "templateUri" }         { $templateUri },
        element { "templateMetadataUri" } { $templateMetadataUri }
      }
    }

  return
    document
    {
      $response
    }
};

(:
 :)
declare 
%roxy:params("")
function tr:post(
    $context as map:map,
    $params  as map:map,
    $input   as document-node()*
) as document-node()*
{
  let $contentTypes := xdmp:add-response-header("output-types", 'application/xml')
  let $responseCode := xdmp:set-response-code(200, "OK")

  let $id       := map:get($params, "id")
  let $filename := map:get($params, "filename")

  (: pull this from the auth token :)
  let $client       := "ey001"
  let $userNum      := 42
  let $userPadNum   := ingest:padNum($userNum)
  let $user         := "janedoe"||$userPadNum
  let $userFullName := "Jane Doe "||$userNum

  let $binDoc :=  document { $input }

  let $templateDir         := "/client/"||$client||"/template"
  let $doc                 := ingest:extractSpreadsheetData($client, $userFullName, $user, $templateDir, "", $binDoc)

  let $templateBinFileName  :=
    if (fn:string-length($filename) gt 0) then
      $filename
    else
      xdmp:hash64($doc)
  
  let $templateMetadataDir := $templateDir||"/"||$templateBinFileName

  let $templateMetadataUri := $templateMetadataDir||"/"||$templateBinFileName||".xml"
  let $templateBinFileUri  := $templateMetadataDir||"/bin/"||$templateBinFileName||".xlsx"

  let $evalCmd :=
    fn:concat
    (
      'declare variable $metaUri external;
       declare variable $doc external;
       declare variable $uri external;
       declare variable $binDoc external;
       xdmp:document-insert($metaUri, $doc, xdmp:default-permissions(), ("spreadsheet")),
       xdmp:document-insert($uri, $binDoc, xdmp:default-permissions(), ("binary"))'
    )

  let $evalDoc :=
    xdmp:eval(
      $evalCmd,
      (xs:QName("metaUri"), $templateMetadataUri, xs:QName("doc"), $doc, xs:QName("uri"), $templateBinFileUri, xs:QName("binDoc"), $binDoc)
    )

  let $response :=
    element { "response" }
    {
      element { "input" }
      {
        element { "dnameCount" } { fn:count($doc/tax:feed/tax:definedNames/tax:definedName) }
      },
      element { "status" }
      {
        element { "elapsedTime" }         { xdmp:elapsed-time() },
        element { "templateBinFileUri" }  { $templateBinFileUri },
        element { "templateMetadataUri" } { $templateMetadataUri }
      }
    }

  return
    document
    {
      $response
    }
};

(:
 :)
declare 
%roxy:params("")
function tr:delete(
    $context as map:map,
    $params  as map:map
) as document-node()?
{
  map:put($context, "output-types", "application/xml"),
  xdmp:set-response-code(200, "OK"),
  document { "DELETE called on the ext service extension" }
};
