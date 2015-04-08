declare namespace zip     = "xdmp:zip";
declare namespace ssml    = "http://schemas.openxmlformats.org/spreadsheetml/2006/main";
declare namespace rel     = "http://schemas.openxmlformats.org/package/2006/relationships";
declare namespace wbrel   = "http://schemas.openxmlformats.org/officeDocument/2006/relationships";
declare namespace wsheet  = "http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet";
declare namespace core    = "http://schemas.openxmlformats.org/package/2006/metadata/core-properties";
declare namespace dcterms = "http://purl.org/dc/terms/";
declare namespace dc      = "http://purl.org/dc/elements/1.1/";

declare namespace tax    = "http://tax.thomsonreuters.com";

declare variable $NS := "http://tax.thomsonreuters.com";
declare variable $OPTIONS as element () :=
                 <options xmlns="xdmp:zip-get">
                   <format>xml</format>
                 </options>;

declare variable $BIN-OPTIONS as element() := 
                 <options xmlns="xdmp:document-get">
                   <format>binary</format>
                 </options>;

(:~
 : Iterate the network directory where the spreadsheet files (xslx files) reside.
 : Traverses the network directory recursively.
 :
 : @param $path The network directory where the XLSX files reside.
 :
 : Returns the complete list of XLSX files.
 :)
declare function local:loadDirectory($path as xs:string)
{
  try
  {
    for $entry in xdmp:filesystem-directory($path)/dir:entry
      let $subpath := $entry/dir:pathname/text()
        return
          if ( $entry/dir:type = 'directory' ) then
            local:loadDirectory($subpath)
          else
            $subpath
  }
  catch ($e) {()}
};

(:~
 : Generates ISO 8601 Date Format using Excel Date Format as input
 :
 : Excel Date Format is an long representing the number of days from 1900-01-01
 :
 : @param $days - Example: 41955 results in 2014-11-12
 :
 : Returns the ISO 8601 Date Format.
 :)
declare function local:getIsoDate($days as xs:string)
{
  let $delta     := xs:long($days) div 365
  let $year      := 1900 + xs:integer($delta)
  let $tempDay   := $delta - xs:integer($delta)
  let $dayNumber := fn:round(365 * math:trunc($tempDay, 17))
  
  let $monthNum  := xs:integer(xs:double($dayNumber div 365) * 12)
  let $month     :=
      if ($monthNum lt 10) then
        fn:concat("0", xs:string($monthNum))
      else
        xs:string($monthNum)

  (: GPR001 - fix this kludge later - use sql:dateadd() API :)
  let $day1      := fn:round(((xs:double($dayNumber div 365) * 12) - $monthNum) * 32)
  let $day  := if ($day1 gt 30) then 29 else $day1

  let $padDay    :=
      if ($day lt 10) then
        fn:concat("0", xs:string($day))
      else
        xs:string($day)
        
  return
    xs:date($year||"-"||$month||"-"||$padDay)
};

(:~
 : Get Value from Defined Name
 :
 : @param $cell
 : @param $doc
 :)
declare function local:getValue($row as xs:string, $col as xs:string, $sheetName as xs:string, $table as map:map)
{
  let $wkBook        := map:get($table, "xl/workbook.xml")/ssml:workbook/ssml:sheets/ssml:sheet
  let $rels          := map:get($table, "xl/_rels/workbook.xml.rels")/rel:Relationships
  let $sharedStrings := map:get($table, "xl/sharedStrings.xml")/ssml:sst/ssml:si/ssml:t/text()

  let $wkSheetKey := "xl/"||xs:string($rels/rel:Relationship[@Id=$wkBook[@name=$sheetName]/@wbrel:id]/@Target)

  let $wkSheet := map:get($table, $wkSheetKey)
  let $item     := $wkSheet/ssml:worksheet/ssml:sheetData/ssml:row[@r=$row]/ssml:c[@r=$col||$row]

  let $ref     := $item/@t
  let $value   := xs:string($item/ssml:v)

  let $retVal  := if ($ref eq "s") then $sharedStrings[xs:integer($value) + 1] else $value

  let $log := xdmp:log("11-1 ----- getValue: $col:        "||$col)
  let $log := xdmp:log("11-2 ----- getValue: $row:        "||$row)
  let $log := xdmp:log("11-3 ----- getValue: $sheetName:  "||$sheetName)
  let $log := xdmp:log("11-4 ----- getValue: $wkSheetKey: "||$wkSheetKey)
  let $log := xdmp:log("11-4 ----- getValue: $wkSheetKey: "||$wkSheetKey)
  
  let $log := xdmp:log("11-5 ----- getValue: $ref:        "||$ref)
  let $log := xdmp:log("11-6 ----- getValue: $value:      "||$value)
  let $log := xdmp:log(" ")

  return $retVal
};

(:~
 : Entry point to a recursive function.
 :
 : @param $row
 :)
declare function local:findRowLabel($row as xs:string, $col as xs:string, $sheetName as xs:string, $table as map:map) as xs:string*
{
  let $leftLabelVal := local:getRowLabelValue($row, $col, $sheetName, $table)

  return $leftLabelVal
};

declare function local:getRowLabelValue($row as xs:string, $col as xs:string, $sheetName as xs:string, $table)
{
  let $pattern  := "[a-zA-Z]"

  let $leftCell := local:getLeftCell($col)

  return
    if (fn:matches(local:getValue($row, $leftCell, $sheetName, $table), $pattern) or
        (fn:string-to-codepoints($leftCell) lt 66)) then
      local:getValue($row, $leftCell, $sheetName, $table)
    else
      local:getRowLabelValue($row, $leftCell, $sheetName, $table)
};

declare function local:getLeftCell($col as xs:string)
{
  let $upperCol      := fn:upper-case($col)
  let $lastCharCode  := fn:string-to-codepoints($upperCol)[fn:last()]
  let $decrementChar := fn:codepoints-to-string(fn:string-to-codepoints($upperCol)[fn:last()] - 1)

  let $retVal :=
    if (($lastCharCode) eq 65) then  (: "A" :)
      $upperCol
    else
      fn:substring($upperCol, 1, fn:string-length($upperCol) - 1)||$decrementChar

  return $retVal
};

(:~
 : Entry point to a recursive function.
 :
 : @param $col
 :)
declare function local:findColumnLabel($row as xs:string, $col as xs:string, $sheetName as xs:string, $table as map:map) (: as xs:string* :)
{
  let $leftLabelVal :=
    if (fn:string-length($row) = 0) then ""
    else
      local:getColumnLabelValue(xs:integer($row), $col, $sheetName, $table)

  return $leftLabelVal
};

declare function local:getColumnLabelValue($row as xs:integer, $col as xs:string, $sheetName as xs:string, $table)
{
  let $pattern  := "[a-zA-Z]"
  
  let $rows :=
    for $n in (1 to $row)
      return
        ($row + 1) - $n

  let $labels :=
    for $row in $rows
      let $label := local:getValue(xs:string($row), $col, $sheetName, $table)
        where fn:matches($label, $pattern)
          return
            $label

  return $labels[1]
};

(:~
 : Generate File URI
 :
 : @param $cell
 :)
declare function local:generateFileUri($user as xs:string, $fileName as xs:string)
{
  let $fileUri := "/user/"||$user||"/files/"||fn:tokenize($fileName, "/")[fn:last()]
  
  return $fileUri
};

(:~
 : Expansion Element
 :
 : @param $dn, $row, $col
 :)
declare function local:expansionElement($dn as node(), $row as xs:string, $col as xs:string, $table as map:map)
{
  let $newPos      := $col||$row
  let $sheetName   := $dn/tax:sheet/text()
  let $dname       := $dn/tax:dname/text()
  let $rowLabel    := local:findRowLabel($row, $col, $sheetName, $table)
  let $columnLabel := local:findColumnLabel($row, $col, $sheetName, $table)
  let $newValue    := local:getValue($row, $col, $sheetName, $table)
  
  let $doc :=
    if (fn:empty($newValue)) then ()
    else
      element { fn:QName($NS, "definedName") }
      {
        element { fn:QName($NS, "dname") }       { $dname },
        element { fn:QName($NS, "rowLabel") }    { if (fn:empty($rowLabel)) then "none" else $rowLabel },
        element { fn:QName($NS, "columnLabel") } { if (fn:empty($columnLabel)) then "none" else $columnLabel },
        element { fn:QName($NS, "sheet") }       { $sheetName },
        element { fn:QName($NS, "col") }         { $col },
        element { fn:QName($NS, "row") }         { $row },
        element { fn:QName($NS, "pos") }         { $newPos },
        element { fn:QName($NS, "dvalue") }      { if ($dname eq "FilingDate") then local:getIsoDate($newValue) else $newValue }
      }

  return $doc
};

(:~
 : Column Expansion
 :
 : @param $doc
 :)
declare function local:columnExpandDoc($dn as node(), $table as map:map)
{
  let $col1 := fn:string-to-codepoints($dn/tax:col1/text())
  let $col2 := fn:string-to-codepoints($dn/tax:col2/text())

  let $doc :=
    for $col in ($col1 to $col2)
      let $row := $dn/tax:row1/text()
      let $newCol := fn:codepoints-to-string($col)
        return
          local:expansionElement($dn, xs:string($row), $newCol, $table)

  return $doc
};

(:~
 : Row Expansion
 :
 : @param $doc
 :)
declare function local:rowExpandDoc($dn as node(), $table as map:map)
{
  let $doc :=
    for $row in ((xs:integer($dn/tax:row1/text())) to xs:integer($dn/tax:row2/text()))
      let $col := $dn/tax:col1/text()
        return
          local:expansionElement($dn, xs:string($row), $col, $table)
                  
  return $doc
};

(:~
 : Column and Row Expansion
 :
 : @param $doc
 :)
declare function local:columnRowExpandDoc($dn as node(), $table as map:map)
{
  let $doc :=
    for $row in ((xs:integer($dn/tax:row1/text())) to xs:integer($dn/tax:row2/text()))
    
      let $col1 := fn:string-to-codepoints($dn/tax:col1/text())
      let $col2 := fn:string-to-codepoints($dn/tax:col2/text())
    
      return
        for $col in ($col1 to $col2)
          let $newCol := fn:codepoints-to-string($col)
            return
              local:expansionElement($dn, xs:string($row), $newCol, $table)

  return $doc
};

(:~
 : Column and Row Expansion
 :
 : @param $doc
 :)
declare function local:expandDoc($doc as node(), $table as map:map)
{
  let $newDoc :=
    element { fn:QName($NS, "definedNames") }
    {
      for $dn in $doc/tax:definedName
        return
          if (fn:empty($dn/tax:row2/text())) then
          (
            (: No Expansion :)
            local:expansionElement($dn, xs:string($dn/tax:row1/text()), $dn/tax:col1/text(), $table)
          )
          else
          if (($dn/tax:row1/text() ne $dn/tax:row2/text()) and ($dn/tax:col1/text() ne $dn/tax:col2/text())) then
          (
            (: Row and Column Expansion :)
            (: local:columnRowExpandDoc($dn, $table) :)
          )
          else
          if ($dn/tax:row1/text() eq $dn/tax:row2/text()) then
          (
            (: Column Expansion :)
            local:columnExpandDoc($dn, $table)
          )
          else
          if ($dn/tax:col1/text() eq $dn/tax:col2/text()) then
          (
            (: Row Expansion :)
            local:rowExpandDoc($dn, $table)
          )
          else ()
    }
    
  return $newDoc
};

(:~
 : Extract Spreadsheet Data
 :
 : @param $zipfile
 :)
declare function local:extractSpreadsheetData($user as xs:string, $zipFile as xs:string)
{
  let $excelFile := xdmp:document-get($zipFile)

  let $exclude :=
  (
    "[Content_Types].xml", "docProps/app.xml", "xl/theme/theme1.xml", "xl/styles.xml", "_rels/.rels",
    "xl/vbaProject.bin", "xl/media/image1.png", "xl/media/image2.jpeg"
  )

  let $table := map:map()
  
  let $docs :=
    for $x in xdmp:zip-manifest($excelFile)//zip:part/text()
      where
        (($x = $exclude) eq fn:false()) and
        fn:not(fn:starts-with($x, "xl/printerSettings/printerSettings")) and
        fn:not(fn:ends-with($x, ".bin")) and
        fn:not(fn:ends-with($x, ".jpeg"))
        return
          map:put($table, $x, xdmp:zip-get($excelFile, $x, $OPTIONS))

  let $wkBook        := map:get($table, "xl/workbook.xml")/ssml:workbook
  
  let $defnames      :=
    for $item in $wkBook/ssml:definedNames/node() [1 to 100] (: [201 to 300] :)
      where fn:not(fn:starts-with($item/text(), "#REF!")) and fn:empty($item/@hidden)
        return $item

  let $wkSheetList   := () (: $wkBook/ssml:sheets/ssml:sheet :)
  
  let $wkSheetList      :=
    for $item in $wkBook/ssml:sheets/ssml:sheet [1 to 100]
      where fn:empty($item/@veryHidden)
        return $item
  
  let $rels          := map:get($table, "xl/_rels/workbook.xml.rels")/rel:Relationships
  let $sharedStrings := map:get($table, "xl/sharedStrings.xml")/ssml:sst/ssml:si/ssml:t/text()

  let $workSheets :=
    element { fn:QName($NS, "worksheets") }
    {
      for $ws in $wkSheetList
        let $wkSheetKey := "xl/"||xs:string($rels/rel:Relationship[@Id=$ws/@wbrel:id/fn:string()]/@Target)
        let $relWkSheet := map:get($table, $wkSheetKey)
        let $dim := $relWkSheet/ssml:worksheet/ssml:dimension/@ref/fn:string()
        where fn:empty($ws/@state)
          return
            element { fn:QName($NS, "worksheet") }
            {
              element { fn:QName($NS, "name") } { $ws/@name/fn:string() },
              element { fn:QName($NS, "key") } { $wkSheetKey },
              element { fn:QName($NS, "dimension") }
              {
                element { fn:QName($NS, "topLeft") } { fn:tokenize($dim, ":") [1] },
                element { fn:QName($NS, "bottomRight") } { fn:tokenize($dim, ":") [2] }
              },
              element { fn:QName($NS, "sheetData") }
              {
                for $cell in $relWkSheet/ssml:worksheet/ssml:sheetData/ssml:row
                  let $row  := xs:string($cell/@r)
                  for $column in $cell/ssml:c
                    let $pos   := xs:string($column/@r)
                    let $col   := fn:tokenize($pos, "[\d]+")[1] (: Tokenize to support more than 1 char like ABC7, AAA8 :)
                    let $ref   := xs:string($column/@t)
                    let $value := xs:string($column/ssml:v)
                    let $val   := if ($ref eq "s") then $sharedStrings[xs:integer($value) + 1] else $value
                    let $type  := if ($ref eq "s") then "string" else "integer"
                    return
                      element { fn:QName($NS, "cell") }
                      {
                        element { fn:QName($NS, "col") }   { $col },
                        element { fn:QName($NS, "row") }   { $row },
                        element { fn:QName($NS, "pos") }   { $pos },
                        element { fn:QName($NS, "dtype") } { $type },
                        element { fn:QName($NS, "val") }   { $val }
                      }
              }
            }
    }

  (:
     1st Pass - create temp doc that has an special expand node.
     Expand node is used in the 2nd pass to expand the number of cells.
  :)
  let $defNamePass1Doc :=
        element { fn:QName($NS, "definedNames") }
        {
          for $dn in $defnames
            let $att    := xs:string($dn/@name)
            
            (: There can be multiple dname items: 'T010'!$A$1:$O$56,'T010'!$A$57:$K$77 :)
            let $item1  := fn:tokenize($dn/text(), ",") [1]
            
            (: Use item1 for now. Add multiple items later :) 
            let $sheet  := fn:replace(fn:tokenize($item1, "!") [1], "'", "")

            let $cell   := fn:tokenize($item1, "!") [2]
            let $pos    := fn:replace($cell, "\$", "")
            
            let $pos1   := fn:tokenize($pos, ":") [1]
            let $pos2   := fn:tokenize($pos, ":") [2]
            
            let $col    := fn:tokenize($pos1, "[0-9]") [1]
            
            let $col1 := fn:tokenize($pos1, "[\d]+")[1]
            let $col2 := fn:tokenize($pos2, "[\d]+")[1]

            let $row1   := fn:tokenize($pos1, "[A-Za-z]+") [2]
            let $row2   := fn:tokenize($pos2, "[A-Za-z]+") [2]
            
            let $lblCol      := $col1
            let $val         := local:getValue($row1, $col1, $sheet, $table)
            let $rowLabel    := local:findRowLabel($row1, $col1, $sheet, $table)
            let $columnLabel := local:findColumnLabel($row1, $col1, $sheet, $table)
              where
                fn:empty($dn/@hidden)
                (: and fn:not(fn:starts-with($att, "_")) :)
                return
                  element { fn:QName($NS, "definedName") }
                  {
                    element { fn:QName($NS, "dname") }       { $att },
                    element { fn:QName($NS, "rowLabel") }    { $rowLabel },
                    element { fn:QName($NS, "columnLabel") } { $columnLabel },
                    element { fn:QName($NS, "sheet") }       { $sheet },
                    element { fn:QName($NS, "col1") }        { $col1 },
                    element { fn:QName($NS, "row1") }        { $row1 },
                    element { fn:QName($NS, "pos1") }        { $pos1 },
                    element { fn:QName($NS, "col2") }        { $col2 },
                    element { fn:QName($NS, "row2") }        { $row2 },
                    element { fn:QName($NS, "pos2") }        { $pos2 },
                    element { fn:QName($NS, "dvalue") }      { $val }
                  }
        }

  let $dnExpansionDoc := local:expandDoc($defNamePass1Doc, $table)
  
  let $unSortedDoc :=
      element { fn:QName($NS, "definedNames") }
      {
        $dnExpansionDoc/node(),
        for $d in $defNamePass1Doc/tax:definedName
          where fn:not(fn:empty($d/tax:pos/text()))
            return
              element { fn:QName($NS, "definedName") }
              {
                  element { fn:QName($NS, "dname") }       { $d/tax:dname/text() },
                  element { fn:QName($NS, "rowLabel") }    { $d/tax:rowLabel/text() },
                  element { fn:QName($NS, "columnLabel") } { $d/tax:columnLabel/text() },
                  element { fn:QName($NS, "sheet") }       { $d/tax:sheet/text() },
                  element { fn:QName($NS, "col") }         { $d/tax:col/text() },
                  element { fn:QName($NS, "row") }         { $d/tax:row/text() },
                  element { fn:QName($NS, "pos") }         { $d/tax:pos/text() },
                  element { fn:QName($NS, "dvalue") }      { $d/tax:dvalue/text() }
              }
      }
  
  let $newDefNameDoc :=
      element { fn:QName($NS, "definedNames") }
      {
        for $i in $unSortedDoc/tax:definedName
          let $row   := xs:integer($i/tax:row/text())
          let $seq   :=
            if ($row lt 10) then
              $i/tax:col/text()||"0"||$i/tax:row/text()
            else
              $i/tax:pos/text()
          let $dname := $i/tax:dname/text()
          order by $seq, $dname
            return $i
      }

  let $doc :=
    element { fn:QName($NS, "workbook") }
    {
      element { fn:QName($NS, "meta") }
      {
        element { fn:QName($NS, "type") }      { "template" },
        element { fn:QName($NS, "user") }      { $user },
        element { fn:QName($NS, "client") }    { "Thomson Reuters" },
        element { fn:QName($NS, "creator") }   { map:get($table, "docProps/core.xml")/core:coreProperties/dc:creator/text() },
        element { fn:QName($NS, "file") }      { local:generateFileUri($user, $zipFile) },
        element { fn:QName($NS, "lastModifiedBy") } { map:get($table, "docProps/core.xml")/core:coreProperties/core:lastModifiedBy/text() },
        element { fn:QName($NS, "created") }   { map:get($table, "docProps/core.xml")/core:coreProperties/dcterms:created/text() },
        element { fn:QName($NS, "modified") }  { map:get($table, "docProps/core.xml")/core:coreProperties/dcterms:modified/text() }
      },
      element { fn:QName($NS, "feed") }
      {
        $newDefNameDoc,
        $workSheets
      }
    }

  return $doc
};

let $excelFileName := "/tmp/users/garyrusso/ey original template.xlsx"

let $userNum      := 3
let $padUserNum   := ingest:padNum($userNum)
let $user         := "janedoe"||$padUserNum
let $userFullName := "Jane Doe "||$padUserNum
let $dir          := "/user/"||$user||"/"

let $binFileUri := fn:replace(ingest:generateFileUri($user, $excelFileName, $userNum), " ", "-")

let $excelFile    := xdmp:document-get($excelFileName, $BIN-OPTIONS)

let $doc     := local:extractSpreadsheetData($user, $excelFile)
let $dir     := "/user/"||$user||"/"
let $uri     := $dir||xdmp:hash64($doc)||".xml"
let $fileUri := local:generateFileUri($user, $zipFile)

return
(
  xdmp:elapsed-time(),
  $uri, $fileUri,
  (:
  xdmp:binary-size($binDoc/binary())
  $doc/tax:feed/tax:worksheets/tax:worksheet
  $uri, $fileUri,
  fn:count($doc/tax:feed/tax:definedNames/tax:definedName),
  $doc
  xdmp:document-insert($uri, $doc, xdmp:default-permissions(), ("spreadsheet")),
  xdmp:document-insert($fileUri, $binDoc, xdmp:default-permissions(), ("binary"))
  :)
)

return $docs
