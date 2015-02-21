xquery version "1.0-ml";

module namespace tr = "http://marklogic.com/rest-api/resource/wpaper";

import module namespace ssheet = "http://marklogic.com/roxy/lib/ssheet" at "/app/lib/spreadsheet.xqy";

declare namespace roxy = "http://marklogic.com/roxy";

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
  let $q   := map:get($params, "q")
  let $doc :=
    element { "response" }
    {
      element { "status" } { "Workpaper GET called" }
    }

  return
    document
    {
      $doc
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
      
  let $excelUri := "/template/C2903000/bin/C2903000.xlsx" (: $userDataDoc/tax:meta/tax:templateFile/text() :)
  
  let $user         := "janedoe0041"
  let $userExcelUri := "/user/"||$user||"/"||"test1"||fn:tokenize($excelUri, "/")[fn:last()]

  let $binDoc := ssheet:createSpreadsheetFile($userDataDoc)
  (:
  let $_      := xdmp:document-insert($userExcelUri, $binDoc, xdmp:default-permissions(), ("userspreadsheet"))
  :)
    
  let $response :=
    element { "response" }
    {
      element { "input" }
      {
        element { "uri" }  { $uri }
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
