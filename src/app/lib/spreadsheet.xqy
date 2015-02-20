(:
 :
 : Common Ingest Functions used for Spreadsheet Generator.
 :
 : @author gary.russo@thomsonreuters.com
 :
 :)

xquery version "1.0-ml";

module namespace ssheet = "http://marklogic.com/roxy/lib/ssheet";

import module namespace mem    = "http://xqdev.com/in-mem-update"       at '/MarkLogic/appservices/utils/in-mem-update.xqy';

declare namespace zip     = "xdmp:zip";
declare namespace ssml    = "http://schemas.openxmlformats.org/spreadsheetml/2006/main";
declare namespace rel     = "http://schemas.openxmlformats.org/package/2006/relationships";
declare namespace wbrel   = "http://schemas.openxmlformats.org/officeDocument/2006/relationships";
declare namespace wsheet  = "http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet";
declare namespace core    = "http://schemas.openxmlformats.org/package/2006/metadata/core-properties";
declare namespace dcterms = "http://purl.org/dc/terms/";
declare namespace dc      = "http://purl.org/dc/elements/1.1/";
declare namespace tax     = "http://tax.thomsonreuters.com";

declare variable $NS     := "http://tax.thomsonreuters.com";
declare variable $SSMLNS := "http://schemas.openxmlformats.org/spreadsheetml/2006/main";

declare variable $OPTIONS as element () :=
                 <options xmlns="xdmp:zip-get">
                   <format>xml</format>
                 </options>;

(: declare option xdmp:mapping "false"; :)

declare function ssheet:generate-simple-xl-ooxml
(
  $relsRels as node(),
  $contentTypes as node(),
  $appDoc as node(),
  $coreDoc as node(),
  $customDoc as node(),
  $wkBookRels as node(),
  $calcChain as node(),
  $drawings as node(),
  $sharedStrings as node(),
  $styles as node(),
  $theme as node(),
  $wkBook as node(),
  $sheet1Rels as node(),
  $sheet1 as node(),
  $sheet2 as node(),
  $sheet3 as node(),
  $printerBinDoc as node()
) as binary()
{
  let $manifest :=
    <parts xmlns="xdmp:zip">
      <part>_rels/.rels</part>
      <part>[Content_Types].xml</part>
      <part>docProps/app.xml</part>
      <part>docProps/core.xml</part>
      <part>docProps/custom.xml</part>
      <part>xl/_rels/workbook.xml.rels</part>
      <part>xl/calcChain.xml</part>
      <part>xl/drawings/drawing1.xml</part>
      <part>xl/sharedStrings.xml</part>
      <part>xl/styles.xml</part>
      <part>xl/theme/theme1.xml</part>
      <part>xl/workbook.xml</part>
      <part>xl/worksheets/_rels/sheet1.xml.rels</part>
      <part>xl/worksheets/sheet1.xml</part>
      <part>xl/worksheets/sheet2.xml</part>
      <part>xl/worksheets/sheet3.xml</part>
      <part>xl/printerSettings/printerSettings1.bin</part>
    </parts>
    
  let $parts :=
    (
      $relsRels,
      $contentTypes,
      $appDoc,
      $coreDoc,
      $customDoc,
      $wkBookRels,
      $calcChain,
      $drawings,
      $sharedStrings,
      $styles,
      $theme,
      $wkBook,
      $sheet1Rels,
      $sheet1,
      $sheet2,
      $sheet3,
      $printerBinDoc
    )

  return
    xdmp:zip-create($manifest, $parts)
};

declare function ssheet:updateCellsbyDName($sheetKey as xs:string, $dnodes as node(), $table as map:map)
{
  (: fixed at 10 changes for now :)

  (: Add code to get sheet name from workbook and workbook rels (xl/_rels/workbook.xml.rels) :)
  let $wkBook       := map:get($table, "xl/workbook.xml")
  let $rels         := map:get($table, "xl/_rels/workbook.xml.rels")
  let $sheet        := map:get($table, $sheetKey)
(:
  let $doc2 := mem:node-replace($doc1/feed/row/c[@r="F4"]/v, $newNodes/v[1])
  let $doc3 := mem:node-replace($doc2/feed/row/c[@r="G4"]/v, $newNodes/v[2])
:)
  let $dname := $dnodes/tax:dname[1]
  let $val   := $dnodes/tax:dname[1]/tax:value/text()

  let $doc := ssheet:updateCell($sheet, $dnodes/tax:dname[2], $table)

  return $doc
};

declare function ssheet:updateCell($sheet as node(), $dn as node(), $table as map:map)
{
  let $dname := $dn/tax:name/text()
  let $val   := $dn/tax:value/text()
  
  let $log := xdmp:log("1 -------------- $dname name: '"||$dname||"'")
  let $log := xdmp:log("2 -------------- $dname val:  '"||$val||"'")

  let $cell := ssheet:getCellsbyDName($dname, $table)

  let $row  := $cell/cells/cell[1]/row/text()
  let $pos  := $cell/cells/cell[1]/pos/text()

  let $sheetCell    := $sheet/ssml:worksheet/ssml:sheetData/ssml:row[@r=$row]/ssml:c[@r=$pos]/ssml:v
  let $newSheetCell := element { fn:QName($SSMLNS, "v") } { $val }

  let $log := xdmp:log("3 -------------- $sheetCell val: '"||$sheetCell/text()||"'")
  let $log := xdmp:log("  -------------- ")

  let $doc :=
    if (fn:empty($sheetCell)) then
      mem:node-insert-child($sheet/ssml:worksheet/ssml:sheetData/ssml:row[@r=$row]/ssml:c[@r=$pos], $newSheetCell)
    else
      mem:node-replace($sheetCell, $newSheetCell)
    
  let $log := xdmp:log("4 -------------- $newSheetCell row: "||$row)
  let $log := xdmp:log("5 -------------- $newSheetCell pos: "||$pos)
  let $log := xdmp:log("6 -------------- $newSheetCell val: '"||$doc/ssml:worksheet/ssml:sheetData/ssml:row[@r=$row]/ssml:c[@r=$pos]/ssml:v/text()||"'")
  
  return $doc
};

declare function ssheet:getCellsbyDName($dname as xs:string, $table as map:map)
{
  (: Test Cases :)
  (:
    let $dn := "Store!$E$15:$E$21"
    let $dn := "Store!$E$15:$I$15"
    let $dn := "Store!$E$15:$G$21"
  :)
  
  let $wkBook        := map:get($table, "xl/workbook.xml")
  let $dn := $wkBook/ssml:workbook/ssml:definedNames/ssml:definedName[@name=$dname]/text()

  (: There can be multiple dname items: 'T010'!$A$1:$O$56,'T010'!$A$57:$K$77 :)
  let $item1  := fn:tokenize($dn, ",") [1]
  
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

  let $doc :=
    element { "dnameInfo" }
    {
      element { "wksheet" }  { $sheet },
      element { "cells" }
      {
        element { "cell" }
        {
          element { "pos" }  { $pos1 },
          element { "col" }  { $col1 },
          element { "row" }  { $row1 }
        }
        ,
        if (fn:empty($pos2)) then ()
        else
        (
          if (($row1 ne $row2) and ($col1 ne $col2)) then
          (
            (: Row and Column Expansion :)
            for $row in (xs:integer($row1) to xs:integer($row2))
            
              let $cpCol1 := fn:string-to-codepoints($col1)
              let $cpCol2 := fn:string-to-codepoints($col2)
            
              return
                for $col in ($cpCol1 to $cpCol2)
                  let $newCol := fn:codepoints-to-string($col)
                  let $newPos := $newCol||$row
                    where $newPos ne $pos1
                      return
                        element { "cell" }
                        {
                          element { "notes" }  { "Row and Column Expansion"},
                          element { "pos" }  { $newPos },
                          element { "col" }  { $newCol },
                          element { "row" }  { $row }
                        }
          )
          else
          if ($row1 eq $row2) then
          (
            (: Column Expansion :)
            let $cpCol1 := fn:string-to-codepoints($col1)
            let $cpCol2 := fn:string-to-codepoints($col2)
          
            return
              for $col in ($cpCol1 to $cpCol2)
                let $newCol := fn:codepoints-to-string($col)
                let $newPos := $newCol||$row1
                  where $newCol ne $col1
                    return
                      element { "cell" }
                      {
                        element { "notes" }  { "Column Expansion"},
                        element { "pos" }  { $newPos },
                        element { "col" }  { $newCol },
                        element { "row" }  { $row1 }
                      }
          )
          else
          if ($col1 eq $col2) then
          (
            (: Row Expansion :)
            for $row in ((xs:integer($row1)) to xs:integer($row2))
              let $newRow := xs:string($row)
              let $newPos := $col1||$newRow
                where $newRow ne $row1
                  return
                    element { "cell" }
                    {
                      element { "notes" }  { "Row Expansion"},
                      element { "pos" }  { $newPos },
                      element { "col" }  { $col1 },
                      element { "row" }  { $newRow }
                    }
          )
          else ()
        )
      }
    }
  
  return $doc
};

declare function ssheet:createSpreadsheetFile(
  $user as xs:string,
  $filingDate as xs:string,
  $excelUri as xs:string,
  $userData as node())
{
  let $excelFile := fn:doc($excelUri)
  
  let $table := map:map()
  
  let $docs :=
          for $x in xdmp:zip-manifest($excelFile)//zip:part/text()
            where fn:not(fn:ends-with($x, ".bin")) and fn:not(fn:ends-with($x, ".png"))
              return
              (
                map:put($table, $x, xdmp:zip-get($excelFile, $x, $OPTIONS)),
                $x
              )
  
  let $contentTypes  := map:get($table, "[Content_Types].xml")
  let $appDoc        := map:get($table, "docProps/app.xml")
  let $coreDoc       := map:get($table, "docProps/core.xml")
  let $customDoc     := map:get($table, "docProps/custom.xml")
  let $calcChain     := map:get($table, "xl/calcChain.xml")
  let $drawings      := map:get($table, "xl/drawings/drawing1.xml")
  let $sharedStrings := map:get($table, "xl/sharedStrings.xml")
  let $styles        := map:get($table, "xl/styles.xml")
  let $theme         := map:get($table, "xl/theme/theme1.xml")
  let $wkBook        := map:get($table, "xl/workbook.xml")
  let $sheet1        := map:get($table, "xl/worksheets/sheet1.xml")
  let $sheet2        := map:get($table, "xl/worksheets/sheet2.xml")
  let $sheet3        := map:get($table, "xl/worksheets/sheet3.xml")
  let $sheet1Rels    := map:get($table, "xl/worksheets/_rels/sheet1.xml.rels")
  let $wkBookRels    := map:get($table, "xl/_rels/workbook.xml.rels")
  let $relsRels      := map:get($table, "_rels/.rels")
  let $printerBinDoc := xdmp:zip-get($excelFile, "xl/printerSettings/printerSettings1.bin")

  let $newSheet1 := ssheet:updateCellsbyDName("xl/worksheets/sheet1.xml", $userData, $table)

  let $binDoc :=
    ssheet:generate-simple-xl-ooxml(
      $relsRels,
      $contentTypes,
      $appDoc,
      $coreDoc,
      $customDoc,
      $wkBookRels,
      $calcChain,
      $drawings,
      $sharedStrings,
      $styles,
      $theme,
      $wkBook,
      $sheet1Rels,
      $newSheet1,
      $sheet2,
      $sheet3,
      $printerBinDoc
     )

  return
  (
    (: xdmp:document-insert($fileUri, $binDoc, xdmp:default-permissions(), ("binary")), :)
    $binDoc
  )
};

