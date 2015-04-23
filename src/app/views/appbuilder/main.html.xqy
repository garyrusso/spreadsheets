(:
Copyright 2012 MarkLogic Corporation

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
:)
xquery version "1.0-ml";

import module namespace c = "http://marklogic.com/roxy/config" at "/app/config/config.xqy";

import module namespace vh = "http://marklogic.com/roxy/view-helper" at "/roxy/lib/view-helper.xqy";

import module namespace facet = "http://marklogic.com/roxy/facet-lib" at "/app/views/helpers/facet-lib.xqy";

declare namespace search = "http://marklogic.com/appservices/search";
declare namespace tax    = "http://tax.thomsonreuters.com";

declare option xdmp:mapping "false";

declare variable $q as xs:string? := vh:get("q");
declare variable $page as xs:int := vh:get("page");
declare variable $search-options as element(search:options) := vh:get("search-options");
declare variable $response as element(search:response)? := vh:get("response");

declare function local:transform-snippet-orig($nodes as node()*)
{
  for $n in $nodes
  return
    typeswitch($n)
      case element(search:highlight) return
        <span xmlns="http://www.w3.org/1999/xhtml" class="highlight">{fn:data($n)}</span>
      case element() return
        element div
        {
          attribute class { fn:local-name($n) },
          local:transform-snippet(($n/@*, $n/node()))
        }
      default return $n
};

declare function local:transform-snippet($nodes as node()*)
{
  for $n in $nodes
    let $sdoc1 := $n/..
    let $sdoc2 := $n/../../..
    let $sdoc3 := fn:doc($sdoc1/@uri)
    let $sdoc4 := fn:doc($sdoc2/@uri)
    
  return
    typeswitch($n)
      case element(search:highlight) return
        let $node1 := xdmp:eval($n/../@path)
        let $sheetName := $node1/../tax:sheet/text()
        return
          if (fn:string-length($sheetName) eq 0) then () else
          (
            element div
            {
              <table border="0" width="100%">
                <tr><td width="145" valign="top">Highlight</td><td valign="top"><span xmlns="http://www.w3.org/1999/xhtml" class="highlight">{$node1}</span></td></tr>
                <tr><td width="145" valign="top">Worksheet</td><td valign="top">{$node1/../tax:sheet/text()}</td></tr>
                <tr><td width="145" valign="top">Cell Position</td><td valign="top">{$node1/../tax:pos/text()}</td></tr>
                <tr><td width="145" valign="top">Field Name</td><td valign="top">{$node1/../tax:dname/text()}</td></tr>
                <tr><td width="145" valign="top">Row Label</td><td valign="top">{$node1/../tax:rowLabel/text()}</td></tr>
                <tr><td width="145" valign="top">Column Label</td><td valign="top">{$node1/../tax:columnLabel/text()}</td></tr>
                <tr><td width="145" valign="top">Field Value</td><td valign="top">{$node1/../tax:dvalue/text()}</td></tr>
              </table>
            },
            <hr/>
          )

      case element() return
        let $docUri := $n/../@uri
        let $doc3   := fn:doc($docUri)
        let $fileUri := $doc3/tax:workbook/tax:meta/tax:file/text()
        let $docType :=
          if (fn:string-length($doc3//tax:meta/tax:type/text()) eq 0) then
            "Data Request"
          else
            $doc3//tax:meta/tax:type/text()
        
        return
        (
            element div
            {
              attribute class { fn:local-name($n) },
              <table border="0" width="100%">
                {
                  if (fn:string-length($docUri) eq 0) then "" else
                  (
                    <tr>
                      <td width="105">Relevance:</td>
                      <td>{fn:concat(fn:format-number($sdoc1/@confidence * 100, "#,###"), "%")}</td>
                      <td align="right"><a target="_blank" href="view.xml?uri={$docUri}">Open XML</a></td>
                    </tr>,
                    <tr><td width="145" valign="top">Type</td><td colspan="2" valign="top">{$docType}</td></tr>,
                    <tr><td width="145" valign="top">User</td><td colspan="2" valign="top">{$doc3//tax:meta/tax:user/text()}</td></tr>,
                    if (fn:starts-with($doc3//tax:meta/tax:type/text(), "template") or fn:starts-with($doc3//tax:meta/tax:type/text(), "wpaper")) then
                      <tr><td width="145" valign="top">File URI</td><td colspan="2" valign="top"><a target="_blank" href="view.xlsx?uri={$fileUri}">{$fileUri}</a></td></tr>
                    else
                    if (fn:ends-with($docUri, "json")) then 
                      <tr><td width="145" valign="top">JSON Doc URI</td><td colspan="2" valign="top"><a target="_blank" href="view.xml?uri={$docUri}">{xs:string($docUri)}</a></td></tr>
                    else
                      <tr><td width="145" valign="top">Doc URI</td><td colspan="2" valign="top">{$docUri}</td></tr>
                  )
                }
                <tr>
                  <td valign="top" colspan="3">
                    {local:transform-snippet(($n/@*, $n/node()))}
                  </td>
                </tr>
              </table>
            }
        )
        
      default return ()
      (:
        let $docUri2 := $n/../../../@uri
        let $doc4   := fn:doc($docUri2)
        return
            if (fn:local-name($n) eq "path") then () else
            (
              element div
              {
                <table border="0" width="100%">
                  <tr>
                    <td width="145" valign="top">File URI 111</td><td valign="top">{$doc4/tax:workbook/tax:meta/*:file/text()}</td>
                    <td width="10%" align="right" valign="top"><a target="_blank" href="view.xml?uri={$docUri2}">Open XML</a></td>
                  </tr>,
                  <tr><td width="145" valign="top">Type</td><td colspan="2" valign="top">{$doc4/tax:workbook/tax:meta/tax:type/text()}</td></tr>,
                  <tr><td width="145" valign="top">User</td><td colspan="2" valign="top">{$doc4/tax:workbook/tax:meta/tax:user/text()}</td></tr>,
                  <tr><td width="145" valign="top">File URI</td><td colspan="2" valign="top">{$doc4/tax:workbook/tax:meta/tax:file/text()}</td></tr>
                </table>
              }
            )
      :)
};

vh:add-value("sidebar",
  <div class="sidebar" arcsize="5 5 0 0" xmlns="http://www.w3.org/1999/xhtml">
  {
    facet:facets($response/search:facet, $q, $c:SEARCH-OPTIONS, $c:LABELS)
  }
  </div>

),

let $page := ($response/@start - 1) div $c:DEFAULT-PAGE-LENGTH + 1
let $total-pages := fn:ceiling($response/@total div $c:DEFAULT-PAGE-LENGTH)
let $sStart1   := fn:format-number($response/@start, "#,###")
let $sStart2   := fn:format-number(fn:min(($response/@start + $response/@page-length - 1, $response/@total)), "#,###")
let $sDocCount := fn:format-number($response/@total, "#,###")
return
  <div xmlns="http://www.w3.org/1999/xhtml" id="search">
  {
    if ($response/@total gt 0) then
    (
      <div class="pagination">
        <span class="status">Showing {$sStart1} to {$sStart2} of <span id="total-results">{$sDocCount}</span> Results </span>
        <span class="nav">
          <span id="first" class="button">
          {
            if ($page gt 1) then
              <a href="/?q={$q}&amp;page=1">&laquo;</a>
            else
              "&laquo;"
          }
          </span>
          <span id="previous" class="button">
          {
            if ($page gt 1) then
              <a href="?q={$q}&amp;page={$page - 1}">&lt;</a>
            else
              "&lt;"
          }
          </span>
          <span id="next" class="button">
          {
            if ($page lt $total-pages) then
              <a href="?q={$q}&amp;page={$page + 1}">&gt;</a>
            else
              "&gt;"
          }
          </span>
          <span id="last" class="button">
          {
            if ($page lt $total-pages) then
              <a href="?q={$q}&amp;page={$total-pages}">&raquo;</a>
            else
              "&raquo;"
          }
          </span>
        </span>
      </div>,
      <div class="results">
      {
        for $result at $i in $response/search:result
        return
          <div class="result">
          {
            local:transform-snippet($result/search:snippet)
          }
          </div>
      }
      </div>
    )
    else
      <div class="results">
        <h2>No Results Found</h2>
      </div>
  }

  </div>