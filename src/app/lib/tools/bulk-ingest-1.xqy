declare variable $page       as xs:string external;
declare variable $pagesize   as xs:string external;
declare variable $userid     as xs:string external;

(: Page Size ($ps) - Standards are ingested in small batches. Each batch has an implied transactional unit of work. :)
let $ps         := 100
let $total      := 1000
let $maxpage    := fn:ceiling($total div $ps)

return
  for $userNumber in 1 to 1000
    for $i in 1 to $maxpage
      return
      (
        xdmp:log(fn:concat("GR1: spreadsheet generator $total = ", $total, " : ps = ", $ps, " : maxpage = ", $maxpage, " : userid = ", $userNumber)),
        xdmp:spawn(
          "/app/lib/tools/bulk-ingest-2.xqy",
          ((xs:QName("page"),     xs:string($i)),
           (xs:QName("pagesize"), xs:string($ps)),
           (xs:QName("userid"),   xs:string($userNumber))))
      )

