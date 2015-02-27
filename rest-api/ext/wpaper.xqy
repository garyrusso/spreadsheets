xquery version "1.0-ml";

module namespace tr = "http://marklogic.com/rest-api/resource/wpaper";

import module namespace ssheet = "http://marklogic.com/roxy/lib/ssheet" at "/app/lib/spreadsheet.xqy";

declare namespace roxy = "http://marklogic.com/roxy";
declare namespace tax  = "http://tax.thomsonreuters.com";
declare namespace xs   = "http://www.w3.org/2001/XMLSchema";

declare option xdmp:mapping "false";

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
(:
  let $outputTypes        := map:put($context,"output-types","application/x-download")
:)
  
  let $contentDisposition := xdmp:add-response-header("Content-Disposition", 'attachment; filename="workpaper.xlsx"')
  let $responseCode       := xdmp:set-response-code(300, "OK")
  
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
      "/user/janedoe0041/"||$id||".xml"
    else
      $tempUri

  let $txid :=
    if (fn:empty(map:get($params, "txid"))) then
      ""
    else
      map:get($params, "txid")
      
  let $userData := fn:doc($uri)
  
  let $binDoc := ssheet:createSpreadsheetFile($userData)
  
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
(:
  let $output-types := map:put($context,"output-types","application/xml")
  let $output-types := map:put($context,"output-types","application/vnd.openxmlformats-officedocument.spreadsheetml.sheet")
:)

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
(:
  let $excelUri :=
    if (fn:empty($userDataDoc)) then
      "/template/C2903000/bin/C2903000.xlsx"
    else
      $userDataDoc/tax:meta/tax:templateFile/text()
:)
  let $excelUri := $userDataDoc/tax:userData/tax:meta/tax:templateFile/text()
  
  let $user := "janedoe0041"
  let $uri  := "/user/"||$user||"/"||"test1"||fn:tokenize($excelUri, "/")[fn:last()]

  let $binDoc := ssheet:createSpreadsheetFile($userDataDoc)

  let $evalCmd :=
    fn:concat
    (
      'declare variable $uri external;
       declare variable $binDoc external;
       xdmp:document-insert($uri, $binDoc, xdmp:default-permissions(), ("userspreadsheet"))'
    )

  let $doc :=
    xdmp:eval(
      $evalCmd,
      (xs:QName("uri"), $uri, xs:QName("binDoc"), $binDoc)
	  )

  let $dataItemCount := fn:count($userDataDoc/tax:userData/tax:feed/tax:dnames/tax:dname/tax:value)

  let $response :=
    element { "response" }
    {
      element { "input" }
      {
        element { "tenplate" }  { $uri },
        element { "dataItemCount" }  { $dataItemCount }
      },
      element { "status" }
      {
        element { "elapsedTime" } { xdmp:elapsed-time() },
        element { "excelUri" } { $excelUri }
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
