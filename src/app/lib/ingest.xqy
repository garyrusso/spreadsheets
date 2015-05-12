(:
 :
 : Common Ingest Functions used for Spreadsheet Generator.
 :
 : @author gary.russo@thomsonreuters.com
 :
 :)

xquery version "1.0-ml";

module namespace ingest = "http://marklogic.com/roxy/lib/ingest";

import module namespace ssheet = "http://marklogic.com/roxy/lib/ssheet" at "/app/lib/spreadsheet.xqy";
import module namespace json   = "http://marklogic.com/json" at "/roxy/lib/json.xqy";

declare namespace tax  = "http://tax.thomsonreuters.com";

declare namespace zip     = "xdmp:zip";
declare namespace ssml    = "http://schemas.openxmlformats.org/spreadsheetml/2006/main";
declare namespace rel     = "http://schemas.openxmlformats.org/package/2006/relationships";
declare namespace wbrel   = "http://schemas.openxmlformats.org/officeDocument/2006/relationships";
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

declare variable $BIN-OPTIONS as element() := 
                 <options xmlns="xdmp:document-get">
                   <format>binary</format>
                 </options>;

(:~
 : Centralized Logging
 :
 : @param $file
 : @param $message
 :)
declare function ingest:log($file as xs:string, $level as xs:string, $message as xs:string)
{
  let $idateTime := xs:string(fn:current-dateTime())
  let $dateTime  := fn:substring($idateTime, 1, fn:string-length($idateTime)-6)

  return
    xdmp:log(fn:concat("1..... LOGGING $file: ", $file, " | dateTime: ", $dateTime, " | level: ", $level, " | message: ", $message))
};

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

declare function ingest:getTargetTaxBracket($bracket as xs:decimal) as xs:decimal
{
  let $rate :=
      if ($bracket eq 0.10) then
        0.10
      else
      if ($bracket eq 0.15) then
        0.10
      else
      if ($bracket eq 0.25) then
        0.15
      else
      if ($bracket eq 0.28) then
        0.25
      else
      if ($bracket eq 0.33) then
        0.28
      else
      if ($bracket eq 0.35) then
        0.33
      else
      if ($bracket eq 0.396) then
        0.35
      else
        0.396
        
  return $rate
};

declare function ingest:getTaxBracket($income as xs:decimal) as xs:decimal
{
(:
10 - 9075
15 - 9076 to 36900
25 - 36901 to 89350
28 - 89351 to 186350
33 - 186351 to 405100
35 - 405101 to 457600
39.6 - 457600
:)

  let $rate :=
      if ($income lt 9075) then
        0.10
      else
      if ($income ge 9076 and $income lt 36901) then
        0.15
      else
      if ($income ge 36901 and $income lt 89351) then
        0.25
      else
      if ($income ge 89351 and $income lt 186351) then
        0.28
      else
      if ($income ge 186351 and $income lt 405101) then
        0.33
      else
      if ($income ge 405101 and $income lt 406751) then
        0.35
      else
      if ($income ge 406751) then
        0.396
      else
        0.396
        
  return $rate
};

declare function ingest:buildTaxPlanDoc()
{
  let $c4  := xdmp:random(100000)
  let $c5  := xdmp:random(100000)
  let $c6  := xdmp:random(100000)
  let $c7  := xdmp:random(100000)
  let $c8  := xdmp:random(100000)
  let $c9  := xdmp:random(10000)
  let $c10 := xdmp:random(10000)
  
  let $c11 := $c4 + $c5 + $c6 + $c7 + $c8 + $c9 + $c10 

  let $d4 := xs:integer($c4 div 12)
  let $d5 := xs:integer($c5 div 12)
  let $d6 := xs:integer($c6 div 12)
  let $d7 := xs:integer($c7 div 12)
  let $d8 := xs:integer($c8 div 12)
  let $d9 := xs:integer($c9 div 12)
  let $d10 := xs:integer($c10 div 12)
  
  let $d11 := $d4 + $d5 + $d6 + $d7 + $d8 + $d9 + $d10 

  let $e4 := $c4 + $d4
  let $e5 := $c5 + $d5
  let $e6 := $c6 + $d6
  let $e7 := $c7 + $d7
  let $e8 := $c8 + $d8
  let $e9 := $c9 + $d9
  let $e10 := $c10 + $d10
  
  let $e11 := $e4 + $e5 + $e6 + $e7 + $e8 + $e9 + $e10 

  let $c14 := xdmp:random(1000)
  let $c15 := xdmp:random(1000)
  let $c16 := xdmp:random(1000)
  let $c17 := xdmp:random(1000)

  let $c18 := $c14 + $c15 + $c16 + $c17
  let $c19 := $c11 - $c18

  let $d14 := xs:integer($c14 div 12)
  let $d15 := xs:integer($c15 div 12)
  let $d16 := xs:integer($c16 div 12)
  let $d17 := xs:integer($c17 div 12)
  
  let $d18 := $d14 + $d15 + $d16 + $d17
  let $d19 := $d11 - $d18

  let $e14 := $c14 + $d14
  let $e15 := $c15 + $d15
  let $e16 := $c16 + $d16
  let $e17 := $c17 + $d17

  let $e18 := $e14 + $e15 + $e16 + $e17
  let $e19 := $e11 - $e18

  let $c22 := xdmp:random(1000)
  let $c23 := xdmp:random(1000)
  let $c24 := xdmp:random(10000)
  let $c25 := xdmp:random(1000)
  let $c26 := xdmp:random(1000)
  let $c27 := xdmp:random(1000)
  let $c28 := xdmp:random(1000)
  let $c29 := xdmp:random(1000)

  let $c30 := $c22 + $c23 + $c24 + $c25 + $c26 + $c27 + $c28 + $c29

  let $d22 := xs:integer($c22 div 12)
  let $d23 := xs:integer($c23 div 12)
  let $d24 := xs:integer($c24 div 12)
  let $d25 := xs:integer($c25 div 12)
  let $d26 := xs:integer($c26 div 12)
  let $d27 := xs:integer($c27 div 12)
  let $d28 := xs:integer($c28 div 12)
  let $d29 := xs:integer($c29 div 12)

  let $d30 := $d22 + $d23 + $d24 + $d25 + $d26 + $d27 + $d28 + $d29

  let $e22 := $c22 + $d22
  let $e23 := $c23 + $d23
  let $e24 := $c24 + $d24
  let $e25 := $c25 + $d25
  let $e26 := $c26 + $d26
  let $e27 := $c27 + $d27
  let $e28 := $c28 + $d28
  let $e29 := $c29 + $d29

  let $e30 := $e22 + $e23 + $e24 + $e25 + $e26 + $e27 + $e28 + $e29

  let $c31 := xdmp:random(100000)
  let $valueOfExemptions := xdmp:random(10000)
  let $numAllowableExemptions := 5

  let $e32 := fn:max(($e30, $c31))
  let $e34 := $valueOfExemptions * $numAllowableExemptions
  let $e35 := $e34 + $e32
  let $e36 := fn:abs($e19 - $e35)

  let $calcTaxBracket := ingest:getTaxBracket($e36)
  
  let $itemizedDeductionPct := xs:integer(xs:float($e30 div $e19) * 100)

  let $doc :=
    element { "taxPlan" }
    {
      element { "grossIncome" }
      {
        element { "actual" }
        {
          element { "c4" }  { $c4 },
          element { "c5" }  { $c5 },
          element { "c6" }  { $c6 },
          element { "c7" }  { $c7 },
          element { "c8" }  { $c8 },
          element { "c9" }  { $c9 },
          element { "c10" }  { $c10 },
          element { "c11" }  { $c11 }
        },
        element { "estimated" }
        {
          element { "yearEnd" }
          {
            element { "d4" }  { $d4 },
            element { "d5" }  { $d5 },
            element { "d6" }  { $d6 },
            element { "d7" }  { $d7 },
            element { "d8" }  { $d8 },
            element { "d9" }  { $d9 },
            element { "d10" }  { $d10 },
            element { "d11" }  { $d11 }
          },
          element { "fullYear" }
          {
            element { "e4" }  { $e4 },
            element { "e5" }  { $e5 },
            element { "e6" }  { $e6 },
            element { "e7" }  { $e7 },
            element { "e8" }  { $e8 },
            element { "e9" }  { $e9 },
            element { "e10" }  { $e10 },
            element { "e11" }  { $e11 }
          }
        }
      },
      element { "adjGrossIncome" }
      {
        element { "actual" }
        {
          element { "c14" }  { $c14 },
          element { "c15" }  { $c15 },
          element { "c16" }  { $c16 },
          element { "c17" }  { $c17 },
          element { "c18" }  { $c18 },
          element { "c19" }  { $c19 }
        },
        element { "estimated" }
        {
          element { "yearEnd" }
          {
            element { "d14" }  { $d14 },
            element { "d15" }  { $d15 },
            element { "d16" }  { $d16 },
            element { "d17" }  { $d17 },
            element { "d18" }  { $d18 },
            element { "d19" }  { $d19 }
          },
          element { "fullYear" }
          {
            element { "e14" }  { $e14 },
            element { "e15" }  { $e15 },
            element { "e16" }  { $e16 },
            element { "e17" }  { $e17 },
            element { "e18" }  { $e18 },
            element { "e19" }  { $e19 }
          }
        }
      },
      element { "allowableItemizedDeductions" }
      {
        element { "actual" }
        {
          element { "c22" }  { $c22 },
          element { "c23" }  { $c23 },
          element { "c24" }  { $c24 },
          element { "c25" }  { $c25 },
          element { "c26" }  { $c26 },
          element { "c27" }  { $c27 },
          element { "c28" }  { $c28 },
          element { "c29" }  { $c29 },
          element { "c30" }  { $c30 },
          element { "c31" }  { $c31 },
          element { "c33" }  { $valueOfExemptions },
          element { "c34" }  { $numAllowableExemptions }
        },
        element { "estimated" }
        {
          element { "yearEnd" }
          {
            element { "d22" }  { $d22 },
            element { "d23" }  { $d23 },
            element { "d24" }  { $d24 },
            element { "d25" }  { $d25 },
            element { "d26" }  { $d26 },
            element { "d27" }  { $d27 },
            element { "d28" }  { $d28 },
            element { "d29" }  { $d29 },
            element { "d30" }  { $d30 }
          },
          element { "fullYear" }
          {
            element { "e22" }  { $e22 },
            element { "e23" }  { $e23 },
            element { "e24" }  { $e24 },
            element { "e25" }  { $e25 },
            element { "e26" }  { $e26 },
            element { "e27" }  { $e27 },
            element { "e28" }  { $e28 },
            element { "e29" }  { $e29 },
            element { "e30" }  { $e30 },
            element { "e32" }  { $e32 },
            element { "e34" }  { $e34 },
            element { "e35" }  { $e35 },
            element { "e36" }  { $e36 },
            element { "e37" }  { $calcTaxBracket },
            element { "e38" }  { xs:integer($e36 * .85) },
            element { "e39" }  { ingest:getTargetTaxBracket($calcTaxBracket) }
          },
          element { "itemizedDeductionPct" } { $itemizedDeductionPct }
        }
      }
    }

   return $doc
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

declare function ingest:getUserFullName()
{
  let $users :=
      element { "users" }
      {
        element { "user" }
        {
          element { "firstName" } { "Grace" },
          element { "lastName" }   { "Hopper" }
        },
        element { "user" }
        {
          element { "firstName" } { "Sandra Day" },
          element { "lastName" }   { "O'Conner" }
        },
        element { "user" }
        {
          element { "firstName" } { "Ruth Bader" },
          element { "lastName" }   { "Ginsberg" }
        },
        element { "user" }
        {
          element { "firstName" } { "Sonia" },
          element { "lastName" }   { "Sotomayor" }
        },
        element { "user" }
        {
          element { "firstName" } { "Elena" },
          element { "lastName" }   { "Kagan" }
        },
        element { "user" }
        {
          element { "firstName" } { "Anthony" },
          element { "lastName" }   { "Kennedy" }
        },
        element { "user" }
        {
          element { "firstName" } { "Marissa" },
          element { "lastName" }   { "Mayer" }
        },
        element { "user" }
        {
          element { "firstName" } { "Steve" },
          element { "lastName" }   { "Jobs" }
        },
        element { "user" }
        {
          element { "firstName" } { "Sheryl" },
          element { "lastName" }   { "Sandberg" }
        },
        element { "user" }
        {
          element { "firstName" } { "Elizabeth" },
          element { "lastName" }   { "Braham" }
        },
        element { "user" }
        {
          element { "firstName" } { "Sharlene" },
          element { "lastName" }  { "Abrams" }
        },
        element { "user" }
        {
          element { "firstName" } { "Brenda" },
          element { "lastName" }  { "Agius" }
        },
        element { "user" }
        {
          element { "firstName" } { "Angela" },
          element { "lastName" }  { "Ahrendts" }
        },
        element { "user" }
        {
          element { "firstName" } { "Betty" },
          element { "lastName" }  { "Alewine" }
        },
        element { "user" }
        {
          element { "firstName" } { "DeLisa" },
          element { "lastName" }  { "Alexander" }
        },
        element { "user" }
        {
          element { "firstName" } { "Mala" },
          element { "lastName" }  { "Anand" }
        },
        element { "user" }
        {
          element { "firstName" } { "Jo" },
          element { "lastName" }  { "Anderson" }
        },
        element { "user" }
        {
          element { "firstName" } { "Sheila M." },
          element { "lastName" }  { "Anderson" }
        },
        element { "user" }
        {
          element { "firstName" } { "Vicki L." },
          element { "lastName" }  { "Andrews" }
        },
        element { "user" }
        {
          element { "firstName" } { "Colleen" },
          element { "lastName" }  { "Arnold" }
        },
        element { "user" }
        {
          element { "firstName" } { "Susan L." },
          element { "lastName" }  { "Amato" }
        },
        element { "user" }
        {
          element { "firstName" } { "Fay" },
          element { "lastName" }  { "Arjomandi" }
        },
        element { "user" }
        {
          element { "firstName" } { "Lisa" },
          element { "lastName" }  { "Arthur" }
        },
        element { "user" }
        {
          element { "firstName" } { "Jocelyne" },
          element { "lastName" }  { "Attal" }
        },
        element { "user" }
        {
          element { "firstName" } { "Carolyn V." },
          element { "lastName" }  { "Aver" }
        },
        element { "user" }
        {
          element { "firstName" } { "Elizabeth L." },
          element { "lastName" }  { "Axelrod" }
        },
        element { "user" }
        {
          element { "firstName" } { "Andrea J." },
          element { "lastName" }  { "Ayers" }
        },
        element { "user" }
        {
          element { "firstName" } { "Silvia" },
          element { "lastName" }  { "Ayyoubi" }
        },
        element { "user" }
        {
          element { "firstName" } { "Maggie" },
          element { "lastName" }  { "Wu" }
        },
        element { "user" }
        {
          element { "firstName" } { "Peg" },
          element { "lastName" }  { "Wynn" }
        }
      }

  let $random := xdmp:random(29) + 1
  let $idx    := if ($random eq 0) then 1 else $random
  
  return
    $users/user[$idx]
};

declare function ingest:getUserFullNameJson()
{
  let $doc := ingest:getUserFullName()
  
  let $jdoc :=
    json:o((
      "firstName", $doc/firstName/text(),
      "lastName", $doc/lastName/text()
    ))
  
  return
    json:serialize($jdoc)
};

(:~
 : Get Value from Defined Name
 :
 : @param $cell
 : @param $doc
 :)
declare function ingest:getValue($row as xs:string, $col as xs:string, $sheetName as xs:string, $table as map:map)
{
  let $wkBook        := map:get($table, "xl/workbook.xml")/ssml:workbook/ssml:sheets/ssml:sheet
  let $rels          := map:get($table, "xl/_rels/workbook.xml.rels")/rel:Relationships
  
  (: Be sure to index from the /ssml:si element (not from /ssml:t element) :)
  let $sharedStrings := map:get($table, "xl/sharedStrings.xml")/ssml:sst/ssml:si

  let $wkSheetKey    := "xl/"||xs:string($rels/rel:Relationship[@Id=$wkBook[@name=$sheetName]/@wbrel:id]/@Target)

  let $wkSheet  := map:get($table, $wkSheetKey)
  let $item     := $wkSheet/ssml:worksheet/ssml:sheetData/ssml:row[@r=$row]/ssml:c[@r=$col||$row]

  let $ref     := $item/@t
  let $value   := xs:string($item/ssml:v)

  let $retVal  := if ($ref eq "s") then $sharedStrings[xs:integer($value) + 1]/ssml:t/text() else $value

  return $retVal
};

(:~
 : Entry point to a recursive function.
 :
 : @param $row
 :)
declare function ingest:findRowLabel($row as xs:string, $col as xs:string, $sheetName as xs:string, $table as map:map) as xs:string*
{
  let $leftLabelVal := ingest:getRowLabelValue($row, $col, $sheetName, $table)

  return $leftLabelVal
};

declare function ingest:getRowLabelValue($row as xs:string, $col as xs:string, $sheetName as xs:string, $table)
{
  let $pattern  := "[a-zA-Z]"

  let $leftCell := ingest:getLeftCell($col)

  return
    if (fn:matches(ingest:getValue($row, $leftCell, $sheetName, $table), $pattern) or
        (fn:string-to-codepoints($leftCell) lt 66)) then
      ingest:getValue($row, $leftCell, $sheetName, $table)
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
declare function ingest:findColumnLabel($row as xs:string, $col as xs:string, $sheetName as xs:string, $table as map:map) (: as xs:string* :)
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
      let $label := ingest:getValue(xs:string($row), $col, $sheetName, $table)
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
declare function ingest:generateFileUriOrig($user as xs:string, $fileName as xs:string, $n as xs:integer)
{
  let $newFileName := fn:tokenize(fn:replace($fileName, "workpaper1", "workpaper"), "\.")[1]||ingest:padNum($n)||".xlsx"
  
  let $fileUri := "/user/"||$user||"/files/"||fn:tokenize($newFileName, "/")[fn:last()]
  
  return $fileUri
};

(:~
 : Generate File URI
 :
 : @param $cell
 :)
declare function ingest:generateTemplateFileUri($client as xs:string, $fileName as xs:string)
{
  let $newFileName     := fn:tokenize($fileName, "/")[fn:last()]
  let $templateDirName := "/client/"||$client||"/template/"||fn:tokenize($newFileName, "\.")[1]
  
  return $templateDirName
};

(:~
 : Generate File URI
 :
 : @param $cell
 :)
declare function ingest:generateFileUri($user as xs:string, $fileName as xs:string, $n as xs:integer)
{
  let $newFileName := fn:tokenize(fn:replace($fileName, "workpaper1", "workpaper"), "\.")[1]||".xlsx"
  
  let $fileUri := "/user/"||$user||"/files/"||fn:tokenize($newFileName, "/")[fn:last()]
  
  return $fileUri
};

(:~
 : Centralized fucntion to create NameRef node.
 :
 : @params
 :)
declare function ingest:createNameRefNode(
  $sheetName as xs:string,
  $rangeName as xs:string,
  $pos as xs:string,
  $value as xs:string,
  $row as xs:string,
  $col as xs:string,
  $rowLabel as xs:string,
  $columnLabel as xs:string)
{
  let $doc :=
    element { fn:QName($NS, "nameRef") }
    {
      element { fn:QName($NS, "rangeName") }   { $rangeName },
      element { fn:QName($NS, "rowLabel") }    { if (fn:empty($rowLabel)) then "" else $rowLabel },
      (: element { fn:QName($NS, "columnLabel") } { if (fn:empty($columnLabel)) then "" else $columnLabel }, :)
      element { fn:QName($NS, "sheet") }       { $sheetName },
      element { fn:QName($NS, "col") }         { $col },
      element { fn:QName($NS, "row") }         { $row },
      element { fn:QName($NS, "pos") }         { $pos },
      element { fn:QName($NS, "rnValue") }      { if (fn:empty($value)) then () else $value }
    }
    
  return $doc
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
  let $rangeName   := $dn/tax:rangeName/text()

  let $rowLabel    := ingest:findRowLabel(xs:string($row), $col, $sheetName, $table)

  (: let $columnLabel := ingest:findColumnLabel(xs:string($row), $col, $sheetName, $table) :)
  let $columnLabel := ""

  let $newValue    := ingest:getValue(xs:string($row), $col, $sheetName, $table)
  
  let $doc := ingest:createNameRefNode($sheetName, $rangeName, $newPos, $newValue, $row, $col, $rowLabel, $columnLabel)

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
      let $log := xdmp:log("222...row expansion..... rangeName: "||$dn/tax:rangeName/text()||" --- row: '"||$row||"' --- col: '"||$col||"'")
        return
          ingest:expansionElement($dn, xs:string($row), $col, $table)
                  
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
          let $log := xdmp:log("111...Column and Row expansion..... rangeName: "||$dn/tax:rangeName/text()||" --- row: '"||$row||"' --- col: '"||$newCol||"'")

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
    element { fn:QName($NS, "nameRefs") }
    {
      for $nameRef in $doc/tax:nameRef
        return
        (
          xdmp:log("1...expandDoc........... rangeName: "||$nameRef/tax:rangeName/text()||" --- row1: '"||$nameRef/tax:row1/text()||"' --- col1: '"||$nameRef/tax:col1/text()||"'"),
          xdmp:log("2...expandDoc........... rangeName: "||$nameRef/tax:rangeName/text()||" --- row1: '"||$nameRef/tax:row2/text()||"' --- col1: '"||$nameRef/tax:col2/text()||"'"),
          
          if (fn:empty($nameRef/tax:row2/text())) then
          (
            (: No Expansion :)
            xdmp:log("3...No Expansion......... rangeName: "||$nameRef/tax:rangeName/text()||" --- row1: '"||$nameRef/tax:row1/text()||"' --- col1: '"||$nameRef/tax:col1/text()||"'"),
            ingest:expansionElement($nameRef, xs:string($nameRef/tax:row1/text()), $nameRef/tax:col1/text(), $table)
          )
          else
          if (($nameRef/tax:row1/text() ne $nameRef/tax:row2/text()) and ($nameRef/tax:col1/text() ne $nameRef/tax:col2/text())) then
          (
            (: Row and Column Expansion :)
            xdmp:log("4...Row and Column Expansion......... rangeName: "||$nameRef/tax:rangeName/text()||" --- row1: '"||$nameRef/tax:row1/text()||"' --- col1: '"||$nameRef/tax:col1/text()||"'"),
            ingest:columnRowExpandDoc($nameRef, $table)
          )
          else
          if ($nameRef/tax:row1/text() eq $nameRef/tax:row2/text()) then
          (
            (: Column Expansion :)
            xdmp:log("5...Column Expansion......... rangeName: "||$nameRef/tax:rangeName/text()||" --- row1: '"||$nameRef/tax:row1/text()||"' --- col1: '"||$nameRef/tax:col1/text()||"'"),
            ingest:columnExpandDoc($nameRef, $table)
          )
          else
          if ($nameRef/tax:col1/text() eq $nameRef/tax:col2/text()) then
          (
            (: Row Expansion :)
            xdmp:log("6...Row Expansion......... rangeName: "||$nameRef/tax:rangeName/text()||" --- row1: '"||$nameRef/tax:row1/text()||"' --- col1: '"||$nameRef/tax:col1/text()||"'"),
            ingest:rowExpandDoc($nameRef, $table)
          )
          else ()
        )
    }

  (:  :)

  return $newDoc
};

declare function ingest:createWorkSheetMetadoc(
    $wkSheet,
    $spreadSheetType as xs:string,
    $client as xs:string,
    $userFullName as xs:string,
    $user as xs:string,
    $version as xs:string,
    $workPaperId as xs:string,
    $fileUri as xs:string,
    $origTemplateId as xs:string,
    $wkBook,
    $rels,
    $table
  )
{
  let $sheetName     := $wkSheet/@name/fn:string()

  let $wkSheetKey    := ingest:getWkSheetKey($sheetName, $rels, $table)
  let $relWkSheet    := map:get($table, $wkSheetKey)
  let $dim           := $relWkSheet/ssml:worksheet/ssml:dimension/@ref/fn:string()
  let $rowCount      := fn:count($relWkSheet/ssml:worksheet/ssml:sheetData/ssml:row)
  let $sharedStrings := map:get($table, "xl/sharedStrings.xml")/ssml:sst/ssml:si

  let $log := xdmp:log("1............... $wkSheetKey: "||$wkSheetKey)

  let $nameRefs      :=
      for $item in $wkBook/ssml:definedNames/node()
        where
          fn:not(fn:starts-with($item/text(), "#REF!")) and
          fn:contains($item/text(), $sheetName)
            return $item

  let $newNameRefDoc := ingest:getNameRangeDocByWorkSheet($sheetName, $nameRefs, $table)

  let $templateId :=
    if (fn:string-length($origTemplateId) gt 0) then
      $origTemplateId
    else
      xdmp:hash64($wkSheet)

  let $state                        := ingest:getNameRefInfo($nameRefs[@name="State"], $table)/tax:rnValue/text()
  let $country                      := ingest:getNameRefInfo($nameRefs[@name="Country"], $table)/tax:rnValue/text()
  let $filingEntity                 := ingest:getNameRefInfo($nameRefs[@name="FilingEntity"], $table)/tax:rnValue/text()
  let $fiscalYear                   := ingest:getNameRefInfo($nameRefs[@name="FiscalYear"], $table)/tax:rnValue/text()
  
  let $averageVariance              := fn:abs(fn:round(ingest:getNameRefInfo($nameRefs[@name="AverageProvisionVariance"], $table)/tax:rnValue/text() * 100))
  let $preTaxBookIncomeVariance     := fn:abs(fn:round(ingest:getNameRefInfo($nameRefs[@name="PreTaxBookIncomeVariance"], $table)/tax:rnValue/text() * 100))
  let $returnBasisProvisionVariance := fn:abs(fn:round(ingest:getNameRefInfo($nameRefs[@name="ReturnBasisProvisionVariance"], $table)/tax:rnValue/text() * 100))
  let $taxableIncomeVariance        := fn:abs(fn:round(ingest:getNameRefInfo($nameRefs[@name="TaxableIncomeVariance"], $table)/tax:rnValue/text() * 100))

  let $fileName := fn:tokenize($fileUri, "/")[fn:last()-1]

  let $doc :=
    element { fn:QName($NS, "worksheet") }
    {
      element { fn:QName($NS, "meta") }
      {
        element { fn:QName($NS, "type") }                         { $spreadSheetType },
        element { fn:QName($NS, "client") }                       { $client },
        if (fn:string-length($state) gt 0) then
        element { fn:QName($NS, "state") }                        { $state }        else (),
        if (fn:string-length($country) gt 0) then
        element { fn:QName($NS, "country") }                      { $country }      else(),
        if (fn:string-length($filingEntity) gt 0) then
        element { fn:QName($NS, "filingEntity") }                 { $filingEntity } else (),
        if (fn:string-length($filingEntity) gt 0) then
        element { fn:QName($NS, "fiscalYear") }                   { $fiscalYear }   else (),
        element { fn:QName($NS, "averageVariance") }              { $averageVariance },
        element { fn:QName($NS, "preTaxBookIncomeVariance") }     { $preTaxBookIncomeVariance },
        element { fn:QName($NS, "returnBasisProvisionVariance") } { $returnBasisProvisionVariance },
        element { fn:QName($NS, "taxableIncomeVariance") }        { $taxableIncomeVariance },
        element { fn:QName($NS, "templateId") }                   { $templateId },
        element { fn:QName($NS, "workPaperId") }                  { $workPaperId },
        element { fn:QName($NS, "user") }                         { $userFullName },
        element { fn:QName($NS, "version") }                      { $version },
        element { fn:QName($NS, "fileName") }                     { $fileName },
        element { fn:QName($NS, "creator") }        { map:get($table, "docProps/core.xml")/core:coreProperties/dc:creator/text() },
        element { fn:QName($NS, "file") }           { $fileUri },
        element { fn:QName($NS, "lastModifiedBy") } { map:get($table, "docProps/core.xml")/core:coreProperties/core:lastModifiedBy/text() },
        element { fn:QName($NS, "created") }        { map:get($table, "docProps/core.xml")/core:coreProperties/dcterms:created/text() },
        element { fn:QName($NS, "modified") }       { map:get($table, "docProps/core.xml")/core:coreProperties/dcterms:modified/text() },
        
        element { fn:QName($NS, "workSheetMeta") }
        {
          element { fn:QName($NS, "name") }          { $wkSheet/@name/fn:string() },
          element { fn:QName($NS, "key") }           { $wkSheetKey },
          element { fn:QName($NS, "rowCount") }      { $rowCount },
          element { fn:QName($NS, "relId") }         { $wkSheet/@wbrel:id/fn:string() },
          element { fn:QName($NS, "dimension") }
          {
            element { fn:QName($NS, "topLeft") }     { fn:tokenize($dim, ":") [1] },
            element { fn:QName($NS, "bottomRight") } { fn:tokenize($dim, ":") [2] }
          }
        }
      },
      element { fn:QName($NS, "feed") }
      {
        $newNameRefDoc,
        element { fn:QName($NS, "sheetData") }
        {
          for $cell in $relWkSheet/ssml:worksheet/ssml:sheetData/ssml:row
            let $row  := xs:string($cell/@r)
            for $column in $cell/ssml:c
              let $pos   := xs:string($column/@r)
              let $col   := fn:tokenize($pos, "[\d]+")[1] (: Tokenize to support more than 1 char like ABC7, AAA8 :)
              let $ref   := xs:string($column/@t)
              let $value := xs:string($column/ssml:v)
              let $val   := if ($ref eq "s") then $sharedStrings[xs:integer($value) + 1]/ssml:t/text() else $value
              let $type  := if ($ref eq "s") then "string" else "integer"
              let $saveCell :=
                if ($val eq " ") then
                  fn:false()
                else if (fn:string-length(xs:string($val)) gt 0) then
                  fn:true()
                else
                  fn:false()
                
                where
                  $saveCell eq fn:true() and
                  fn:not($cell[@hidden=1])
                  return
                    element { fn:QName($NS, "cell") }
                    {
                      element { fn:QName($NS, "col") }      { $col },
                      element { fn:QName($NS, "row") }      { $row },
                      element { fn:QName($NS, "pos") }      { $pos },
                      element { fn:QName($NS, "cellType") } { $type },
                      element { fn:QName($NS, "val") }      { $val }
                    }
        }
      }
    }

  return $doc
};

(:~
 : Get Local Meta Info for Workbook
 :
 : @param $binFileName
 :)
declare function ingest:getLocalMetaInfo($binFileName)
{
  let $binFile    := xdmp:document-get($binFileName, $BIN-OPTIONS)

  let $userFullName  := ingest:getUserFullNameJson()
  let $firstName     := fn:replace(fn:replace(fn:lower-case(fn:tokenize(fn:substring-after($userFullName, '{"firstName":"'), '","')[1]), " ", ""), "\.", "")
  let $lastName      := fn:replace(fn:lower-case(fn:substring-before(fn:tokenize(fn:tokenize(fn:substring-after($userFullName, '{"firstName":"'), '","')[2], '":"')[2], '"}')), "'", "")
  let $user          := $firstName||$lastName
  let $userFullName2 := fn:tokenize(fn:substring-after($userFullName, '{"firstName":"'), '","')[1]||" "||fn:replace(fn:substring-after($userFullName, 'lastName":"'), '"\}', '')

  let $client   := "ey003"
  let $fileName := fn:replace(fn:tokenize(fn:tokenize($binFileName, "/")[fn:last()], ".xlsx") [1], " ", "-")||"-"||xdmp:hash64(xs:string($binFile))
  
  let $fileDir          := "/client/"||$client||"/wpaper"
  let $fileMetadataDir  := $fileDir||"/"||$fileName

  let $fileMetadataUri := $fileMetadataDir||"/"||$fileName
  let $binFileUri      := $fileMetadataDir||"/"||$fileName||".xlsx"
  
  let $version     := "0.1"
  let $workPaperId := "101"
  let $templateId  := "111111"||$workPaperId

  let $doc :=
    element { fn:QName($NS, "meta") }
    {
      element { fn:QName($NS, "metaFileUri") }  { $fileMetadataUri },
      element { fn:QName($NS, "binFileUri") }   { $binFileUri },
      element { fn:QName($NS, "client") }       { $client },
      element { fn:QName($NS, "userFullName") } { $userFullName2 },
      element { fn:QName($NS, "user") }         { $user },
      element { fn:QName($NS, "version") }      { $version },
      element { fn:QName($NS, "fileName") }     { $fileName },
      element { fn:QName($NS, "workPaperId") }  { $workPaperId },
      element { fn:QName($NS, "templateId") }   { $templateId }
    }
    
  return $doc
};

(:~
 : Extract Spreadsheet Data By WorkSheet - this is needed to process very large spreadsheets
 :
 : @param $zipfile
 :)
declare function ingest:extractSpreadsheetData(
  $spreadSheetType as xs:string,
  $client as xs:string,
  $userFullName as xs:string,
  $user as xs:string,
  $version as xs:string,
  $workPaperId as xs:string,
  $fileUri as xs:string,
  $origTemplateId as xs:string,
  $binFileName as node()*)
{
  let $metaDoc      := ingest:getLocalMetaInfo($binFileName)
  let $binFile      := xdmp:document-get($binFileName, $BIN-OPTIONS)
  
  let $exclude :=
    (
      "[Content_Types].xml", "docProps/app.xml", "xl/theme/theme1.xml", "xl/styles.xml", "_rels/.rels",
      "xl/vbaProject.bin", "xl/media/image1.png"
    )
  
  let $table := map:map()

  let $docs :=
      for $x in xdmp:zip-manifest($binFile)//zip:part/text()
        where (($x = $exclude) eq fn:false()) and
            fn:not(fn:starts-with($x, "xl/printerSettings/printerSettings")) and
            fn:not(fn:ends-with($x, ".jpeg")) and
            fn:not(fn:ends-with($x, ".bin"))
         return
            map:put($table, $x, xdmp:zip-get($binFile, $x, $OPTIONS))
  
  let $wkBook := map:get($table, "xl/workbook.xml")/ssml:workbook
  
  let $wkSheetList   :=
        for $ws in $wkBook/ssml:sheets/ssml:sheet
          where fn:empty($ws/@state)
            order by $ws/@wbrel:id
              return $ws
  
  let $rels := map:get($table, "xl/_rels/workbook.xml.rels")/rel:Relationships
  
  let $binDocStatus := xdmp:document-insert($metaDoc/tax:binFileUri/text(), $binFile, xdmp:default-permissions(), ("binary"))
  
  let $spreadSheetType := "wpaper"
  
  let $wkBookMapDoc := 
      element { fn:QName($NS, "workBookMap") }
      {
        element { fn:QName($NS, "meta") }
        {
          element { fn:QName($NS, "type") }           { $spreadSheetType },
          element { fn:QName($NS, "templateId") }     { $metaDoc/tax:templateId/text() },
          element { fn:QName($NS, "workPaperId") }    { $metaDoc/tax:workPaperId/text() },
          element { fn:QName($NS, "user") }           { $metaDoc/tax:userFullName/text() },
          element { fn:QName($NS, "version") }        { $metaDoc/tax:version/text() },
          element { fn:QName($NS, "fileName") }       { $metaDoc/tax:fileName/text() },
          element { fn:QName($NS, "creator") }        { map:get($table, "docProps/core.xml")/core:coreProperties/dc:creator/text() },
          element { fn:QName($NS, "file") }           { $metaDoc/tax:binFileUri/text() },
          element { fn:QName($NS, "lastModifiedBy") } { map:get($table, "docProps/core.xml")/core:coreProperties/core:lastModifiedBy/text() },
          element { fn:QName($NS, "created") }        { map:get($table, "docProps/core.xml")/core:coreProperties/dcterms:created/text() },
          element { fn:QName($NS, "modified") }       { map:get($table, "docProps/core.xml")/core:coreProperties/dcterms:modified/text() }
        },
        element { fn:QName($NS, "workBookMap") }
        {
          for $ws in $wkSheetList
            let $sheetCycle := xs:string($ws/@name)
            let $relId      := $wkBook/ssml:sheets/ssml:sheet[@name=$sheetCycle]/@*:id
            let $metaUri    := $metaDoc/tax:metaFileUri/text()||"-"||$relId||".xml"
              where fn:not(fn:contains($sheetCycle, "Trial Balance"))
                order by $relId
              return
                element { fn:QName($NS, "workSheet") }
                {
                  element { fn:QName($NS, "name") } { xs:string($ws/@name) },
                  element { fn:QName($NS, "uri") }  { $metaUri }
                }
        }
      }

  let $workBookMapDocStatus := xdmp:document-insert($metaDoc/tax:metaFileUri/text()||"-map.xml", $wkBookMapDoc, xdmp:default-permissions(), ("spreadsheet"))

  let $workSheetDocs :=
      for $ws in $wkSheetList
        let $sheetCycle := xs:string($ws/@name)
        let $relId      := $wkBook/ssml:sheets/ssml:sheet[@name=$sheetCycle]/@*:id
        let $metaUri    := $metaDoc/tax:metaFileUri/text()||"-"||$relId||".xml"
        let $wkSheetKey := ingest:getWkSheetKey($sheetCycle, $rels, $table)
        
        where fn:not(fn:contains($sheetCycle, "Trial Balance"))
          order by $relId

        return
        (
          xdmp:document-insert(
            $metaUri,
            ingest:createWorkSheetMetadoc(
              $wkSheetList[@name=$sheetCycle],
              "wsheet",
              $metaDoc/tax:client/text(),
              $metaDoc/tax:userFullName/text(),
              $metaDoc/tax:user/text(),
              "0.1",
              "101",
              $metaDoc/tax:binFileUri/text(),
              "",
              $wkBook,
              $rels,
              $table
            ),
            xdmp:default-permissions(),
            ("worksheet")
          ),
          $metaUri
       )

  return
  (
    xdmp:elapsed-time(),
    fn:count($workSheetDocs)
  )
};

(:~
 : Extract Spreadsheet Data
 :
 : @param $zipfile
 :)
declare function ingest:extractSpreadsheetData-Older(
  $spreadSheetType as xs:string,
  $client as xs:string,
  $userFullName as xs:string,
  $user as xs:string,
  $version as xs:string,
  $workPaperId as xs:string,
  $fileUri as xs:string,
  $origTemplateId as xs:string,
  $binFile as node()*)
{
  (: 2 types: wpaper or template :)

  let $exclude :=
  (
    "[Content_Types].xml", "docProps/app.xml", "xl/theme/theme1.xml", "xl/styles.xml", "_rels/.rels",
    "xl/vbaProject.bin", "xl/media/image1.png"
  )

  let $fileName := fn:tokenize($fileUri, "/")[fn:last()-1]

  let $table := map:map()
  
  let $docs :=
    for $x in xdmp:zip-manifest($binFile)//zip:part/text()
      where (($x = $exclude) eq fn:false()) and fn:not(fn:starts-with($x, "xl/printerSettings/printerSettings"))
        return
          map:put($table, $x, xdmp:zip-get($binFile, $x, $OPTIONS))

  let $wkBook        := map:get($table, "xl/workbook.xml")/ssml:workbook

  let $nameRefs      :=
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
        let $wkSheetKey := "xl/"||xs:string($rels/rel:Relationship[@Id=$ws/@wbrel:id/fn:string()]/@Target)
        let $relWkSheet := map:get($table, $wkSheetKey)
        let $dim := $relWkSheet/ssml:worksheet/ssml:dimension/@ref/fn:string()
        where fn:empty($ws/@state)
          return
            ingest:createWorkSheetMetadoc(
              "wpaper",
              $client,
              $userFullName,
              $user,
              $version,
              $workPaperId,
              $fileUri,
              $origTemplateId,
              $wkBook,
              $ws,
              $rels,
              $table
            )
    }

  let $newNameRefDoc := ingest:getNameRangeDoc($nameRefs, $table)
  
  let $templateId :=
    if (fn:string-length($origTemplateId) gt 0) then
      $origTemplateId
    else
      xdmp:hash64($workSheets)

  (: GR001: fix to do this by worksheet :)
  let $state                        := ingest:getNameRefInfo($nameRefs[@name="State"][1], $table)/tax:rnValue/text()
  let $country                      := ingest:getNameRefInfo($nameRefs[@name="Country"][1], $table)/tax:rnValue/text()
  let $filingEntity                 := ingest:getNameRefInfo($nameRefs[@name="FilingEntity"][1], $table)/tax:rnValue/text()
  let $fiscalYear                   := ingest:getNameRefInfo($nameRefs[@name="FiscalYear"][1], $table)/tax:rnValue/text()
  
  let $averageVariance              := fn:abs(fn:round(ingest:getNameRefInfo($nameRefs[@name="AverageProvisionVariance"][1], $table)/tax:rnValue/text() * 100))
  let $preTaxBookIncomeVariance     := fn:abs(fn:round(ingest:getNameRefInfo($nameRefs[@name="PreTaxBookIncomeVariance"][1], $table)/tax:rnValue/text() * 100))
  let $returnBasisProvisionVariance := fn:abs(fn:round(ingest:getNameRefInfo($nameRefs[@name="ReturnBasisProvisionVariance"][1], $table)/tax:rnValue/text() * 100))
  let $taxableIncomeVariance        := fn:abs(fn:round(ingest:getNameRefInfo($nameRefs[@name="TaxableIncomeVariance"][1], $table)/tax:rnValue/text() * 100))

  let $doc :=
    element { fn:QName($NS, "workbook") }
    {
      element { fn:QName($NS, "meta") }
      {
        element { fn:QName($NS, "type") }                         { $spreadSheetType },
        element { fn:QName($NS, "client") }                       { $client },
        element { fn:QName($NS, "state") }                        { $state },
        element { fn:QName($NS, "country") }                      { $country },
        element { fn:QName($NS, "filingEntity") }                 { $filingEntity },
        element { fn:QName($NS, "fiscalYear") }                   { $fiscalYear },
        element { fn:QName($NS, "averageVariance") }              { $averageVariance },
        element { fn:QName($NS, "preTaxBookIncomeVariance") }     { $preTaxBookIncomeVariance },
        element { fn:QName($NS, "returnBasisProvisionVariance") } { $returnBasisProvisionVariance },
        element { fn:QName($NS, "taxableIncomeVariance") }        { $taxableIncomeVariance },
        element { fn:QName($NS, "templateId") }                   { $templateId },
        element { fn:QName($NS, "workPaperId") }                  { $workPaperId },
        element { fn:QName($NS, "user") }                         { $userFullName },
        element { fn:QName($NS, "version") }                      { $version },
        element { fn:QName($NS, "fileName") }                     { $fileName },
        element { fn:QName($NS, "creator") }        { map:get($table, "docProps/core.xml")/core:coreProperties/dc:creator/text() },
        element { fn:QName($NS, "file") }           { $fileUri },
        element { fn:QName($NS, "lastModifiedBy") } { map:get($table, "docProps/core.xml")/core:coreProperties/core:lastModifiedBy/text() },
        element { fn:QName($NS, "created") }        { map:get($table, "docProps/core.xml")/core:coreProperties/dcterms:created/text() },
        element { fn:QName($NS, "modified") }       { map:get($table, "docProps/core.xml")/core:coreProperties/dcterms:modified/text() }
      },
      element { fn:QName($NS, "feed") }
      {
        $newNameRefDoc,
        $workSheets
      }
    }

  return $doc
};

(:~
 : Extract Spreadsheet Data
 :
 : @param $zipfile
 :)
declare function ingest:extractSpreadsheetDataOrig(
  $client as xs:string,
  $userFullName as xs:string,
  $user as xs:string,
  $version as xs:string,
  $workPaperId as xs:string,
  $fileUri as xs:string,
  $origTemplateId as xs:string,
  $binFile as node()*)
{
  let $exclude :=
  (
    "[Content_Types].xml", "docProps/app.xml", "xl/theme/theme1.xml", "xl/styles.xml", "_rels/.rels",
    "xl/vbaProject.bin", "xl/media/image1.png"
  )

  let $spreadSheetType := fn:tokenize($fileUri, "/") [4]
  (: let $log := xdmp:log("1............... $spreadSheetType: "||$spreadSheetType) :)

  let $fileName := fn:tokenize($fileUri, "/")[fn:last()-1]

  let $table := map:map()
  
  let $docs :=
    for $x in xdmp:zip-manifest($binFile)//zip:part/text()
      where (($x = $exclude) eq fn:false()) and fn:not(fn:starts-with($x, "xl/printerSettings/printerSettings"))
        return
          map:put($table, $x, xdmp:zip-get($binFile, $x, $OPTIONS))

  let $wkBook        := map:get($table, "xl/workbook.xml")/ssml:workbook

  let $nameRefs      :=
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
                    where fn:not($cell[@hidden=1])
                      return
                        element { fn:QName($NS, "cell") }
                        {
                          element { fn:QName($NS, "col") }     { $col },
                          element { fn:QName($NS, "row") }     { $row },
                          element { fn:QName($NS, "pos") }     { $pos },
                          element { fn:QName($NS, "valType") } { $type },
                          element { fn:QName($NS, "val") }     { $val }
                        }
              }
            }
    }

  let $newNameRefDoc := ingest:getNameRangeDoc($nameRefs, $table)
  
  let $templateId :=
    if (fn:string-length($origTemplateId) gt 0) then
      $origTemplateId
    else
      xdmp:hash64($workSheets)

  (: GR001: fix to do this by worksheet :)
  let $state                        := ingest:getNameRefInfo($nameRefs[@name="State"][1], $table)/tax:rnValue/text()
  let $country                      := ingest:getNameRefInfo($nameRefs[@name="Country"][1], $table)/tax:rnValue/text()
  let $filingEntity                 := ingest:getNameRefInfo($nameRefs[@name="FilingEntity"][1], $table)/tax:rnValue/text()
  let $fiscalYear                   := ingest:getNameRefInfo($nameRefs[@name="FiscalYear"][1], $table)/tax:rnValue/text()
  
  let $averageVariance              := fn:abs(fn:round(ingest:getNameRefInfo($nameRefs[@name="AverageProvisionVariance"][1], $table)/tax:rnValue/text() * 100))
  let $preTaxBookIncomeVariance     := fn:abs(fn:round(ingest:getNameRefInfo($nameRefs[@name="PreTaxBookIncomeVariance"][1], $table)/tax:rnValue/text() * 100))
  let $returnBasisProvisionVariance := fn:abs(fn:round(ingest:getNameRefInfo($nameRefs[@name="ReturnBasisProvisionVariance"][1], $table)/tax:rnValue/text() * 100))
  let $taxableIncomeVariance        := fn:abs(fn:round(ingest:getNameRefInfo($nameRefs[@name="TaxableIncomeVariance"][1], $table)/tax:rnValue/text() * 100))

  let $doc :=
    element { fn:QName($NS, "workbook") }
    {
      element { fn:QName($NS, "meta") }
      {
        element { fn:QName($NS, "type") }                         { $spreadSheetType },
        element { fn:QName($NS, "client") }                       { $client },
        element { fn:QName($NS, "state") }                        { $state },
        element { fn:QName($NS, "country") }                      { $country },
        element { fn:QName($NS, "filingEntity") }                 { $filingEntity },
        element { fn:QName($NS, "fiscalYear") }                   { $fiscalYear },
        element { fn:QName($NS, "averageVariance") }              { $averageVariance },
        element { fn:QName($NS, "preTaxBookIncomeVariance") }     { $preTaxBookIncomeVariance },
        element { fn:QName($NS, "returnBasisProvisionVariance") } { $returnBasisProvisionVariance },
        element { fn:QName($NS, "taxableIncomeVariance") }        { $taxableIncomeVariance },
        element { fn:QName($NS, "templateId") }                   { $templateId },
        element { fn:QName($NS, "workPaperId") }                  { $workPaperId },
        element { fn:QName($NS, "user") }                         { $userFullName },
        element { fn:QName($NS, "version") }                      { $version },
        element { fn:QName($NS, "fileName") }                     { $fileName },
        element { fn:QName($NS, "creator") }        { map:get($table, "docProps/core.xml")/core:coreProperties/dc:creator/text() },
        element { fn:QName($NS, "file") }           { $fileUri },
        element { fn:QName($NS, "lastModifiedBy") } { map:get($table, "docProps/core.xml")/core:coreProperties/core:lastModifiedBy/text() },
        element { fn:QName($NS, "created") }        { map:get($table, "docProps/core.xml")/core:coreProperties/dcterms:created/text() },
        element { fn:QName($NS, "modified") }       { map:get($table, "docProps/core.xml")/core:coreProperties/dcterms:modified/text() }
      },
      element { fn:QName($NS, "feed") }
      {
        $newNameRefDoc,
        $workSheets
      }
    }

  return $doc
};

(:
:)
declare function ingest:getWkSheetKey($sheet, $rels, $table)
{
  let $wkBook        := map:get($table, "xl/workbook.xml")/ssml:workbook/ssml:sheets/ssml:sheet
  let $rels          := map:get($table, "xl/_rels/workbook.xml.rels")/rel:Relationships

  let $wkSheetKey    := "xl/"||xs:string($rels/rel:Relationship[@Id=$wkBook[@name=$sheet]/@wbrel:id]/@Target)
  
  return $wkSheetKey
};

(:
:)
declare function ingest:getNameRangeDocByWorkSheet($sheetName, $nameRefs, $table)
{
  (:
     1st Pass - create temp doc that has an special expand node.
     Expand node is used in the 2nd pass to expand the number of cells.
  :)
  let $nameRefPass1Doc :=
        element { fn:QName($NS, "nameRefs") }
        {
          for $nameRef in $nameRefs
            let $item1  := fn:tokenize($nameRef, ",") [1]
            let $sheet  := fn:replace(fn:tokenize($item1, "!") [1], "'", "")
              where
                fn:not(fn:starts-with(xs:string($nameRef/@name), "_")) and
                fn:empty($nameRef/@hidden) and
                $sheet eq $sheetName
              return
                ingest:getNameRefInfo($nameRef, $table)
        }

  let $rnExpansionDoc := ingest:expandDoc($nameRefPass1Doc, $table)

  let $unSortedDoc :=
      element { fn:QName($NS, "nameRefs") }
      {
        $rnExpansionDoc/node(),
        for $nr in $nameRefPass1Doc/tax:nameRef
          where fn:not(fn:empty($nr/tax:pos/text()))
            return
              ingest:createNameRefNode(
                $nr/tax:sheet/text(),
                $nr/tax:rangeName/text(),
                $nr/tax:pos/text(),
                $nr/tax:rnValue/text(),
                $nr/tax:row/text(),
                $nr/tax:col/text(),
                $nr/tax:rowLabel/text(),
                $nr/tax:columnLabel/text()
              )
      }

  let $newNameRefDoc :=
      element { fn:QName($NS, "nameRefs") }
      {
        for $i in $unSortedDoc/tax:nameRef
          let $row   := xs:integer($i/tax:row/text())
          let $seq   :=
            if ($row lt 10) then
              $i/tax:col/text()||"0"||$i/tax:row/text()
            else
              $i/tax:pos/text()
          let $rangeName := $i/tax:rangeName/text()
          order by $seq, $rangeName
            return $i
      }

  return $newNameRefDoc
};

(:
:)
declare function ingest:getNameRangeDoc($nameRefs, $table)
{
  (:
     1st Pass - create temp doc that has an special expand node.
     Expand node is used in the 2nd pass to expand the number of cells.
  :)
  let $nameRefPass1Doc :=
        element { fn:QName($NS, "nameRefs") }
        {
          for $nameRef in $nameRefs
            where fn:not(fn:starts-with(xs:string($nameRef/@name), "_")) and fn:empty($nameRef/@hidden)
              return
                ingest:getNameRefInfo($nameRef, $table)
        }

  let $rnExpansionDoc := ingest:expandDoc($nameRefPass1Doc, $table)

  let $unSortedDoc :=
      element { fn:QName($NS, "nameRefs") }
      {
        $rnExpansionDoc/node(),
        for $nr in $nameRefPass1Doc/tax:nameRef
          where fn:not(fn:empty($nr/tax:pos/text()))
            return
              ingest:createNameRefNode(
                $nr/tax:sheet/text(),
                $nr/tax:rangeName/text(),
                $nr/tax:pos/text(),
                $nr/tax:rnValue/text(),
                $nr/tax:row/text(),
                $nr/tax:col/text(),
                $nr/tax:rowLabel/text(),
                $nr/tax:columnLabel/text()
              )
      }

  let $newNameRefDoc :=
      element { fn:QName($NS, "nameRefs") }
      {
        for $i in $unSortedDoc/tax:nameRef
          let $row   := xs:integer($i/tax:row/text())
          let $seq   :=
            if ($row lt 10) then
              $i/tax:col/text()||"0"||$i/tax:row/text()
            else
              $i/tax:pos/text()
          let $rangeName := $i/tax:rangeName/text()
          order by $seq, $rangeName
            return $i
      }

  return $newNameRefDoc
};

(:
:)
declare function ingest:getNameRefInfo($nameRef, $table)
{
  let $rangeName := xs:string($nameRef/@name)

  (: There can be multiple rangeName items: 'T010'!$A$1:$O$56,'T010'!$A$57:$K$77 :)
  let $nameRefVal := $nameRef/text()
  let $item1  := fn:tokenize($nameRefVal, ",") [1]
  
  (: Use item1 for now. Add support for multiple items later :) 
  let $sheet := fn:replace(fn:tokenize($item1, "!") [1], "'", "")
  
  let $cell   := fn:tokenize($item1, "!") [2]
  let $pos    := fn:replace($cell, "\$", "")
  
  let $pos1   := fn:tokenize($pos, ":") [1]
  let $pos2   := fn:tokenize($pos, ":") [2]
  
  let $col    := fn:tokenize($pos1, "[0-9]") [1]
  
  let $col1 := fn:tokenize($pos1, "[\d]+")[1]
  let $col2 := fn:tokenize($pos2, "[\d]+")[1]
  
  let $row1   := fn:tokenize($pos1, "[A-Za-z]+") [2]
  let $row2   := fn:tokenize($pos2, "[A-Za-z]+") [2]

  (: GR001 - Added new code to check if row or cell is hidden :)
  let $wkBook        := map:get($table, "xl/workbook.xml")/ssml:workbook/ssml:sheets/ssml:sheet
  let $rels          := map:get($table, "xl/_rels/workbook.xml.rels")/rel:Relationships

  let $wkSheetKey    := "xl/"||xs:string($rels/rel:Relationship[@Id=$wkBook[@name=$sheet]/@wbrel:id]/@Target)
  let $wkSheet       := map:get($table, $wkSheetKey)

  let $hiddenAttrib1 :=
    if (fn:string-length($row1) gt 0) then
    (
      if (fn:empty($wkSheet/ssml:worksheet/ssml:sheetData/ssml:row[@r=$row1]/@hidden)) then
        fn:false()
      else
        fn:true()
     )
     else
      fn:false()

  let $hiddenAttrib2 :=
    if (fn:string-length($row2) gt 0) then
    (
      if (fn:empty($wkSheet/ssml:worksheet/ssml:sheetData/ssml:row[@r=$row2]/@hidden)) then
        fn:false()
      else
        fn:true()
     )
     else
      fn:false()

  let $hiddenCell  := if ($hiddenAttrib1 or $hiddenAttrib2) then fn:true() else fn:false()
  
  let $val         := if ($hiddenCell) then "hidden" else ingest:getValue($row1, $col1, $sheet, $table)
  let $rowLabel    := if ($hiddenCell) then "hidden" else ingest:findRowLabel($row1, $col1, $sheet, $table)
  let $columnLabel := ""

  (:
  let $columnLabel := if ($hiddenCell) then "hidden" else ingest:findColumnLabel($row1, $col1, $sheet, $table)
  let $log := xdmp:log("2....... $hidden: '"||$wkSheet/ssml:worksheet/ssml:sheetData/ssml:row[@r=$row1]/@hidden||"'")
  :)

  let $log := xdmp:log("1...... $sheet: '"||$sheet||"' --- $rowNum: '"||$wkSheet/ssml:worksheet/ssml:sheetData/ssml:row[@r=$row1]/@r||"' --- $rowLabel: '"||$rowLabel||"' --- $columnLabel: '"||$columnLabel||"'")

  let $doc :=
    element { fn:QName($NS, "nameRef") }
    {
      element { fn:QName($NS, "rangeName") }   { $rangeName },
      element { fn:QName($NS, "rowLabel") }    { $rowLabel },
      element { fn:QName($NS, "columnLabel") } { $columnLabel },
      element { fn:QName($NS, "sheet") }       { $sheet },
      element { fn:QName($NS, "col1") }        { $col1 },
      element { fn:QName($NS, "row1") }        { $row1 },
      element { fn:QName($NS, "pos1") }        { $pos1 },
      element { fn:QName($NS, "col2") }        { $col2 },
      element { fn:QName($NS, "row2") }        { $row2 },
      element { fn:QName($NS, "pos2") }        { $pos2 },
      element { fn:QName($NS, "rnValue") }     { $val }
    }

  return $doc
};

(:
:)
declare function ingest:getNameRefInfoOrig($nameRef, $table)
{
  let $rangeName := xs:string($nameRef/@name)
  
  (: There can be multiple rangeName items: 'T010'!$A$1:$O$56,'T010'!$A$57:$K$77 :)
  let $item1  := fn:tokenize($nameRef, ",") [1]
  
  (: Use item1 for now. Add support for multiple items later :) 
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

  let $hiddenCell := fn:true()

  let $val         := if ($hiddenCell) then "hidden" else ingest:getValue($row1, $col1, $sheet, $table)
  let $rowLabel    := if ($hiddenCell) then "hidden" else ingest:findRowLabel($row1, $col1, $sheet, $table)
  let $columnLabel := if ($hiddenCell) then "hidden" else ingest:findColumnLabel($row1, $col1, $sheet, $table)

  let $doc :=
    element { fn:QName($NS, "nameRef") }
    {
      element { fn:QName($NS, "rangeName") }   { $rangeName },
      element { fn:QName($NS, "rowLabel") }    { $rowLabel },
      element { fn:QName($NS, "columnLabel") } { $columnLabel },
      element { fn:QName($NS, "sheet") }       { $sheet },
      element { fn:QName($NS, "col1") }        { $col1 },
      element { fn:QName($NS, "row1") }        { $row1 },
      element { fn:QName($NS, "pos1") }        { $pos1 },
      element { fn:QName($NS, "col2") }        { $col2 },
      element { fn:QName($NS, "row2") }        { $row2 },
      element { fn:QName($NS, "pos2") }        { $pos2 },
      element { fn:QName($NS, "rnValue") }     { $val }
    }

  return $doc
};

(:~
 : Extract Spreadsheet Data
 :
 : @param $zipfile
 :)
declare function ingest:extractGeneratedSpreadsheetData(
  $userFullName as xs:string,
  $user as xs:string,
  $excelFile as node(),
  $taxRate as xs:decimal,
  $deductionPct as xs:decimal,
  $totalGrossInc as xs:decimal,
  $taxableInc as xs:decimal,
  $fileDate as xs:string,
  $fileUri as xs:string)
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

  let $nameRefs      :=
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
                    where fn:not($cell[@hidden=1])
                      return
                        element { fn:QName($NS, "cell") }
                        {
                          element { fn:QName($NS, "col") }     { $col },
                          element { fn:QName($NS, "row") }     { $row },
                          element { fn:QName($NS, "pos") }     { $pos },
                          element { fn:QName($NS, "valType") } { $type },
                          element { fn:QName($NS, "val") }     { $val }
                        }
              }
            }
    }

  let $newNameRefDoc := ingest:getNameRangeDoc($nameRefs, $table)

  let $doc :=
    element { fn:QName($NS, "workbook") }
    {
      element { fn:QName($NS, "meta") }
      {
        element { fn:QName($NS, "type") }           { "template" },
        element { fn:QName($NS, "user") }           { $userFullName },
        element { fn:QName($NS, "client") }         { "Thomson Reuters" },
        element { fn:QName($NS, "creator") }        { map:get($table, "docProps/core.xml")/core:coreProperties/dc:creator/text() },
        element { fn:QName($NS, "file") }           { $fileUri },
        element { fn:QName($NS, "fileDate") }       { $fileDate },
        element { fn:QName($NS, "taxBracket") }     { $taxRate * 100 },
        element { fn:QName($NS, "deductionPct") }   { $deductionPct },
        element { fn:QName($NS, "totalGrossInc") }  { $totalGrossInc },
        element { fn:QName($NS, "taxableInc") }     { $taxableInc },
        element { fn:QName($NS, "lastModifiedBy") } { map:get($table, "docProps/core.xml")/core:coreProperties/core:lastModifiedBy/text() },
        element { fn:QName($NS, "created") }        { map:get($table, "docProps/core.xml")/core:coreProperties/dcterms:created/text() },
        element { fn:QName($NS, "modified") }       { map:get($table, "docProps/core.xml")/core:coreProperties/dcterms:modified/text() }
      },
      element { fn:QName($NS, "feed") }
      {
        $newNameRefDoc,
        $workSheets
      }
    }

  return $doc
};
