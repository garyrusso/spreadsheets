xquery version "1.0-ml";

module namespace tr = "http://marklogic.com/rest-api/resource/aggregate";

declare namespace roxy = "http://marklogic.com/roxy";
declare namespace tax  = "http://tax.thomsonreuters.com";

declare variable $NS := "http://tax.thomsonreuters.com";

(:
 :)
declare function tr:getAllFieldValues($field as xs:string) (: as node()* :)
{
  let $query := cts:and-query((
                  cts:collection-query(("spreadsheet")),
                  cts:element-value-query(fn:QName($NS, "dname"), $field)
                ))
                
  let $results := cts:search(fn:doc(), $query)
  
  return
    xs:integer($results/tax:workbook/tax:feed/tax:definedNames/tax:definedName[tax:dname=$field]/tax:rnValue)
};

(:
 :)
declare function tr:getAllFieldLabels($field as xs:string) (: as node()* :)
{
  let $query := cts:and-query((
                  cts:collection-query(("spreadsheet")),
                  cts:element-value-query(fn:QName($NS, "dname"), $field)
                ))
                
  let $results := cts:search(fn:doc(), $query)
  
  return
    xs:string($results/tax:workbook/tax:feed/tax:definedNames/tax:definedName[tax:dname=$field]/tax:dlabel)
};

(:
 :)
declare function tr:getFieldValuesByUser($field as xs:string, $user as xs:string) (: as node()* :)
{
  let $query := cts:and-query((
                  cts:collection-query(("spreadsheet")),
                  cts:element-value-query(fn:QName($NS, "user"), $user),
                  cts:element-value-query(fn:QName($NS, "dname"), $field)
                ))
                
  let $results := cts:search(fn:doc(), $query)
  
  return
    xs:integer($results/tax:workbook/tax:feed/tax:definedNames/tax:definedName[tax:dname=$field]/tax:rnValue)
};

(:
 :)
declare function tr:getFieldLabelsByUser($field as xs:string, $user as xs:string) (: as node()* :)
{
  let $query := cts:and-query((
                  cts:collection-query(("spreadsheet")),
                  cts:element-value-query(fn:QName($NS, "user"), $user),
                  cts:element-value-query(fn:QName($NS, "dname"), $field)
                ))
                
  let $results := cts:search(fn:doc(), $query)
  
  return
    xs:string($results/tax:workbook/tax:feed/tax:definedNames/tax:definedName[tax:dname=$field]/tax:dlabel)
};

(:
 :)
declare function tr:getUsersByField($field as xs:string) (: as node()* :)
{
  let $query := cts:and-query((
                  cts:collection-query(("spreadsheet")),
                  cts:element-value-query(fn:QName($NS, "dname"), $field)
                ))
                
  let $results := cts:search(fn:doc(), $query)
  
  return
    fn:distinct-values(xs:string($results/tax:workbook/tax:meta/tax:user/text()))
};

(:
 :)
declare function tr:getDocUrisByField($field as xs:string) (: as node()* :)
{
  let $query := cts:and-query((
                  cts:collection-query(("spreadsheet")),
                  cts:element-value-query(fn:QName($NS, "dname"), $field)
                ))
                
  let $results := cts:search(fn:doc(), $query)
  
  let $docUris :=
    for $docUri in fn:distinct-values(xs:string($results/tax:workbook/tax:meta/tax:file/text()))
      order by $docUri
        return
          $docUri
  
  return
    $docUris
};

(:
 :)
declare function tr:getDocUrisByUser($field as xs:string, $user as xs:string) (: as node()* :)
{
  let $query := cts:and-query((
                  cts:collection-query(("spreadsheet")),
                  cts:element-value-query(fn:QName($NS, "user"), $user),
                  cts:element-value-query(fn:QName($NS, "dname"), $field)
                ))
                
  let $results := cts:search(fn:doc(), $query)
  
  let $docUris :=
    for $docUri in fn:distinct-values(xs:string($results/tax:workbook/tax:meta/tax:file/text()))
      order by $docUri
        return
          $docUri
  
  return
    $docUris
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
  let $field  := map:get($params, "field")
  let $user   := map:get($params, "user")

  let $values :=
    if ((fn:string-length($user) gt 0) and 
        (fn:string-length($field) gt 0)) then
      tr:getFieldValuesByUser($field, $user)
    else
    if (fn:string-length($field) gt 0) then
      tr:getAllFieldValues($field)
    else
      "incomplete input"

  let $labels :=
    if (fn:string-length($user) gt 0) then
      fn:distinct-values(tr:getFieldLabelsByUser($field, $user))
    else
      fn:distinct-values(tr:getAllFieldLabels($field))

  let $users :=
    if (fn:string-length($user) eq 0) then
      fn:distinct-values(tr:getUsersByField($field))
    else
      document { $user }

  let $docUris :=
    if (fn:string-length($user) eq 0) then
      fn:distinct-values(tr:getDocUrisByField($field))
    else
      fn:distinct-values(tr:getDocUrisByUser($field, $user))

  let $inputDoc :=
    element { "input" }
    {
      element { "field" } { $field },
      element { "user" } { $user }
    }

  let $labelsDoc :=
    element { "labels" }
    {
      for $label in $labels
        return
          element { "label" } { $label }
    }

  let $usersDoc :=
    element { "users" }
    {
      for $user in $users
        return
          element { "user" } { $user }
    }

  let $urisDoc :=
    element { "uris" }
    {
      for $uri in $docUris
        return
          element { "uri" } { $uri }
    }

  return
    document
    {
      <response>
        {$inputDoc}
        <refs>
          {$usersDoc}
          {$labelsDoc}
          {$urisDoc}
        </refs>
        <values>{$values}</values>
        <sum>{fn:sum($values)}</sum>
        <avg>{fn:avg($values)}</avg>
        <min>{fn:min($values)}</min>
        <max>{fn:max($values)}</max>
        <stddev>{math:stddev($values)}</stddev>
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
