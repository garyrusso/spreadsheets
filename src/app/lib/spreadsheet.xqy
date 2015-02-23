(:
 :
 : Common Ingest Functions used for Spreadsheet Generator.
 :
 : @author gary.russo@thomsonreuters.com
 :
 :)

xquery version "1.0-ml";

module namespace ssheet = "http://marklogic.com/roxy/lib/ssheet";

import module namespace mem    = "http://xqdev.com/in-mem-update" at '/MarkLogic/appservices/utils/in-mem-update.xqy';

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
      (: $calcChain, :)
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

declare function ssheet:updateCellsbyDName($sheetKey as xs:string, $userData as node(), $table as map:map)
{
  (: Add code to get sheet name from workbook and workbook rels (xl/_rels/workbook.xml.rels) :)
  let $wkBook       := map:get($table, "xl/workbook.xml")
  let $rels         := map:get($table, "xl/_rels/workbook.xml.rels")
  let $sheet        := map:get($table, $sheetKey)

  (: $sheet/ssml:worksheet/ssml:sheetData :)
  let $sheetDataNode := $sheet/ssml:worksheet/ssml:sheetData

  let $userDataCellValues := ssheet:getUserDataCellPosAndValue($userData, $table)

  (: rebuild the sheetData node :)
  let $sheetData :=
    element { fn:QName($SSMLNS,"sheetData") }
    {
      for $row in $sheetDataNode/ssml:row
        return
          element { fn:QName($SSMLNS,"row") }
          {
            for $a in $row/@*
              let $aname  := fn:node-name($a)
              return
                attribute { $aname } { $a },
            for $cnode in $row/ssml:c
              let $pos := xs:string($cnode/@r)

              (: selector - is this cellPos referenced in the dname list? :)
              let $newVal := $userDataCellValues/cell[pos=$pos]/val/text()

              let $childNodes := $cnode/ssml:*
              return
                element { fn:QName($SSMLNS,"c") }
                {
                  for $a in $cnode/@*
                    return
                      attribute { fn:node-name($a) } { $a },
                  if ((fn:count($childNodes) eq 0) and (fn:string-length($newVal) gt 0)) then
                    element { fn:QName($SSMLNS,"v") } { $newVal }
                  else
                    for $child in $cnode/ssml:*
                      let $childName := fn:node-name($child)
                      let $childNodeName := ""||$childName (: used this to convert to xs:string() :)
                        return
                        (
                          if ($childNodeName eq "v") then
                          (
                            if (fn:empty($newVal)) then
                              element { $childName } { $child/text() }
                            else
                              element { $childName } { $newVal }
                          )
                          else
                            element { $childName } { $child/text() }
                        )
                }
          }
    }

  let $newDoc := mem:node-replace($sheet/ssml:worksheet/ssml:sheetData, $sheetData)

  return $newDoc
};

declare function ssheet:getUserDataCellPosAndValue($userData as node(), $table as map:map)
{
  let $dnames := $userData/tax:userData/tax:feed/tax:dnames/tax:dname/tax:name/text()

  let $doc :=
    element { "cells" }
    {
      for $dname in $dnames
        let $cellNode := ssheet:getDNamePosAndValue($dname, $userData, $table)
        return
          $cellNode/cell
    }

  return $doc
};

declare function ssheet:getDNamePosAndValue($dname as xs:string, $userData as node(), $table as map:map)
{
  let $dnamePositions := ssheet:getCellsbyDName($dname, $table)
  let $cells := $dnamePositions/cells/cell

  let $doc :=
    element { "cells" }
    {
      for $cell in $cells
        return
          element { "cell" }
          {
            element { "pos" }  { $cell/pos/text() },
            element { "val" }  { $userData/tax:userData/tax:feed/tax:dnames/tax:dname[tax:name=$dname]/tax:value/text() }
          }
    }
    
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

declare function ssheet:createSpreadsheetFileAndApplyUserData($excelUri as xs:string, $userData as node())
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

  (: GR001: Temp Fix for calcChain Error on File Open :)
  let $calcChain1 := document { element { fn:QName($SSMLNS, "calcChain") } { element { fn:QName($SSMLNS, "c") } { attribute { "r" } { "H3" }, attribute { "i" } { "1" } } } }

  let $binDoc :=
    ssheet:generate-simple-xl-ooxml(
      $relsRels,
      $contentTypes,
      $appDoc,
      $coreDoc,
      $customDoc,
      $wkBookRels,
      $calcChain1,
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
    $binDoc
};

declare function ssheet:createSpreadsheetFile($userData as node())
{
(:
  let $excelUri1 := $userData/../../tax:meta/tax:templateFile/text()
  let $excelUri2 := $userData/tax:userData/tax:meta/tax:templateFile/text()

  let $excelUri :=
    if (fn:string-length($excelUri1) gt 0) then
      $excelUri1
    else
      $excelUri2
:)
  let $excelUri := $userData/tax:userData/tax:meta/tax:templateFile/text()

  let $log := xdmp:log("1 ----- excelUri: "||$excelUri)

  let $binDoc :=
    if ((fn:string-length($excelUri) gt 0) and (fn:doc($excelUri))) then
      ssheet:createSpreadsheetFileAndApplyUserData($excelUri, $userData)
    else
      ()
  
  return
    if (fn:empty($binDoc)) then
      element {"status"} { "Invalid Excel Template File: "||"'"||$excelUri||"'" }
    else
      $binDoc
};

