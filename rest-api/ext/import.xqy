xquery version "1.0-ml";

module namespace tr = "http://marklogic.com/rest-api/resource/import";

import module namespace search="http://marklogic.com/appservices/search" at "/MarkLogic/appservices/search/search.xqy";

declare namespace roxy = "http://marklogic.com/roxy";
declare namespace tax  = "http://tax.thomsonreuters.com";

declare variable $NS  := "http://tax.thomsonreuters.com";

declare variable $exportOptions :=
  <options xmlns="http://marklogic.com/appservices/search">
    <search-option>unfiltered</search-option>
    <page-length>20</page-length>
    <term>
      <term-option>case-insensitive</term-option>
    </term>
    <constraint name="dnames">
      <range type="xs:string">
        <element ns="http://tax.thomsonreuters.com" name="dname"/>
        <facet-option>descending</facet-option>
        <facet-option>limit=10</facet-option>
      </range>
    </constraint>
    <constraint name="user">
      <word>
        <element ns="http://tax.thomsonreuters.com" name="user"/>
      </word>
    </constraint>
    <constraint name="type">
      <word>
        <element ns="http://tax.thomsonreuters.com" name="type"/>
      </word>
    </constraint>
    <constraint name="dname">
      <word>
        <element ns="http://tax.thomsonreuters.com" name="dname"/>
      </word>
    </constraint>
    <constraint name="dvalue">
      <word>
        <element ns="http://tax.thomsonreuters.com" name="dvalue"/>
      </word>
    </constraint>
    <constraint name="dlabel">
      <word>
        <element ns="http://tax.thomsonreuters.com" name="dlabel"/>
      </word>
    </constraint>
    <transform-results apply="snippet">
      <preferred-elements>
        <element ns="http://tax.thomsonreuters.com" name="dname"/>
        <element ns="http://tax.thomsonreuters.com" name="dlabel"/>
        <element ns="http://tax.thomsonreuters.com" name="dvalue"/>
      </preferred-elements>
    </transform-results>
    <return-results>true</return-results>
    <return-query>true</return-query>
  </options>;

(:
 :)
declare function tr:getResults($query as xs:string) (: as node()* :)
{
  let $results := search:search($query, $exportOptions)/search:result
  
  let $records :=
      element { "records" }
      {
        (: element { "count" } { fn:count($results) }, :)
        for $result in $results
          let $doc := xdmp:eval($result/@path)
          return
            element { "record" }
            {
              element { "user" } { $doc/tax:workbook/tax:meta/tax:user/text() },
              element { "file" } { $doc/tax:workbook/tax:meta/tax:file/text() },
              element { "fields" }
              {
                for $match in $result/search:snippet/search:match/@*:path
                  let $defName := xdmp:eval($match)/..
                  return
                    element { "field" }
                    {
                      element { "name" } { $defName/tax:dname/text() },
                      element { "label" } { $defName/tax:dlabel/text() },
                      element { "value" } { $defName/tax:dvalue/text() },
                      element { "sheet" } { $defName/tax:sheet/text() },
                      element { "cell" } { $defName/tax:pos/text() }
                    }
              }
            }
      }

  return
    $records
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
  let $query  :=
    if ((map:get($params, "q") eq "") or (fn:empty(map:get($params, "q")))) then
      "dname:*"
    else
      map:get($params, "q")

  let $inputDoc :=
    element { "input" }
    {
      element { "query" } { $query }
    }

  let $results := tr:getResults($query)
  
  return
    document
    {
      <response>
        {$results}
      </response>
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
  document { "PUT called on the ext service extension" }
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
  map:put($context, "output-types", "application/xml"),
  xdmp:set-response-code(200, "OK"),
  document { "POST called on the ext service extension" }
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
