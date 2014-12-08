xquery version "1.0-ml";

module namespace tr = "http://marklogic.com/rest-api/resource/fields";

declare namespace roxy = "http://marklogic.com/roxy";
declare namespace tax  = "http://tax.thomsonreuters.com";

declare variable $NS := "http://tax.thomsonreuters.com";

(:
 :)
declare function tr:getFields($user as xs:string?)
{
  let $query :=
    if (fn:empty($user)) then
      cts:and-query((
                      cts:collection-query(("spreadsheet"))
                    ))
    else
      cts:and-query((
                      cts:collection-query(("spreadsheet")),
                      cts:element-word-query(fn:QName($NS, "user"), $user)
                    ))
  
  let $vals := cts:element-values(fn:QName($NS, "dname"), (), (), $query)
  
  return
    element { "fields" }
    {
      element { "count" } { fn:count($vals) },
      for $val in $vals
        let $freq := cts:frequency($val)
        order by $freq descending
          return
            element { "field" }
            {
              element { "name" }  { $val },
              element { "count" } { $freq }
            }
    }
};

(:
 :)
declare function tr:getFieldsWithinDoc($uri as xs:string)
{
  let $definedNames := fn:doc($uri)/tax:workbook/tax:feed/tax:definedNames/tax:definedName

  let $vals := $definedNames/tax:dname/text()
  
  return
    if (fn:count($vals) eq 0) then
      element { "fields" } { "empty" }
    else
      element { "fields" }
      {
        element { "count" } { fn:count($vals) },
        for $val in $vals
          let $freq := fn:count($definedNames[tax:dname=$val])
          order by $freq descending, $val ascending
            return
              element { "field" }
              {
                element { "name" }  { $val },
                element { "count" } { $freq }
              }
      }
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
  let $user := map:get($params, "user")
  let $uri  := map:get($params, "uri")

  let $fieldsDoc :=
    if (fn:not(fn:empty($user))) then
      tr:getFields($user)
    else
    if (fn:not(fn:empty($uri))) then
      tr:getFieldsWithinDoc($uri)
    else
      tr:getFields(())

  let $inputDoc :=
    if (fn:not(fn:empty($user))) then
      element { "input" } { "user: "||$user }
    else
    if (fn:not(fn:empty($uri))) then
      element { "input" } { "uri: "||$uri }
    else
      element { "input" } { "no parameters - full scope search" }
  
  return
    document
    {
      <response>
        {$inputDoc}
        {$fieldsDoc}
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
