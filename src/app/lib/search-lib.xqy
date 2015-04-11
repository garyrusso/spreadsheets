xquery version "1.0-ml";

module namespace slib = "http://marklogic.com/roxy/lib/search-lib";

import module namespace ssheet = "http://marklogic.com/roxy/lib/ssheet" at "/app/lib/spreadsheet.xqy";
import module namespace ingest = "http://marklogic.com/roxy/lib/ingest" at "/app/lib/ingest.xqy";
import module namespace mem    = "http://xqdev.com/in-mem-update" at '/MarkLogic/appservices/utils/in-mem-update.xqy';
(: import module namespace json   = "http://marklogic.com/xdmp/json" at "/MarkLogic/json/json.xqy"; :)

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

  let $templateUri := slib:getTemplateUri($client, $templateId)/metadataUri/text()

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
declare function slib:getTemplateUri($client as xs:string, $id as xs:string)
{
  let $query := cts:and-query((
                  cts:collection-query(("spreadsheet")),
                  cts:element-value-query(fn:QName($NS, "templateId"), $id)
                ))
                
  let $results := cts:search(fn:doc(), $query)
  
  let $doc :=
    if (fn:count($results) gt 0) then
      element { "templateInfo" }
      {
        element { "binFileUri" } { $results[1]/tax:workbook/tax:meta/tax:file/text() },
        element { "metadataUri" } { xdmp:node-uri($results[1]) }
      }
    else
      element { "templateInfo" }
      {
        element { "binFileUri" } { "Template File does not exist" },
        element { "metadataUri" } { "Template Metadata File does not exist" }
      }

  return $doc
};

(:
 :)
declare function slib:formatResults($results as document-node()*)
{
  let $doc :=
    element { "list" }
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
  
  return slib:formatResults($results)
};

(:
 :)
declare function slib:getTemplateListByClient($client as xs:string)
{
  let $query := cts:and-query((
                  cts:collection-query(("spreadsheet")),
                  cts:element-value-query(fn:QName($NS, "client"), $client)
                ))
                
  let $results := cts:search(fn:doc(), $query)
  
  return slib:formatResults($results)
};

(:
 :)
declare function slib:searchTemplates($q as xs:string, $client as xs:string)
{
  let $query := cts:and-query((
                  cts:collection-query(("spreadsheet")),
                  cts:element-value-query(fn:QName($NS, "client"), $client),
                  cts:word-query($q)
                ))
                
  let $results := cts:search(fn:doc(), $query)
  
  return slib:formatResults($results)
};

