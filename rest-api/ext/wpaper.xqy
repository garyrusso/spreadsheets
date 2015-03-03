xquery version "1.0-ml";

module namespace tr = "http://marklogic.com/rest-api/resource/wpaper";

import module namespace ssheet = "http://marklogic.com/roxy/lib/ssheet" at "/app/lib/spreadsheet.xqy";
import module namespace ingest = "http://marklogic.com/roxy/lib/ingest" at "/app/lib/ingest.xqy";
import module namespace mem    = "http://xqdev.com/in-mem-update" at '/MarkLogic/appservices/utils/in-mem-update.xqy';
import module namespace json   = "http://marklogic.com/xdmp/json" at "/MarkLogic/json/json.xqy";

declare namespace roxy = "http://marklogic.com/roxy";
declare namespace tax  = "http://tax.thomsonreuters.com";
declare namespace xs   = "http://www.w3.org/2001/XMLSchema";

declare variable $NS := "http://tax.thomsonreuters.com";

declare option xdmp:mapping "false";

(:
 :)
declare function tr:formatResults($results as document-node()*)
{
  let $doc :=
    element { "list" }
    {
      element { "count" } { fn:count($results/tax:userData) },
      for $result in $results
        return
          element { "userData" }
          {
            element { "id" }          { $result/tax:userData/tax:meta/tax:userDataId/text() },
            element { "templateId" }  { $result/tax:userData/tax:meta/tax:templateId/text() },
            element { "dataUri" }     { xdmp:node-uri($result) },
            element { "templateUri" } { $result/tax:userData/tax:meta/tax:templateUri/text() },
            element { "user" }        { $result/tax:userData/tax:meta/tax:user/text() }
          }
    }

  return $doc
};

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
declare function tr:getUserDataList($client as xs:string)
{
  let $query := cts:and-query((
                  cts:collection-query(("userdata"))
                ))
                
  let $results := cts:search(fn:doc(), $query)

  return
    tr:formatResults($results)
};

declare function tr:searchUserData($q as xs:string, $client as xs:string)
{
  let $query := cts:and-query((
                  cts:collection-query(("userdata")),
                  cts:element-value-query(fn:QName($NS, "client"), $client),
                  cts:word-query($q)
                ))
                
  let $results := cts:search(fn:doc(), $query)
  
  return tr:formatResults($results)
};

(:
 :)
declare function tr:getUserDataById($client as xs:string, $id as xs:string)
{
  let $query := cts:and-query((
                  cts:collection-query(("userdata")),
                  cts:element-value-query(fn:QName($NS, "userDataId"), $id)
                ))
                
  let $results := cts:search(fn:doc(), $query)
  
  return
    element { "userDataInfo" }
    {
      element { "binFileUri" } { $results[1]/tax:userData/tax:meta/tax:templateFile/text() },
      element { "uri" } { xdmp:node-uri($results[1]) }
    }
};

declare function tr:getUserFullName($client as xs:string, $user as xs:string)
{
  let $userNum      := "41"
  let $userFullName := "Jane Doe "||$userNum

  let $userPadNum   := ingest:padNum(xs:integer($userNum))
  let $revisedUser  := $user||$userPadNum
  
  return $userFullName
};

declare function tr:createUserDataDoc($client as xs:string, $user as xs:string, $templateId as xs:string, $dnames as item()*)
{
  let $templateUri := tr:getTemplateUri($client, $templateId)/metadataUri/text()

  let $doc :=
    element { fn:QName($NS, "userData") }
    {
      element { fn:QName($NS, "meta") }
      {
        element { fn:QName($NS, "type") }        { "user data" },
        element { fn:QName($NS, "client") }      { $client },
        element { fn:QName($NS, "user") }        { tr:getUserFullName($client, $user) },
        element { fn:QName($NS, "userDataId") }  { "pending" },
        element { fn:QName($NS, "templateId") }  { $templateId },
        element { fn:QName($NS, "templateUri") } { $templateUri },
        element { fn:QName($NS, "modified") }    { "2015-10-08T18:21:48Z" }
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

  let $userDataId := xdmp:hash64($doc)
  
  let $newUserDataIdNode  := element {fn:QName($NS, "userDataId")} { $userDataId }
  
  let $newDoc := mem:node-replace($doc/tax:meta/tax:userDataId, $newUserDataIdNode)
  
  return $newDoc
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
%roxy:params("")
function tr:get(
  $context as map:map,
  $params  as map:map
) as document-node()*
{
  let $contentDisposition := xdmp:add-response-header("Content-Disposition", 'attachment; filename="workpaper.xlsx"')
  let $responseCode       := xdmp:set-response-code(300, "OK")

  (: GR001 - Get client and user id from token :)
  let $client := "ey001"
  let $user   := "janedoe"
  
  let $merge :=
    if (fn:empty(map:get($params, "merge"))) then
      ""
    else
      map:get($params, "merge")

  let $tempUri :=
    if (fn:empty(map:get($params, "uri"))) then
      ""
    else
      map:get($params, "uri")

  let $id :=
    if (fn:empty(map:get($params, "id"))) then
      ""
    else
      map:get($params, "id")

  let $uri :=
    if (fn:string-length($id) gt 0) then
      tr:getUserDataById($client, $id)/uri/text()
    else
      $tempUri

  let $log := xdmp:log("1 ----- User Workpaper Uri: "||$uri)
  let $log := xdmp:log("2 ----- User Workpaper Id:  "||$id)

  let $binDoc :=
    if (fn:string-length($id) gt 0) then
    (
      if (fn:lower-case($merge) eq "false") then
        fn:doc($uri)
      else
        ssheet:createSpreadsheetFile(fn:doc($uri))
    )
    else
    (
      tr:getUserDataList($client)
    )

  return
    document {
      try {
        $binDoc
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
  let $output-types := map:put($context,"output-types","application/xml")

  let $userDataDoc :=  document { $input }

  let $uri :=
    if (fn:empty(map:get($params, "uri"))) then
      ""
    else
      map:get($params, "uri")
      
  let $txid :=
    if (fn:empty(map:get($params, "txid"))) then
      ""
    else
      map:get($params, "txid")

  return
    document
    {
      $userDataDoc
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
  let $output-types := map:put($context,"output-types","application/xml")

  (: GR001 - Get client and user id from token :)
  let $client := "ey001"
  let $user   := "janedoe0041"

  let $id          := map:get($params, "templateId")
  
  let $jUserDataDoc :=  document { $input }

  (: Convert json to xml :)
  let $userDataDoc  := json:transform-from-json($jUserDataDoc)
  
  let $doc := tr:createUserDataDoc($client, $user, $id, $userDataDoc)

  let $log := xdmp:log("1 ----- userDataId: "||$doc/tax:meta/tax:userDataId/text())

  let $uri  := "/client/"||$client||"/user/"||$user||"/"||$doc/tax:meta/tax:userDataId/text()||".xml"

  let $evalCmd :=
    fn:concat
    (
      'declare variable $uri external;
       declare variable $doc external;
       xdmp:document-insert($uri, $doc, xdmp:default-permissions(), ("userdata"))'
    )

  let $evalDoc :=
    xdmp:eval(
      $evalCmd,
      (xs:QName("uri"), $uri, xs:QName("doc"), $doc)
	  )

  let $dataItemCount := fn:count($userDataDoc/*:dnames/*:json)

  let $response :=
    element { "response" }
    {
      element { "input" }
      {
        element { "dataItemCount" }  { $dataItemCount }
      },
      element { "status" }
      {
        element { "elapsedTime" } { xdmp:elapsed-time() },
        element { "client" }      { $client },
        element { "user" }        { $user },
        element { "id" }          { $id },
        element { "templateUri" } { $doc/tax:meta/tax:templateUri/text() },
        element { "userDataUri" } { $uri }
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
  let $contentTypes := xdmp:add-response-header("output-types", 'application/xml')
  let $responseCode := xdmp:set-response-code(200, "OK")

  let $id := map:get($params, "id")
  
  (: Get the client and user info from the OAuth2 token :)
  let $client := "ey001"

  let $status :=
    if (fn:string-length($id) gt 0) then
      "Deleted Template Id: "||$id
    else
      "Invalid Template Id"

  let $uri := tr:getUserDataById($client, $id)/uri/text()
  
  let $__ := xdmp:document-delete($uri)

  let $response :=
    element { "response" }
    {
      element { "input" }
      {
        element { "requestId" }  { $id }
      },
      element { "status" }
      {
        element { "elapsedTime" } { xdmp:elapsed-time() },
        element { "status" }      { $status },
        element { "uri" } { $uri }
      }
    }

  return
    document
    {
      $response
    }
};
