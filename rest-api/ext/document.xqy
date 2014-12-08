xquery version "1.0-ml";

module namespace tr = "http://marklogic.com/rest-api/resource/document";

declare namespace roxy = "http://marklogic.com/roxy";

declare namespace tax = "http://tax.thomsonreuters.com";

declare variable $NS := "http://tax.thomsonreuters.com";

declare variable $CONTENT-DIR := "/test/";

declare variable $TIDY-OPTIONS as element () :=
                 <options xmlns="xdmp:tidy">
                   <input-xml>yes</input-xml>
                 </options>;

(:~
 : Centralized Logging
 :
 : @param $file
 : @param $message
 :)
declare function tr:log($file as xs:string, $level as xs:string, $message as xs:string)
{
  let $idateTime := xs:string(fn:current-dateTime())
  let $dateTime  := fn:substring($idateTime, 1, fn:string-length($idateTime)-6)

  return
    xdmp:log(fn:concat("1..... LOGGING $file: ", $file, " | dateTime: ", $dateTime, " | level: ", $level, " | message: ", $message))
};

(:~
 : Get Document Helper Function
 :
 : @param $uri
 : @param $txid
 :)
declare function tr:getDocument($uri as xs:string, $txid  as xs:string) as document-node()*
{
  let $longHostId := xs:unsignedLong(fn:tokenize($txid,"_")[1])
  let $longTxId := xs:unsignedLong(fn:tokenize($txid,"_")[2])

  let $evalCmd :=
        fn:concat
        (
          'declare variable $uri external;
           fn:doc($uri)'
        )

  let $doc :=
    if (fn:string-length($txid) gt 0) then
    (
      xdmp:eval(
        $evalCmd,
        (xs:QName("uri"), $uri),
  		  <options xmlns="xdmp:eval">
  		    <transaction-id>{$longTxId}</transaction-id>
  		  </options>
		  )
    )
    else
      fn:doc($uri)

  return $doc
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
%roxy:params("uri=xs:string", "txid=xs:string")
function tr:get(
  $context as map:map,
  $params  as map:map
) as document-node()*
{
  let $output-types := map:put($context,"output-types","application/xml")

  let $uri  := map:get($params, "uri")
  let $txid :=
    if (fn:empty(map:get($params, "txid"))) then
      ""
    else
      map:get($params, "txid")

  let $doc := tr:getDocument($uri, $txid)

  return
    if (fn:empty($doc)) then
      document {
        <status>Document does not exist</status>
      }
    else
      document { $doc }
};

(:
 :)
declare 
%roxy:params("uri=xs:string", "document=payload")
function tr:put(
    $context as map:map,
    $params  as map:map,
    $input   as document-node()*
) as document-node()?
{
  let $output-types := map:put($context,"output-types","application/xml")

  let $revisedDoc :=  document { $input }

  let $uri := map:get($params, "uri")
  let $txid :=
    if (fn:empty(map:get($params, "txid"))) then
      ""
    else
      map:get($params, "txid")

  let $longHostId := xs:unsignedLong(fn:tokenize($txid,"_")[1])
  let $longTxId := xs:unsignedLong(fn:tokenize($txid,"_")[2])

  let $doc := tr:getDocument($uri, $txid)

  let $evalCmd :=
        fn:concat
        (
          'declare variable $uri external;
           declare variable $revisedDoc external;
           xdmp:document-insert($uri, $revisedDoc, xdmp:default-permissions(), ("RESTful"))'
        )

  return
    if (fn:empty($doc)) then
      document {
        <status>Document does not exist</status>
      }
    else
    (
      if (fn:not(fn:empty($revisedDoc/node()))) then
        try
        {
          if (fn:empty($longTxId)) then
          (
            xdmp:document-insert($uri, $revisedDoc, xdmp:default-permissions(), ("RESTful"))
          )
          else
          (
            xdmp:eval
            (
              $evalCmd,
              (xs:QName("uri"), $uri, xs:QName("revisedDoc"), $revisedDoc),
        		  <options xmlns="xdmp:eval">
        		    <transaction-id>{$longTxId}</transaction-id>
        		  </options>
            )
          ),
          tr:log($uri, "INFO", fn:concat("INFO: Document was updated: ", $uri)),
          document {
            <status>{fn:concat("Update Success: ", $uri)}</status>
          }
        }
        catch ($e)
        {
          tr:log($uri, "ERROR", $e/error:message/text())
        }
        else
          document {
            <status>Input Error</status>
          }
    )
};

(:
 :)
declare
%roxy:params("document=payload")
function tr:post(
    $context as map:map,
    $params  as map:map,
    $input   as document-node()*
) as document-node()*
{
  let $output-types := map:put($context,"output-types","application/xml")

  let $doc :=  document { $input } (: xdmp:tidy(document { $input }, $TIDY-OPTIONS) [2] :)

  let $txid :=
    if (fn:empty(map:get($params, "txid"))) then
      ""
    else
      map:get($params, "txid")

  let $longHostId := xs:unsignedLong(fn:tokenize($txid,"_")[1])
  let $longTxId := xs:unsignedLong(fn:tokenize($txid,"_")[2])

  let $rootName := fn:local-name-from-QName(fn:node-name($doc/child::element()))
  
  let $dir := if (fn:string-length($rootName) eq 0) then $CONTENT-DIR else "/"||$rootName||"/"
  
  let $uri := fn:concat($dir, xdmp:hash64($doc), xdmp:random(), ".xml")

  let $log := tr:log($uri, "INFO", "--------------"||$uri)
  
  (: Add createdAt and updatedAt code :)
  let $log := tr:log($uri, "INFO createdAt", "--------------"||$doc//*:createdAt/text())
  let $log := tr:log($uri, "INFO updatedAt", "--------------"||$doc//*:updatedAt/text())
  let $log := tr:log($longTxId, "INFO $txId", "--------------"||$longTxId)
  
  (: let $__ := xdmp:node-replace($doc//*:updatedAt, ) :)

  let $evalCmd :=
        fn:concat
        (
          'declare variable $doc external;
           xdmp:document-insert($uri, $doc, xdmp:default-permissions(), ("RESTful"))'
        )

  return
    if (fn:not(fn:empty($doc/node()))) then
        try
        {
          if (fn:empty($longTxId)) then
          (
            xdmp:document-insert($uri, $doc, xdmp:default-permissions(), ("RESTful"))
          )
          else
          (
            xdmp:eval
            (
              $evalCmd,
              (xs:QName("uri"), $uri, xs:QName("doc"), $doc),
        		  <options xmlns="xdmp:eval">
        		    <transaction-id>{$longTxId}</transaction-id>
        		  </options>
            )
          ),
          tr:log($uri, "INFO", fn:concat("INFO: Document was updated: ", $uri)),
          document {
            <status>{fn:concat("Update Success: ", $uri)}</status>
          }
        }
        catch ($e)
        {
          tr:log($uri, "ERROR", $e/error:message/text())
        }
        else
          document {
            <status>Input Error</status>
          }
};

(:
 :)
declare 
%roxy:params("uri=xs:string")
function tr:delete(
    $context as map:map,
    $params  as map:map
) as document-node()?
{
  let $output-types := map:put($context,"output-types","application/xml")

  let $uri := map:get($params, "uri")
  let $doc := fn:doc($uri)

  return
    if (fn:empty($doc)) then
      document {
        <status>Document does not exist</status>
      }
    else
      try
      {
        xdmp:document-delete($uri),
        tr:log($uri, "INFO", fn:concat("INFO: Document was deleted: ", $uri)),
        document {
          <status>{fn:concat("Delete Success: ", $uri)}</status>
        }
      }
      catch ($e)
      {
        tr:log($uri, "ERROR", $e/error:message/text())
      }
};
