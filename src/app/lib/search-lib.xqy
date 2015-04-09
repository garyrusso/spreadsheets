xquery version "1.0-ml";

module namespace slib = "http://marklogic.com/roxy/lib/search-lib";

import module namespace ssheet = "http://marklogic.com/roxy/lib/ssheet" at "/app/lib/spreadsheet.xqy";

declare namespace tax  = "http://tax.thomsonreuters.com";

declare namespace zip     = "xdmp:zip";

declare variable $NS := "http://tax.thomsonreuters.com";

declare variable $OPTIONS as element () :=
                 <options xmlns="xdmp:zip-get">
                   <format>xml</format>
                 </options>;

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

