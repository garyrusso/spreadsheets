xquery version "1.0-ml";

module namespace tr = "http://marklogic.com/rest-api/resource/findValues";

declare namespace roxy = "http://marklogic.com/roxy";
declare namespace tax = "http://tax.thomsonreuters.com";

declare variable $NL      := "\r?\n";
declare variable $pathIdx := "/tax:origin/tax:feed/tax:price//*";

(:
 :)
declare function tr:getValuesWithinRange($min as xs:decimal, $max as xs:decimal) as node()*
{
  let $values  :=
    for $val in cts:values(cts:path-reference($pathIdx))
      where $val ge $min and $val le $max
        return
          $val
  
  let $valuesDoc :=
    element { "valueItems" }
    {
      for $value in $values
      
        let $results := cts:search(/tax:origin/tax:feed/tax:price, cts:word-query(xs:string($value)))
        
        return
          element { "valueItem" }
          {
            (
              element { "value" } { $value },
              element { "count" } { fn:count($results) },
              element { "items" }
              {
                for $item in $results//*/text()
                  let $path  := xdmp:path($item/..)
                    where $item eq $value
                      return
                        element { "item" }
                        {
                          element { "uri" }   { xdmp:node-uri($item) },
                          element { "path" }  { $path }
                        }
               }
            )
          }
    }

  let $response :=
    element { "response" }
    {
      element { "input" }
      {
        element { "query" }          { "importedUnitCode:RU0073* AND endingBalance:5896.*" },
        element { "min" }            { $min },
        element { "max" }            { $max }
      },
      element { "elapsedTime" }      { xdmp:elapsed-time() },
      element { "uniqueValueCount" } { fn:count($values) },
      element { "values" }           { fn:string-join(xs:string($values), " ") },
      $valuesDoc
    }

  return $response
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
  let $q   := map:get($params, "q")
  let $min := xs:decimal(map:get($params, "min"))
  let $max := xs:decimal(map:get($params, "max"))
  
  let $doc := tr:getValuesWithinRange($min, $max)

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
