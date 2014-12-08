xquery version "1.0-ml";

module namespace tr = "http://marklogic.com/rest-api/resource/search";

import module namespace search = "http://marklogic.com/appservices/search" at "/MarkLogic/appservices/search/search.xqy";
import module namespace json   = "http://marklogic.com/json" at "/roxy/lib/json.xqy";
import module namespace c      = "http://marklogic.com/roxy/config" at "/app/config/config.xqy";

declare namespace roxy  = "http://marklogic.com/roxy";
declare namespace xh    = "http://www.w3.org/1999/xhtml";

declare namespace glm   = "http://marklogic.com/xdmp/json/basic";

(: 
 : To add parameters to the functions, specify them in the params annotations. 
 : Example
 :   declare %roxy:params("uri=xs:string", "priority=xs:int") tr:get(...)
 : This means that the get function will take two parameters, a string and an int.
 :)

(:
 :)
declare 
%roxy:params("q=xs:string", "start=xs:integer", "pageLength=xs:integer")
function tr:get(
  $context as map:map,
  $params  as map:map
) as document-node()*
{
  let $q  := map:get($params, "q")
  let $st := map:get($params, "start")
  let $ps := map:get($params, "pageLength")
  let $ft := map:get($params, "format")

  let $qtext      := if (fn:string-length($q) eq 0)  then "" else $q
  let $start      := if (fn:string-length($st) eq 0) then  1 else xs:integer($st)
  let $pageLength := if (fn:string-length($ps) eq 0) then 10 else xs:integer($ps)
  let $format     := if ($ft eq "json") then "json" else "xml"

  let $output-types :=
    if ($format eq "json") then
    (
      map:put($context,"output-types","application/json")
    )
    else
    (
      map:put($context,"output-types","application/xml")
    )

  let $options  := $c:REST-SEARCH-OPTIONS

  let $options1 := $c:SEARCH-OPTIONS

  let $options2 :=
      <options xmlns="http://marklogic.com/appservices/search">
        <constraint name="Id">
          <word>
            <element ns="http://marklogic.com/xdmp/json/basic" name="Id"/>
          </word>
        </constraint>
        <constraint name="ImportedAccountCode">
          <word>
            <element ns="http://marklogic.com/xdmp/json/basic" name="ImportedAccountCode"/>
          </word>
        </constraint>
        <constraint name="ImportedUnitCode">
          <word>
            <element ns="http://marklogic.com/xdmp/json/basic" name="ImportedUnitCode"/>
          </word>
        </constraint>
        <transform-results apply="metadata-snippet">
          <preferred-elements>
            <element ns="http://marklogic.com/xdmp/json/basic" name="Id"/>
            <element ns="http://marklogic.com/xdmp/json/basic" name="ImportFileId"/>
            <element ns="http://marklogic.com/xdmp/json/basic" name="ImportedUnitCode"/>
            <element ns="http://marklogic.com/xdmp/json/basic" name="ImportedAccountCode"/>
            <element ns="http://marklogic.com/xdmp/json/basic" name="BeginningBalance"/>
            <element ns="http://marklogic.com/xdmp/json/basic" name="EndingBalance"/>
          </preferred-elements>
          <max-matches>2</max-matches>
          <max-snippet-chars>150</max-snippet-chars>
          <per-match-tokens>20</per-match-tokens>
        </transform-results>
      </options>

  let $results := search:search($qtext, $options, $start, $pageLength)

  let $doc :=
    if ($format eq "json") then
    (
      text { tr:convert-to-json($results, $pageLength) }
    )
    else
    (
      $results
    )

  return document { $doc }
};

declare function tr:convert-to-json($results, $ps)
{
  let $count       := fn:count($results/search:result)
  let $response    := $results
  let $total       := fn:string($response/@total)

  let $pagesize    := if ($ps eq 0) then $c:DEFAULT-PAGE-LENGTH else $ps
  let $page        := (($response/@start - 1) div ($pagesize) + 1)
  let $end         := fn:string(fn:min(($response/@start + $response/@page-length - 1, $response/@total)))
  let $total-pages := fn:ceiling($response/@total div ($pagesize))

  let $jdoc        := tr:serialize-to-json($response, $page, $end, $total-pages, $count, $total)

  return $jdoc
};

declare function tr:serialize-to-json($doc, $page, $end, $total-pages, $count, $total)
{
  let $facetInfo :=
          json:o(("facetInfo",
            json:a((
              for $facet in $doc/search:facet
                return
                  json:o((
                    "categoryName", fn:string($facet/@name),
                    "facets",
                      json:a((
                        for $facet-value in $facet/search:facet-value
                          return
                            json:o((
                              "code", fn:string($facet-value/@name),
                              "count", xs:int($facet-value/@count),
                              "name", fn:string($facet-value/text())
                            ))
                          ))
                        ))
                      ))
                    ))

  let $resultsJson :=
          json:o(("results",
            json:a((
            for $result in $doc/search:result
              return
              (
                json:o((
                  "index",               xs:int($result/@index),
                  "relevance",           fn:string($result/@confidence * 100),
                  "ImportFileId",        $result//glm:ImportFileId/text(),
                  "ImportedUnitCode",    $result//glm:ImportedUnitCode/text(),
                  "ImportedAccountCode", $result//glm:ImportedAccountCode/text(),
                  "BeginningBalance",    $result//glm:BeginningBalance/text(),
                  "EndingBalance",       $result//glm:EndingBalance/text(),
                  "snippet",
                  for $match in $result/search:snippet/search:match
                    return
                      json:o((
                        "highLights",
                        json:a((
                          for $highlight in $match/search:highlight
                            return
                              $highlight/text()
                          )),
                        "snippetText", fn:string(fn:normalize-space(fn:data($match)))
                      ))
                ))
              )
            ))
          ))

  let $paginationInfo :=
          json:o(("paginationInfo",
            json:o((
              "start", xs:int($doc/@start),
              "end", xs:int($end),
              "page", xs:int($page),
              "pageLength", xs:int($doc/@page-length),
              "totalPages", xs:int($total-pages),
              "total", xs:int($doc/@total),
              "qtext", fn:string($doc/search:qtext)
            ))
          ))

  let $pagination1 := json:serialize($paginationInfo)
  let $pagination2 := fn:substring($pagination1, 1, fn:string-length($pagination1)-1)
  
  let $facets1 := json:serialize($facetInfo)
  let $facets2 := fn:concat(fn:substring($facets1, 2, fn:string-length($facets1)-2))

  let $results1 := json:serialize($resultsJson)
  let $results2 := fn:concat(fn:substring($results1, 2, fn:string-length($results1)-2))

  let $jdoc := fn:concat($pagination2, ",", $facets2, ",", $results2, "}")

  return $jdoc
};
