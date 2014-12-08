xquery version "1.0-ml";

module namespace olib = "http://marklogic.com/roxy/lib/origin-lib";

import module namespace search = "http://marklogic.com/appservices/search" at "/MarkLogic/appservices/search/search.xqy";
import module namespace cfg    = "http://marklogic.com/roxy/config" at "/app/config/config.xqy";

declare namespace cts    = "http://marklogic.com/cts";

declare option xdmp:mapping "false";

declare variable $NS := "http://marklogic.com/appservices/search";

declare function olib:rest-origin-snippet(
   $result as node(),
   $ctsquery as schema-element(cts:query),
   $options as element(search:transform-results)?
)
{
  let $default-snippet := search:snippet($result, $ctsquery, $options)
  return
    element
    { fn:QName($NS, "result-elements") }
    {
      element
      { fn:QName($NS, "result-element") }
      {
        element { fn:QName($NS, "element-name") } { "type" },
        element { fn:QName($NS, "element-value") } { $result//*:meta/*:type/text() }
      },
      element
      { fn:QName($NS, "result-element") }
      {
        element { fn:QName($NS, "element-name") } { "id" },
        element { fn:QName($NS, "element-value") } { $result//*:meta/*:id/text() }
      },
      element
      { fn:QName($NS, "result-element") }
      {
        element { fn:QName($NS, "element-name") } { "importFileId" },
        element { fn:QName($NS, "element-value") } { $result/*:origin/*:meta/*:importFileId/text() }
      },
      element
      { fn:QName($NS, "result-element") }
      {
        element { fn:QName($NS, "element-name") } { "importedUnitCode" },
        element { fn:QName($NS, "element-value") } { $result/*:origin/*:meta/*:importedUnitCode/text() }
      },
      element
      { fn:QName($NS, "result-element") }
      {
        element { fn:QName($NS, "element-name") } { "importedAccountCode" },
        element { fn:QName($NS, "element-value") } { $result/*:origin/*:meta/*:importedAccountCode/text() }
      },

      element
      { fn:QName($NS, "result-element") }
      {
        element { fn:QName($NS, "element-name") } { "beginningBalance" },
        element { fn:QName($NS, "element-value") } { $result/*:origin/*:meta/*:beginningBalance/text() }
      },
      element
      { fn:QName($NS, "result-element") }
      {
        element { fn:QName($NS, "element-name") } { "endingBalance" },
        element { fn:QName($NS, "element-value") } { $result/*:origin/*:meta/*:endingBalance/text() }
      }
    }
};

declare function olib:origin-snippet(
   $result as node(),
   $ctsquery as schema-element(cts:query),
   $options as element(search:transform-results)?
)
{
  let $default-snippet := search:snippet($result, $ctsquery, $options)
  return
    element
    { fn:QName(fn:namespace-uri($default-snippet), fn:name($default-snippet)) }
    { $default-snippet/@*,
      for $child in $default-snippet/node()
      return
        if ($child instance of element(search:match)) then
        element
        { fn:QName(fn:namespace-uri($child), fn:name($child)) }
        {
          $child/../@*,
          let $uri := fn:data($result/@uri)
          let $snipdoc := fn:doc($uri)
          return
            <table boder="1">
              <tr><td width="145" valign="top">namespace-uri</td><td colspan="2" valign="top">{fn:namespace-uri($result)}</td></tr>,
              <tr><td width="145" valign="top">name</td><td colspan="2" valign="top">{fn:name($result)}</td></tr>,
              <tr><td width="145" valign="top">Type</td><td colspan="2" valign="top">{$snipdoc/*:origin/*:meta/*:type/text()}</td></tr>,
              <tr><td width="145" valign="top">Id</td><td colspan="2" valign="top">{$snipdoc/*:origin/*:meta/*:id/text()}</td></tr>,
              <tr><td width="145" valign="top">Import File Id</td><td colspan="2" valign="top">{$snipdoc/*:origin/*:meta/*:importFileId/text()}</td></tr>,
              <tr><td width="145" valign="top">Imported Unit Code</td><td colspan="2" valign="top">{$snipdoc/*:origin/*:meta/*:importedUnitCode/text()}</td></tr>,
              <tr><td width="145" valign="top">Imported Account Code</td><td colspan="2" valign="top">{$snipdoc/*:origin/*:meta/*:importedAccountCode/text()}</td></tr>,
              <tr><td width="145" valign="top">Beginning Balance</td><td colspan="2" valign="top">{$snipdoc/*:origin/*:meta/*:beginningBalance/text()}</td></tr>,
              <tr><td width="145" valign="top">Ending Balance</td><td colspan="2" valign="top">{$snipdoc/*:origin/*:meta/*:endingBalance/text()}</td></tr>
            </table>
        }
        else
          $child
    }
};
