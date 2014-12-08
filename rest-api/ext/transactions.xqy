xquery version "1.0-ml";

module namespace tr = "http://marklogic.com/rest-api/resource/transactions";

import module namespace admin = "http://marklogic.com/xdmp/admin" at "/MarkLogic/admin.xqy";

declare namespace roxy = "http://marklogic.com/roxy";

declare variable $NS := "http://tax.thomsonreuters.com";

(:~
 : Commit Transaction
 :
 : @param $txid as xs:string - upper string is the hostId lower string is the txId
 :)
declare function tr:commitTransaction($txid as xs:string)
{
  let $longHostId := xs:unsignedLong(fn:tokenize($txid,"_")[1])
  let $longTxId := xs:unsignedLong(fn:tokenize($txid,"_")[2])
  
  let $__ := xdmp:transaction-commit($longHostId, $longTxId)

  return "---> "||$txid
};

(:~
 : Rollback Transaction
 :
 : @param $txid as xs:string - upper string is the hostId lower string is the txId
 :)
declare function tr:rollbackTransaction($txid as xs:string)
{
  let $longHostId := xs:unsignedLong(fn:tokenize($txid,"_")[1])
  let $longTxId := xs:unsignedLong(fn:tokenize($txid,"_")[2])
  
  let $__ := xdmp:transaction-rollback($longHostId, $longTxId)

  return "---> "||$txid
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
  let $output := map:put($context, "output-types", "application/xml")

  let $config    := admin:get-configuration()
  let $transList := xdmp:host-status(admin:get-host-ids($config)[1])/*:transactions/*:transaction

  let $ids :=
      element { fn:QName($NS, "txids") }
      {
        for $doc in $transList
          order by $doc/*:transaction-state/text(), $doc/*:transaction-id/text()
            return
              element { fn:QName($NS, "txid") }
              {
                $doc/*:transaction-state/text()||": "||$doc/*:host-id/text()||"_"||$doc/*:transaction-id/text()
              }
      }

  return
    document
    {
      <status>{($ids, $transList)}</status>
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
  map:put($context, "output-types", "application/xml"),
  xdmp:set-response-code(200, "OK"),
  document
  {
    <status>PUT called on the ext service extension</status>
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
  let $output := map:put($context, "output-types", "application/xml")

  let $result := map:get($params, "result")
  let $txid   := map:get($params, "txid")

  let $config := admin:get-configuration()
  let $hostid := admin:get-host-ids($config)

  let $result := 
    if (fn:string-length($result) eq 0 and fn:string-length($txid) eq 0) then
    (
      $hostid||"_"||
      xdmp:transaction-create(
        <options xmlns="xdmp:eval">
          <transaction-mode>update</transaction-mode>
        </options>
      )
    )
    else
    if (fn:string-length($txid) gt 0 and fn:string-length($result) gt 0) then
    (
      if ($result eq "commit") then
        "Transaction Committed: "||tr:commitTransaction($txid)
      else
      if ($result eq "rollback") then
        "Transaction Rolled Back: "||tr:rollbackTransaction($txid)
      else
        "unknown operation"
    )
    else
      "Missing transaction-id and/or result"

  let $resultDoc := <result>{$result}</result>

  return
    document { $resultDoc }
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
  document
  {
    <status>DELETE called on the ext service extension</status>
  }
};
