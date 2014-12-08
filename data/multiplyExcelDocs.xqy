declare namespace tax = "http://tax.thomsonreuters.com";
declare variable $NS := "http://tax.thomsonreuters.com";

declare function local:getNewDoc($origDoc as node()) as node()*
{
  let $newPriceNode1 := element { fn:QName($NS, "price"||xdmp:random(100)) } { xdmp:random(1000000)||"."||xdmp:random(100) }
  let $newPriceNode2 := element { fn:QName($NS, "price"||xdmp:random(100)) } { xdmp:random(1000000)||"."||xdmp:random(100) }
  
  let $doc :=
    document
    {
      element { fn:QName($NS, "origin") }
      {
        $origDoc/tax:origin/tax:meta,
        element { fn:QName($NS, "feed") }
        {
          element { fn:QName($NS, "price") }
          {
            $newPriceNode1,
            $newPriceNode2,
            $origDoc/tax:origin/tax:feed/tax:price/*
          },
          $origDoc/tax:origin/tax:feed/tax:body
        }
      }
    }

  return $doc
};

let $query := cts:directory-query("/origin/", "1")
let $docs  := cts:search(fn:collection(), $query)

let $newUris :=
  for $doc in $docs[101 to 2001]
    for $i in (1 to 10)
      let $newUri := "/loadtest/"||xdmp:hash64($doc)||xdmp:random(10000000)||".xml"
      let $newDoc := local:getNewDoc($doc)
      let $_      := xdmp:document-insert($newUri, $newDoc)
      return
        $newUri

return
  fn:count($newUris)
