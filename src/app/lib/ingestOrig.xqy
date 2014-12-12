(:
 :
 : Common Ingest Functions used for Spreadsheet Generator.
 :
 : @author gary.russo@thomsonreuters.com
 :
 :)

xquery version "1.0-ml";

module namespace ingest = "http://marklogic.com/roxy/lib/ingestOrig";

import module namespace ssheet = "http://marklogic.com/roxy/lib/ssheet" at "/app/lib/spreadsheet.xqy";

declare namespace tax  = "http://tax.thomsonreuters.com";

declare namespace zip     = "xdmp:zip";
declare namespace ssml    = "http://schemas.openxmlformats.org/spreadsheetml/2006/main";
declare namespace mc      = "http://schemas.openxmlformats.org/markup-compatibility/2006";
declare namespace rel     = "http://schemas.openxmlformats.org/package/2006/relationships";
declare namespace r       = "http://schemas.openxmlformats.org/officeDocument/2006/relationships";
declare namespace wsheet  = "http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet";
declare namespace core    = "http://schemas.openxmlformats.org/package/2006/metadata/core-properties";
declare namespace dcterms = "http://purl.org/dc/terms/";
declare namespace dc      = "http://purl.org/dc/elements/1.1/";


(: declare option xdmp:mapping "false"; :)

declare variable $NS := "http://tax.thomsonreuters.com";
declare variable $OPTIONS as element () :=
                 <options xmlns="xdmp:zip-get">
                   <format>xml</format>
                 </options>;

(:~
 : Iterate the network directory where the spreadsheet files (xslx files) reside.
 : Traverses the network directory recursively.
 :
 : @param $path The network directory where the XLSX files reside.
 :
 : Returns the complete list of XLSX files.
 :)
declare function ingest:loadDirectory($path as xs:string)
{
  try
  {
    for $entry in xdmp:filesystem-directory($path)/dir:entry
      let $subpath := $entry/dir:pathname/text()
        return
          if ( $entry/dir:type = 'directory' ) then
            ingest:loadDirectory($subpath)
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
declare function ingest:getIsoDate($days as xs:string)
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

declare function ingest:getFilingDate()
{
  let $dates :=
      element { "dates" }
      {
        element { "date" }
        {
          element { "days" } { "41940" },
          element { "isoDate" }   { "2014-10-28" }
        },
        element { "date" }
        {
          element { "days" } { "41941" },
          element { "isoDate" }   { "2014-10-29" }
        },
        element { "date" }
        {
          element { "days" } { "41942" },
          element { "isoDate" }   { "2014-10-30" }
        },
        element { "date" }
        {
          element { "days" } { "41943" },
          element { "isoDate" }   { "2014-10-31" }
        },
        element { "date" }
        {
          element { "days" } { "41944" },
          element { "isoDate" }   { "2014-11-01" }
        },
        element { "date" }
        {
          element { "days" } { "41945" },
          element { "isoDate" }   { "2014-11-02" }
        },
        element { "date" }
        {
          element { "days" } { "41946" },
          element { "isoDate" }   { "2014-11-03" }
        },
        element { "date" }
        {
          element { "days" } { "41947" },
          element { "isoDate" }   { "2014-11-04" }
        },
        element { "date" }
        {
          element { "days" } { "41948" },
          element { "isoDate" }   { "2014-11-05" }
        },
        element { "date" }
        {
          element { "days" } { "41949" },
          element { "isoDate" }   { "2014-11-06" }
        }
      }

  let $random := xdmp:random(10)
  let $idx    := if ($random eq 0) then 1 else $random

  return
    $dates/date[$idx]
};

(:~
 : Get Value from Defined Name
 :
 : @param $cell
 : @param $doc
 :)
declare function ingest:getValue($col as xs:string, $row as xs:string, $sheetName as xs:string, $table as map:map)
{
  let $wkBook        := map:get($table, "xl/workbook.xml")/ssml:workbook/ssml:sheets/ssml:sheet
  let $rels          := map:get($table, "xl/_rels/workbook.xml.rels")/rel:Relationships
  let $sharedStrings := map:get($table, "xl/sharedStrings.xml")/ssml:sst/ssml:si/ssml:t/text()

  let $wkSheetKey := "xl/"||xs:string($rels/rel:Relationship[@Id=$wkBook[@name=$sheetName]/@r:id]/@Target)

  let $wkSheet := map:get($table, $wkSheetKey)
  let $item     := $wkSheet/ssml:worksheet/ssml:sheetData/ssml:row[@r=$row]/ssml:c[@r=$col||$row]

  let $ref     := $item/@t
  let $value   := xs:string($item/ssml:v)

  let $retVal  := if ($ref eq "s") then $sharedStrings[xs:integer($value) + 1] else $value

  return $retVal
};

(:~
 : Entry point to a recursive function.
 :
 : @param $row
 :)
declare function ingest:findRowLabel($col as xs:string, $row as xs:string, $sheetName as xs:string, $table as map:map) as xs:string*
{
  let $leftLabelVal := ingest:getRowLabelValue($row, $col, $sheetName, $table)

  return $leftLabelVal
};

declare function ingest:getRowLabelValue($row as xs:string, $col as xs:string, $sheetName as xs:string, $table)
{
  let $pattern  := "[a-zA-Z]"

  let $leftCell := ingest:getLeftCell($col)

  return
    if (fn:matches(ingest:getValue($leftCell, $row, $sheetName, $table), $pattern) or
        (fn:string-to-codepoints($leftCell) lt 66)) then
      ingest:getValue($leftCell, $row, $sheetName, $table)
    else
      ingest:getRowLabelValue($row, $leftCell, $sheetName, $table)
};

declare function ingest:getLeftCell($col as xs:string)
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
declare function ingest:findColumnLabel($col as xs:string, $row as xs:string, $sheetName as xs:string, $table as map:map) (: as xs:string* :)
{
  let $leftLabelVal :=
    if (fn:string-length($row) = 0) then ""
    else
      ingest:getColumnLabelValue(xs:integer($row), $col, $sheetName, $table)

  return $leftLabelVal
};

declare function ingest:getColumnLabelValue($row as xs:integer, $col as xs:string, $sheetName as xs:string, $table)
{
  let $pattern  := "[a-zA-Z]"
  
  let $rows :=
    for $n in (1 to $row)
      return
        ($row + 1) - $n

  let $labels :=
    for $row in $rows
      let $label := ingest:getValue($col, xs:string($row), $sheetName, $table)
        where fn:matches($label, $pattern)
          return
            $label

  return $labels[1]
};

(:~
 : Left Pad Number with at most 3 zeros
 :
 : @param $cell
 :)
declare function ingest:padNum($n as xs:integer)
{
  let $sNum := xs:string($n)
  let $padNum :=
      if (fn:string-length($sNum) eq 1) then
        "000"||$sNum
      else
      if (fn:string-length($sNum) eq 2) then
        "00"||$sNum
      else
      if (fn:string-length($sNum) eq 3) then
        "0"||$sNum
      else
        $sNum

  return $padNum
};

(:~
 : Generate File URI
 :
 : @param $cell
 :)
declare function ingest:generateFileUri($user as xs:string, $fileName as xs:string, $n as xs:integer)
{
  let $newFileName := fn:tokenize(fn:replace($fileName, "workpaper1", "workpaper"), "\.")[1]||ingest:padNum($n)||".xlsx"
  
  let $fileUri := "/user/"||$user||"/files/"||fn:tokenize($newFileName, "/")[fn:last()]
  
  return $fileUri
};

(:~
 : Expansion Element
 :
 : @param $dn, $row, $col
 :)
declare function ingest:expansionElement($dn as node(), $row as xs:string, $col as xs:string, $table as map:map)
{
  let $newPos      := $col||$row
  let $sheetName   := $dn/tax:sheet/text()
  let $dname       := $dn/tax:dname/text()
  let $rowLabel    := ingest:findRowLabel($col, $row, $sheetName, $table)
  let $columnLabel := ingest:findColumnLabel($col, $row, $sheetName, $table)
  let $newValue    := ingest:getValue($col, $row, $sheetName, $table)

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
        element { fn:QName($NS, "dvalue") }      { $newValue }
      }

  return $doc
};

(:~
 : Column Expansion
 :
 : @param $doc
 :)
declare function ingest:columnExpandDoc($dn as node(), $table as map:map)
{
  let $col1 := fn:string-to-codepoints($dn/tax:col1/text())
  let $col2 := fn:string-to-codepoints($dn/tax:col2/text())

  let $doc :=
    for $col in ($col1 to $col2)
      let $row := $dn/tax:row1/text()
      let $newCol := fn:codepoints-to-string($col)
        return
          ingest:expansionElement($dn, xs:string($row), $newCol, $table)

  return $doc
};

(:~
 : Row Expansion
 :
 : @param $doc
 :)
declare function ingest:rowExpandDoc($dn as node(), $table as map:map)
{
  let $doc :=
    for $row in ((xs:integer($dn/tax:row1/text())) to xs:integer($dn/tax:row2/text()))
      let $col := $dn/tax:col1/text()
        return
          ingest:expansionElement($dn, $col, xs:string($row), $table)
                  
  return $doc
};

(:~
 : Column and Row Expansion
 :
 : @param $doc
 :)
declare function ingest:columnRowExpandDoc($dn as node(), $table as map:map)
{
  let $doc :=
    for $row in ((xs:integer($dn/tax:row1/text())) to xs:integer($dn/tax:row2/text()))
    
      let $col1 := fn:string-to-codepoints($dn/tax:col1/text())
      let $col2 := fn:string-to-codepoints($dn/tax:col2/text())
    
      return
        for $col in ($col1 to $col2)
          let $newCol := fn:codepoints-to-string($col)
            return
              ingest:expansionElement($dn, xs:string($row), $newCol, $table)

  return $doc
};

(:~
 : Column and Row Expansion
 :
 : @param $doc
 :)
declare function ingest:expandDoc($doc as node(), $table as map:map)
{
  let $newDoc :=
    element { fn:QName($NS, "definedNames") }
    {
      for $dn in $doc/tax:definedName
        return
          if (fn:empty($dn/tax:row2/text())) then
          (
            (: No Expansion :)
            ingest:expansionElement($dn, xs:string($dn/tax:row1/text()), $dn/tax:col1/text(), $table)
          )
          else
          if (($dn/tax:row1/text() ne $dn/tax:row2/text()) and ($dn/tax:col1/text() ne $dn/tax:col2/text())) then
          (
            (: Row and Column Expansion :)
            ingest:columnRowExpandDoc($dn, $table)
          )
          else
          if ($dn/tax:row1/text() eq $dn/tax:row2/text()) then
          (
            (: Column Expansion :)
            ingest:columnExpandDoc($dn, $table)
          )
          else
          if ($dn/tax:col1/text() eq $dn/tax:col2/text()) then
          (
            (: Row Expansion :)
            ingest:rowExpandDoc($dn, $table)
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
declare function ingest:extractSpreadsheetData($user as xs:string, $excelFile as node(), $fileUri as xs:string)
{
  let $exclude :=
  (
    "[Content_Types].xml", "docProps/app.xml", "xl/theme/theme1.xml", "xl/styles.xml", "_rels/.rels",
    "xl/vbaProject.bin", "xl/media/image1.png"
  )

  let $table := map:map()
  
  let $docs :=
    for $x in xdmp:zip-manifest($excelFile)//zip:part/text()
      where (($x = $exclude) eq fn:false()) and fn:not(fn:starts-with($x, "xl/printerSettings/printerSettings"))
        return
          map:put($table, $x, xdmp:zip-get($excelFile, $x, $OPTIONS))

  let $wkBook        := map:get($table, "xl/workbook.xml")/ssml:workbook
  
  let $defnames      :=
    for $item in $wkBook/ssml:definedNames/node()
      where fn:not(fn:starts-with($item/text(), "#REF!"))
        return $item
    
  let $wkSheetList   := $wkBook/ssml:sheets/ssml:sheet
  let $rels          := map:get($table, "xl/_rels/workbook.xml.rels")/rel:Relationships
  let $sharedStrings := map:get($table, "xl/sharedStrings.xml")/ssml:sst/ssml:si/ssml:t/text()

  let $workSheets :=
    element { fn:QName($NS, "worksheets") }
    {
      for $ws in $wkSheetList
        let $wkSheetKey := "xl/"||xs:string($rels/rel:Relationship[@Id=$ws/@r:id/fn:string()]/@Target)
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
            let $val         := ingest:getValue($col1, $row1, $sheet, $table)
            let $rowLabel    := ingest:findRowLabel($col1, $row1, $sheet, $table)
            let $columnLabel := ingest:findColumnLabel($col1, $row1, $sheet, $table)
              where fn:not(fn:starts-with($att, "_")) and fn:empty($dn/@hidden)
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

  let $dnExpansionDoc := ingest:expandDoc($defNamePass1Doc, $table)
  
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
        element { fn:QName($NS, "type") }      { "workbook" },
        element { fn:QName($NS, "user") }      { $user },
        element { fn:QName($NS, "client") }    { "Thomson Reuters" },
        element { fn:QName($NS, "creator") }   { map:get($table, "docProps/core.xml")/core:coreProperties/dc:creator/text() },
        element { fn:QName($NS, "file") }      { $fileUri },
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
