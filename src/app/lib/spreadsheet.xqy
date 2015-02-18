(:
 :
 : Common Ingest Functions used for Spreadsheet Generator.
 :
 : @author gary.russo@thomsonreuters.com
 :
 :)

xquery version "1.0-ml";

module namespace ssheet = "http://marklogic.com/roxy/lib/ssheet";

declare namespace zip     = "xdmp:zip";
declare namespace ssml    = "http://schemas.openxmlformats.org/spreadsheetml/2006/main";
declare namespace rel     = "http://schemas.openxmlformats.org/package/2006/relationships";
declare namespace wbrel   = "http://schemas.openxmlformats.org/officeDocument/2006/relationships";
declare namespace wsheet  = "http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet";
declare namespace core    = "http://schemas.openxmlformats.org/package/2006/metadata/core-properties";
declare namespace dcterms = "http://purl.org/dc/terms/";
declare namespace dc      = "http://purl.org/dc/elements/1.1/";

(: declare option xdmp:mapping "false"; :)

declare function ssheet:generate-simple-xl-ooxml
(
  $contentTypes as node(),
  $appDoc as node(),
  $coreDoc as node(),
  $calcChain as node(),
  $sharedStrings as node(),
  $styles as node(),
  $wkBook as node(),
  $printerBinDoc as node(),
  $theme as node(),
  $sheet1 as node(),
  $sheet1Rels as node(),
  $wkBookRels as node(),
  $relsRels as node()
) as binary()
{
  let $manifest :=
    <parts xmlns="xdmp:zip">
      <part>[Content_Types].xml</part>
      <part>docProps/app.xml</part>
      <part>docProps/core.xml</part>
      <part>xl/calcChain.xml</part>
      <part>xl/sharedStrings.xml</part>
      <part>xl/styles.xml</part>
      <part>xl/workbook.xml</part>
      <part>xl/printerSettings/printerSettings1.bin</part>
      <part>xl/theme/theme1.xml</part>
      <part>xl/worksheets/sheet1.xml</part>
      <part>xl/worksheets/_rels/sheet1.xml.rels</part>
      <part>xl/_rels/workbook.xml.rels</part>
      <part>_rels/.rels</part>
    </parts>
    
  let $parts :=
    (
      $contentTypes,
      $appDoc,
      $coreDoc,
      $calcChain,
      $sharedStrings,
      $styles,
      $wkBook,
      $printerBinDoc,
      $theme,
      $sheet1,
      $sheet1Rels,
      $wkBookRels,
      $relsRels
    )
  
  return
    xdmp:zip-create($manifest, $parts)
};

declare function ssheet:createSpreadsheetFile(
  $user as xs:string,
  $filingDate as xs:string,
  $fileUri as xs:string,
  $taxPlan as node())
{
  let $contentTypes :=
    <Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
      <Default Extension="bin"
        ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.printerSettings"/>
      <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
      <Default Extension="xml" ContentType="application/xml"/>
      <Override PartName="/xl/workbook.xml"
        ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>
      <Override PartName="/xl/worksheets/sheet1.xml"
        ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>
      <Override PartName="/xl/theme/theme1.xml"
        ContentType="application/vnd.openxmlformats-officedocument.theme+xml"/>
      <Override PartName="/xl/styles.xml"
        ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>
      <Override PartName="/xl/sharedStrings.xml"
        ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sharedStrings+xml"/>
      <Override PartName="/xl/calcChain.xml"
        ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.calcChain+xml"/>
      <Override PartName="/docProps/core.xml"
        ContentType="application/vnd.openxmlformats-package.core-properties+xml"/>
      <Override PartName="/docProps/app.xml"
        ContentType="application/vnd.openxmlformats-officedocument.extended-properties+xml"/>
    </Types>
  
  let $appDoc :=
    <Properties xmlns="http://schemas.openxmlformats.org/officeDocument/2006/extended-properties"
      xmlns:vt="http://schemas.openxmlformats.org/officeDocument/2006/docPropsVTypes">
      <Application>Microsoft Excel</Application>
      <DocSecurity>0</DocSecurity>
      <ScaleCrop>false</ScaleCrop>
      <HeadingPairs>
        <vt:vector size="4" baseType="variant">
          <vt:variant>
            <vt:lpstr>Worksheets</vt:lpstr>
          </vt:variant>
          <vt:variant>
            <vt:i4>1</vt:i4>
          </vt:variant>
          <vt:variant>
            <vt:lpstr>Named Ranges</vt:lpstr>
          </vt:variant>
          <vt:variant>
            <vt:i4>18</vt:i4>
          </vt:variant>
        </vt:vector>
      </HeadingPairs>
      <TitlesOfParts>
        <vt:vector size="19" baseType="lpstr">
          <vt:lpstr>Year-End Tax Plan</vt:lpstr>
          <vt:lpstr>AdjustmentsToGrossIncFullYear</vt:lpstr>
          <vt:lpstr>AdjustmentsToGrossIncToDate</vt:lpstr>
          <vt:lpstr>AdjustmentsToGrossIncYearEnd</vt:lpstr>
          <vt:lpstr>FilingDate</vt:lpstr>
          <vt:lpstr>FilingPerson</vt:lpstr>
          <vt:lpstr>GrossIncomeFullYear</vt:lpstr>
          <vt:lpstr>GrossIncomeToDate</vt:lpstr>
          <vt:lpstr>GrossIncomeToYear</vt:lpstr>
          <vt:lpstr>ItemizedDeductionsFullYear</vt:lpstr>
          <vt:lpstr>ItemizedDeductionsToDate</vt:lpstr>
          <vt:lpstr>ItemizedDeductionsYearEnd</vt:lpstr>
          <vt:lpstr>NumberOfExemptions</vt:lpstr>
          <vt:lpstr>'Year-End Tax Plan'!Print_Area</vt:lpstr>
          <vt:lpstr>StandardDeduction</vt:lpstr>
          <vt:lpstr>TargetedTaxableIncome</vt:lpstr>
          <vt:lpstr>TargetedTaxBracket</vt:lpstr>
          <vt:lpstr>TaxBracket</vt:lpstr>
          <vt:lpstr>ValueOfExemptions</vt:lpstr>
        </vt:vector>
      </TitlesOfParts>
      <Company>Russo Enterprises</Company>
      <LinksUpToDate>false</LinksUpToDate>
      <SharedDoc>false</SharedDoc>
      <HyperlinksChanged>false</HyperlinksChanged>
      <AppVersion>14.0300</AppVersion>
    </Properties>
  
  let $coreDoc :=
    <cp:coreProperties
      xmlns:cp="http://schemas.openxmlformats.org/package/2006/metadata/core-properties"
      xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:dcterms="http://purl.org/dc/terms/"
      xmlns:dcmitype="http://purl.org/dc/dcmitype/"
      xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
      <dc:creator>Zenee Miller</dc:creator>
      <cp:lastModifiedBy>Gary P. Russo</cp:lastModifiedBy>
      <cp:lastPrinted>2004-02-26T18:52:56Z</cp:lastPrinted>
      <dcterms:created xsi:type="dcterms:W3CDTF">1997-03-01T10:51:00Z</dcterms:created>
      <dcterms:modified xsi:type="dcterms:W3CDTF">2014-11-13T17:42:57Z</dcterms:modified>
    </cp:coreProperties>
  
  let $calcChain :=
    <calcChain xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
      <c r="E4" i="2" l="1"/>
      <c r="E5" i="2"/>
      <c r="E6" i="2"/>
      <c r="E7" i="2"/>
      <c r="E8" i="2"/>
      <c r="E9" i="2"/>
      <c r="E10" i="2"/>
      <c r="C11" i="2"/>
      <c r="D11" i="2"/>
      <c r="E14" i="2"/>
      <c r="E15" i="2"/>
      <c r="E16" i="2"/>
      <c r="E17" i="2"/>
      <c r="C18" i="2"/>
      <c r="D18" i="2"/>
      <c r="E22" i="2"/>
      <c r="E23" i="2"/>
      <c r="E24" i="2"/>
      <c r="E25" i="2"/>
      <c r="E26" i="2"/>
      <c r="E27" i="2"/>
      <c r="E28" i="2"/>
      <c r="E29" i="2"/>
      <c r="C30" i="2"/>
      <c r="D30" i="2"/>
      <c r="E34" i="2"/>
      <c r="E30" i="2" l="1"/>
      <c r="E32" i="2" s="1"/>
      <c r="E35" i="2" s="1"/>
      <c r="D19" i="2"/>
      <c r="E18" i="2"/>
      <c r="C19" i="2"/>
      <c r="E11" i="2"/>
      <c r="E19" i="2" l="1"/>
      <c r="E36" i="2" s="1"/>
    </calcChain>
  
  let $sharedStrings :=
      <sst count="52" uniqueCount="42" xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
        <si>
          <t>Actual</t>
        </si>
        <si>
          <t>Estimated</t>
        </si>
        <si>
          <t>To Date</t>
        </si>
        <si>
          <t>To Year End</t>
        </si>
        <si>
          <t>Full Year</t>
        </si>
        <si>
          <t>Medical</t>
        </si>
        <si>
          <t>Taxes</t>
        </si>
        <si>
          <t>Taxable wages/salaries</t>
        </si>
        <si>
          <t>Taxable dividends and interest</t>
        </si>
        <si>
          <t>Net business income (loss)</t>
        </si>
        <si>
          <t>Net capital gain (loss)</t>
        </si>
        <si>
          <t>Net rent income (loss)</t>
        </si>
        <si>
          <t>Net partnership income (allowable loss)</t>
        </si>
        <si>
          <t>Other income (loss)</t>
        </si>
        <si>
          <t>Alimony paid</t>
        </si>
        <si>
          <t>IRA payments</t>
        </si>
        <si>
          <t>Keogh plan payments</t>
        </si>
        <si>
          <t>Other adjustments</t>
        </si>
        <si>
          <t>Mortgage interest paid</t>
        </si>
        <si>
          <t>Charitable contributions</t>
        </si>
        <si>
          <t>Casualty and theft losses</t>
        </si>
        <si>
          <t>Unreimbursed moving expenses</t>
        </si>
        <si>
          <t>Unreimbursed employee business expenses</t>
        </si>
        <si>
          <t>Miscellaneous deductions</t>
        </si>
        <si>
          <t>Standard deduction</t>
        </si>
        <si>
          <t>Greater of itemized or standard deduction</t>
        </si>
        <si>
          <t>Value of exemptions</t>
        </si>
        <si>
          <t>Number of allowable exemptions</t>
        </si>
        <si>
          <t>Taxable income</t>
        </si>
        <si>
          <t>Tax bracket</t>
        </si>
        <si>
          <t>Targeted taxable income</t>
        </si>
        <si>
          <t>Targeted tax bracket</t>
        </si>
        <si>
          <t>Allowable Itemized Deductions</t>
        </si>
        <si>
          <t>Adjusted Gross Income</t>
        </si>
        <si>
          <t>Adjustments to Gross Income</t>
        </si>
        <si>
          <t>Gross Income</t>
        </si>
        <si>
          <t>Total Gross Income</t>
        </si>
        <si>
          <t>Total Adjustments</t>
        </si>
        <si>
          <t>Total Itemized Deductions</t>
        </si>
        <si>
          <t>Total Deductions and Exemptions</t>
        </si>
        <si>
          <t>Year-End Tax Plan</t>
        </si>
        <si>
          <t>{$user}</t>
        </si>
      </sst>
  
    let $styles :=
      <styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"
        xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006" mc:Ignorable="x14ac"
        xmlns:x14ac="http://schemas.microsoft.com/office/spreadsheetml/2009/9/ac">
        <numFmts count="5">
          <numFmt numFmtId="6" formatCode="&quot;$&quot;#,##0_);[Red]\(&quot;$&quot;#,##0\)"/>
          <numFmt numFmtId="8" formatCode="&quot;$&quot;#,##0.00_);[Red]\(&quot;$&quot;#,##0.00\)"/>
          <numFmt numFmtId="164" formatCode="mm/dd/yy"/>
          <numFmt numFmtId="165" formatCode="0_);[Red]\(0\)"/>
          <numFmt numFmtId="166" formatCode="mmm\ d\,\ yyyy"/>
        </numFmts>
        <fonts count="5" x14ac:knownFonts="1">
          <font>
            <sz val="10"/>
            <name val="Arial"/>
            <family val="2"/>
          </font>
          <font>
            <sz val="10"/>
            <name val="Arial"/>
            <family val="2"/>
          </font>
          <font>
            <sz val="10"/>
            <name val="Tahoma"/>
            <family val="2"/>
          </font>
          <font>
            <b/>
            <sz val="10"/>
            <color indexed="9"/>
            <name val="Tahoma"/>
            <family val="2"/>
          </font>
          <font>
            <sz val="20"/>
            <name val="Tahoma"/>
            <family val="2"/>
          </font>
        </fonts>
        <fills count="8">
          <fill>
            <patternFill patternType="none"/>
          </fill>
          <fill>
            <patternFill patternType="gray125"/>
          </fill>
          <fill>
            <patternFill patternType="solid">
              <fgColor indexed="44"/>
              <bgColor indexed="64"/>
            </patternFill>
          </fill>
          <fill>
            <patternFill patternType="solid">
              <fgColor indexed="55"/>
              <bgColor indexed="64"/>
            </patternFill>
          </fill>
          <fill>
            <patternFill patternType="solid">
              <fgColor indexed="46"/>
              <bgColor indexed="64"/>
            </patternFill>
          </fill>
          <fill>
            <patternFill patternType="solid">
              <fgColor indexed="41"/>
              <bgColor indexed="64"/>
            </patternFill>
          </fill>
          <fill>
            <patternFill patternType="lightUp">
              <fgColor indexed="41"/>
              <bgColor indexed="22"/>
            </patternFill>
          </fill>
          <fill>
            <patternFill patternType="solid">
              <fgColor indexed="9"/>
              <bgColor indexed="41"/>
            </patternFill>
          </fill>
        </fills>
        <borders count="9">
          <border>
            <left/>
            <right/>
            <top/>
            <bottom/>
            <diagonal/>
          </border>
          <border>
            <left style="thin">
              <color indexed="22"/>
            </left>
            <right style="thin">
              <color indexed="22"/>
            </right>
            <top style="thin">
              <color indexed="22"/>
            </top>
            <bottom style="thin">
              <color indexed="22"/>
            </bottom>
            <diagonal/>
          </border>
          <border>
            <left style="thin">
              <color indexed="22"/>
            </left>
            <right/>
            <top style="thin">
              <color indexed="22"/>
            </top>
            <bottom style="thin">
              <color indexed="22"/>
            </bottom>
            <diagonal/>
          </border>
          <border>
            <left/>
            <right style="thin">
              <color indexed="22"/>
            </right>
            <top style="thin">
              <color indexed="22"/>
            </top>
            <bottom style="thin">
              <color indexed="22"/>
            </bottom>
            <diagonal/>
          </border>
          <border>
            <left style="thin">
              <color indexed="22"/>
            </left>
            <right style="thin">
              <color indexed="22"/>
            </right>
            <top/>
            <bottom style="thin">
              <color indexed="22"/>
            </bottom>
            <diagonal/>
          </border>
          <border>
            <left/>
            <right/>
            <top style="thin">
              <color indexed="22"/>
            </top>
            <bottom style="thin">
              <color indexed="22"/>
            </bottom>
            <diagonal/>
          </border>
          <border>
            <left style="thin">
              <color indexed="22"/>
            </left>
            <right style="thin">
              <color indexed="22"/>
            </right>
            <top style="thin">
              <color indexed="22"/>
            </top>
            <bottom/>
            <diagonal/>
          </border>
          <border>
            <left style="thin">
              <color indexed="22"/>
            </left>
            <right style="thin">
              <color indexed="22"/>
            </right>
            <top/>
            <bottom/>
            <diagonal/>
          </border>
          <border>
            <left style="thin">
              <color indexed="55"/>
            </left>
            <right/>
            <top style="thin">
              <color indexed="22"/>
            </top>
            <bottom style="thin">
              <color indexed="22"/>
            </bottom>
            <diagonal/>
          </border>
        </borders>
        <cellStyleXfs count="4">
          <xf numFmtId="38" fontId="0" fillId="0" borderId="0" applyFont="0" applyBorder="0"
            applyAlignment="0" applyProtection="0"/>
          <xf numFmtId="164" fontId="1" fillId="0" borderId="0" applyFont="0" applyFill="0"
            applyBorder="0" applyAlignment="0" applyProtection="0"/>
          <xf numFmtId="165" fontId="1" fillId="0" borderId="0" applyFont="0" applyFill="0"
            applyBorder="0" applyAlignment="0" applyProtection="0"/>
          <xf numFmtId="49" fontId="1" fillId="0" borderId="0" applyFont="0" applyFill="0" applyBorder="0"
            applyAlignment="0" applyProtection="0"/>
        </cellStyleXfs>
        <cellXfs count="40">
          <xf numFmtId="38" fontId="0" fillId="0" borderId="0" xfId="0"/>
          <xf numFmtId="38" fontId="4" fillId="0" borderId="0" xfId="0" applyFont="1" applyFill="1"
            applyAlignment="1" applyProtection="1">
            <alignment horizontal="left"/>
          </xf>
          <xf numFmtId="38" fontId="2" fillId="0" borderId="0" xfId="0" applyFont="1" applyFill="1"
            applyAlignment="1" applyProtection="1">
            <alignment horizontal="left" vertical="center"/>
          </xf>
          <xf numFmtId="38" fontId="2" fillId="0" borderId="0" xfId="0" applyFont="1" applyAlignment="1"
            applyProtection="1">
            <alignment horizontal="left" vertical="center"/>
          </xf>
          <xf numFmtId="38" fontId="2" fillId="0" borderId="0" xfId="0" applyFont="1" applyFill="1"
            applyAlignment="1" applyProtection="1">
            <alignment horizontal="left"/>
          </xf>
          <xf numFmtId="38" fontId="2" fillId="0" borderId="0" xfId="0" applyFont="1" applyAlignment="1"
            applyProtection="1">
            <alignment horizontal="left"/>
          </xf>
          <xf numFmtId="38" fontId="3" fillId="2" borderId="2" xfId="0" applyFont="1" applyFill="1"
            applyBorder="1" applyAlignment="1" applyProtection="1">
            <alignment horizontal="left" vertical="center"/>
          </xf>
          <xf numFmtId="38" fontId="3" fillId="3" borderId="2" xfId="0" applyFont="1" applyFill="1"
            applyBorder="1" applyAlignment="1" applyProtection="1">
            <alignment horizontal="left" vertical="center"/>
          </xf>
          <xf numFmtId="38" fontId="3" fillId="3" borderId="1" xfId="0" applyFont="1" applyFill="1"
            applyBorder="1" applyAlignment="1" applyProtection="1">
            <alignment horizontal="left" vertical="center"/>
          </xf>
          <xf numFmtId="38" fontId="3" fillId="3" borderId="3" xfId="0" applyFont="1" applyFill="1"
            applyBorder="1" applyAlignment="1" applyProtection="1">
            <alignment horizontal="left" vertical="center"/>
          </xf>
          <xf numFmtId="8" fontId="2" fillId="4" borderId="4" xfId="0" applyNumberFormat="1" applyFont="1"
            applyFill="1" applyBorder="1" applyAlignment="1" applyProtection="1">
            <alignment horizontal="left" vertical="center"/>
          </xf>
          <xf numFmtId="8" fontId="2" fillId="4" borderId="1" xfId="0" applyNumberFormat="1" applyFont="1"
            applyFill="1" applyBorder="1" applyAlignment="1" applyProtection="1">
            <alignment horizontal="left" vertical="center"/>
          </xf>
          <xf numFmtId="166" fontId="2" fillId="0" borderId="0" xfId="0" applyNumberFormat="1"
            applyFont="1" applyFill="1" applyAlignment="1" applyProtection="1">
            <alignment horizontal="right"/>
            <protection locked="0"/>
          </xf>
          <xf numFmtId="38" fontId="2" fillId="5" borderId="1" xfId="0" applyFont="1" applyFill="1"
            applyBorder="1" applyAlignment="1" applyProtection="1">
            <alignment horizontal="left" vertical="center"/>
          </xf>
          <xf numFmtId="8" fontId="2" fillId="4" borderId="3" xfId="0" applyNumberFormat="1" applyFont="1"
            applyFill="1" applyBorder="1" applyAlignment="1" applyProtection="1">
            <alignment horizontal="left" vertical="center"/>
          </xf>
          <xf numFmtId="0" fontId="2" fillId="6" borderId="3" xfId="0" applyNumberFormat="1" applyFont="1"
            applyFill="1" applyBorder="1" applyAlignment="1" applyProtection="1">
            <alignment horizontal="left" vertical="center"/>
          </xf>
          <xf numFmtId="0" fontId="2" fillId="6" borderId="1" xfId="0" applyNumberFormat="1" applyFont="1"
            applyFill="1" applyBorder="1" applyAlignment="1" applyProtection="1">
            <alignment horizontal="left" vertical="center"/>
          </xf>
          <xf numFmtId="6" fontId="2" fillId="4" borderId="1" xfId="0" applyNumberFormat="1" applyFont="1"
            applyFill="1" applyBorder="1" applyAlignment="1" applyProtection="1">
            <alignment horizontal="left" vertical="center"/>
          </xf>
          <xf numFmtId="0" fontId="2" fillId="6" borderId="5" xfId="0" applyNumberFormat="1" applyFont="1"
            applyFill="1" applyBorder="1" applyAlignment="1" applyProtection="1">
            <alignment horizontal="left" vertical="center"/>
          </xf>
          <xf numFmtId="38" fontId="2" fillId="4" borderId="1" xfId="0" applyNumberFormat="1"
            applyFont="1" applyFill="1" applyBorder="1" applyAlignment="1" applyProtection="1">
            <alignment horizontal="left" vertical="center"/>
          </xf>
          <xf numFmtId="38" fontId="2" fillId="5" borderId="2" xfId="0" applyFont="1" applyFill="1"
            applyBorder="1" applyAlignment="1" applyProtection="1">
            <alignment vertical="center"/>
          </xf>
          <xf numFmtId="38" fontId="2" fillId="0" borderId="4" xfId="0" applyFont="1" applyFill="1"
            applyBorder="1" applyAlignment="1" applyProtection="1">
            <alignment horizontal="left" vertical="center"/>
          </xf>
          <xf numFmtId="8" fontId="2" fillId="0" borderId="4" xfId="0" applyNumberFormat="1" applyFont="1"
            applyFill="1" applyBorder="1" applyAlignment="1" applyProtection="1">
            <alignment horizontal="left" vertical="center"/>
            <protection locked="0"/>
          </xf>
          <xf numFmtId="38" fontId="2" fillId="0" borderId="1" xfId="0" applyFont="1" applyFill="1"
            applyBorder="1" applyAlignment="1" applyProtection="1">
            <alignment horizontal="left" vertical="center"/>
          </xf>
          <xf numFmtId="8" fontId="2" fillId="0" borderId="1" xfId="0" applyNumberFormat="1" applyFont="1"
            applyFill="1" applyBorder="1" applyAlignment="1" applyProtection="1">
            <alignment horizontal="left" vertical="center"/>
            <protection locked="0"/>
          </xf>
          <xf numFmtId="8" fontId="2" fillId="7" borderId="1" xfId="0" applyNumberFormat="1" applyFont="1"
            applyFill="1" applyBorder="1" applyAlignment="1" applyProtection="1">
            <alignment horizontal="left" vertical="center"/>
            <protection locked="0"/>
          </xf>
          <xf numFmtId="38" fontId="2" fillId="0" borderId="6" xfId="0" applyFont="1" applyFill="1"
            applyBorder="1" applyAlignment="1" applyProtection="1">
            <alignment horizontal="left" vertical="center"/>
          </xf>
          <xf numFmtId="6" fontId="2" fillId="0" borderId="6" xfId="0" applyNumberFormat="1" applyFont="1"
            applyFill="1" applyBorder="1" applyAlignment="1" applyProtection="1">
            <alignment horizontal="left" vertical="center"/>
            <protection locked="0"/>
          </xf>
          <xf numFmtId="38" fontId="2" fillId="0" borderId="2" xfId="0" applyFont="1" applyFill="1"
            applyBorder="1" applyAlignment="1" applyProtection="1">
            <alignment horizontal="left" vertical="center"/>
          </xf>
          <xf numFmtId="0" fontId="2" fillId="6" borderId="1" xfId="0" applyNumberFormat="1" applyFont="1"
            applyFill="1" applyBorder="1" applyAlignment="1" applyProtection="1">
            <alignment horizontal="left" vertical="center"/>
            <protection locked="0"/>
          </xf>
          <xf numFmtId="6" fontId="2" fillId="0" borderId="1" xfId="0" applyNumberFormat="1" applyFont="1"
            applyFill="1" applyBorder="1" applyAlignment="1" applyProtection="1">
            <alignment horizontal="left" vertical="center"/>
            <protection locked="0"/>
          </xf>
          <xf numFmtId="38" fontId="2" fillId="0" borderId="6" xfId="0" applyFont="1" applyFill="1"
            applyBorder="1" applyAlignment="1" applyProtection="1">
            <alignment horizontal="left" vertical="center"/>
            <protection locked="0"/>
          </xf>
          <xf numFmtId="10" fontId="2" fillId="0" borderId="1" xfId="0" applyNumberFormat="1"
            applyFont="1" applyFill="1" applyBorder="1" applyAlignment="1" applyProtection="1">
            <alignment horizontal="left" vertical="center"/>
            <protection locked="0"/>
          </xf>
          <xf numFmtId="38" fontId="3" fillId="2" borderId="6" xfId="0" applyFont="1" applyFill="1"
            applyBorder="1" applyAlignment="1" applyProtection="1">
            <alignment horizontal="left" vertical="center"/>
          </xf>
          <xf numFmtId="38" fontId="3" fillId="2" borderId="4" xfId="0" applyFont="1" applyFill="1"
            applyBorder="1" applyAlignment="1" applyProtection="1">
            <alignment horizontal="left" vertical="center"/>
          </xf>
          <xf numFmtId="38" fontId="3" fillId="2" borderId="7" xfId="0" applyFont="1" applyFill="1"
            applyBorder="1" applyAlignment="1" applyProtection="1">
            <alignment horizontal="left" vertical="center"/>
          </xf>
          <xf numFmtId="38" fontId="2" fillId="0" borderId="0" xfId="0" applyFont="1" applyFill="1"
            applyBorder="1" applyAlignment="1" applyProtection="1">
            <alignment horizontal="left"/>
            <protection locked="0"/>
          </xf>
          <xf numFmtId="38" fontId="3" fillId="2" borderId="8" xfId="0" applyFont="1" applyFill="1"
            applyBorder="1" applyAlignment="1" applyProtection="1">
            <alignment horizontal="center" vertical="center"/>
          </xf>
          <xf numFmtId="38" fontId="3" fillId="2" borderId="3" xfId="0" applyFont="1" applyFill="1"
            applyBorder="1" applyAlignment="1" applyProtection="1">
            <alignment horizontal="center" vertical="center"/>
          </xf>
          <xf numFmtId="38" fontId="0" fillId="0" borderId="3" xfId="0" applyBorder="1"/>
        </cellXfs>
        <cellStyles count="4">
          <cellStyle name="Date" xfId="1"/>
          <cellStyle name="Fixed" xfId="2"/>
          <cellStyle name="Normal" xfId="0" builtinId="0"/>
          <cellStyle name="Text" xfId="3"/>
        </cellStyles>
        <dxfs count="0"/>
        <tableStyles count="0" defaultTableStyle="TableStyleMedium9" defaultPivotStyle="PivotStyleLight16"/>
        <colors>
          <indexedColors>
            <rgbColor rgb="00000000"/>
            <rgbColor rgb="00FFFFFF"/>
            <rgbColor rgb="00FF0000"/>
            <rgbColor rgb="0000FF00"/>
            <rgbColor rgb="000000FF"/>
            <rgbColor rgb="00FFFF00"/>
            <rgbColor rgb="00FF00FF"/>
            <rgbColor rgb="0000FFFF"/>
            <rgbColor rgb="00000000"/>
            <rgbColor rgb="00FFFFFF"/>
            <rgbColor rgb="00FF0000"/>
            <rgbColor rgb="0000FF00"/>
            <rgbColor rgb="000000FF"/>
            <rgbColor rgb="00FFFF00"/>
            <rgbColor rgb="00FF00FF"/>
            <rgbColor rgb="0000FFFF"/>
            <rgbColor rgb="00800000"/>
            <rgbColor rgb="00008000"/>
            <rgbColor rgb="00000080"/>
            <rgbColor rgb="00808000"/>
            <rgbColor rgb="00800080"/>
            <rgbColor rgb="00008080"/>
            <rgbColor rgb="00C0C0C0"/>
            <rgbColor rgb="00636363"/>
            <rgbColor rgb="008080FF"/>
            <rgbColor rgb="00802060"/>
            <rgbColor rgb="00FFFFC0"/>
            <rgbColor rgb="00A0E0E0"/>
            <rgbColor rgb="00600080"/>
            <rgbColor rgb="00FF8080"/>
            <rgbColor rgb="000080C0"/>
            <rgbColor rgb="00C0C0FF"/>
            <rgbColor rgb="00000080"/>
            <rgbColor rgb="00FF00FF"/>
            <rgbColor rgb="00FFFF00"/>
            <rgbColor rgb="0000FFFF"/>
            <rgbColor rgb="00800080"/>
            <rgbColor rgb="00800000"/>
            <rgbColor rgb="00008080"/>
            <rgbColor rgb="000000FF"/>
            <rgbColor rgb="0000CCFF"/>
            <rgbColor rgb="00EDEEF3"/>
            <rgbColor rgb="00CCFFCC"/>
            <rgbColor rgb="00FFFF99"/>
            <rgbColor rgb="004E5A7A"/>
            <rgbColor rgb="00CC99CC"/>
            <rgbColor rgb="00EAEAEA"/>
            <rgbColor rgb="00E3E3E3"/>
            <rgbColor rgb="003366FF"/>
            <rgbColor rgb="0033CCCC"/>
            <rgbColor rgb="00339933"/>
            <rgbColor rgb="00999933"/>
            <rgbColor rgb="00996633"/>
            <rgbColor rgb="00996666"/>
            <rgbColor rgb="00666699"/>
            <rgbColor rgb="00969696"/>
            <rgbColor rgb="003333CC"/>
            <rgbColor rgb="00336666"/>
            <rgbColor rgb="00003300"/>
            <rgbColor rgb="00333300"/>
            <rgbColor rgb="00663300"/>
            <rgbColor rgb="00993366"/>
            <rgbColor rgb="00333399"/>
            <rgbColor rgb="00424242"/>
          </indexedColors>
        </colors>
        <extLst>
          <ext uri="EB79DEF2-80B8-43e5-95BD-54CBDDF9020C"
            xmlns:x14="http://schemas.microsoft.com/office/spreadsheetml/2009/9/main">
            <x14:slicerStyles defaultSlicerStyle="SlicerStyleLight1"/>
          </ext>
          <ext uri="EB79DEF2-80B8-43e5-95BD-54CBDDF9020C"
            xmlns:x14="http://schemas.microsoft.com/office/spreadsheetml/2009/9/main">
            <x14:slicerStyles defaultSlicerStyle="SlicerStyleLight1"/>
          </ext>
        </extLst>
      </styleSheet>
  
    let $workBook :=
      <workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"
        xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
        <fileVersion appName="xl" lastEdited="5" lowestEdited="5" rupBuild="9302"/>
        <workbookPr showInkAnnotation="0" codeName="ThisWorkbook" defaultThemeVersion="124226"/>
        <bookViews>
          <workbookView xWindow="690" yWindow="-60" windowWidth="12120" windowHeight="8295"/>
        </bookViews>
        <sheets>
          <sheet name="Year-End Tax Plan" sheetId="2" r:id="rId1"/>
        </sheets>
        <definedNames>
          <definedName name="AdjustmentsToGrossIncFullYear">'Year-End Tax Plan'!$E$14:$E$17</definedName>
          <definedName name="AdjustmentsToGrossIncToDate">'Year-End Tax Plan'!$C$14:$C$17</definedName>
          <definedName name="AdjustmentsToGrossIncYearEnd">'Year-End Tax Plan'!$D$14:$D$17</definedName>
          <definedName name="FilingDate">'Year-End Tax Plan'!$E$1</definedName>
          <definedName name="FilingPerson">'Year-End Tax Plan'!$C$1</definedName>
          <definedName name="GrossIncomeFullYear">'Year-End Tax Plan'!$E$4:$E$10</definedName>
          <definedName name="GrossIncomeToDate">'Year-End Tax Plan'!$C$4:$C$10</definedName>
          <definedName name="GrossIncomeToYear">'Year-End Tax Plan'!$D$4:$D$10</definedName>
          <definedName name="ItemizedDeductionsFullYear">'Year-End Tax Plan'!$E$22:$E$29</definedName>
          <definedName name="ItemizedDeductionsToDate">'Year-End Tax Plan'!$C$22:$C$29</definedName>
          <definedName name="ItemizedDeductionsYearEnd">'Year-End Tax Plan'!$D$22:$D$29</definedName>
          <definedName name="NumberOfExemptions">'Year-End Tax Plan'!$C$34</definedName>
          <definedName name="_xlnm.Print_Area" localSheetId="0">'Year-End Tax Plan'!$B$1:$E$39</definedName>
          <definedName name="StandardDeduction">'Year-End Tax Plan'!$C$31</definedName>
          <definedName name="TargetedTaxableIncome">'Year-End Tax Plan'!$E$38</definedName>
          <definedName name="TargetedTaxBracket">'Year-End Tax Plan'!$E$39</definedName>
          <definedName name="TaxableIncome">'Year-End Tax Plan'!$E$36</definedName>
          <definedName name="TaxBracket">'Year-End Tax Plan'!$E$37</definedName>
          <definedName name="ValueOfExemptions">'Year-End Tax Plan'!$C$33</definedName>
        </definedNames>
        <calcPr calcId="144525"/>
      </workbook>
  
    let $binFileUri    := "/tmp/users/template/workpaper1.xlsx"
    let $excelFile1    := xdmp:document-get($binFileUri)
    let $printerBinDoc := xdmp:zip-get($excelFile1, "xl/printerSettings/printerSettings1.bin")
  
    let $theme :=
    <a:theme xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" name="Office Theme">
      <a:themeElements>
        <a:clrScheme name="Office">
          <a:dk1>
            <a:sysClr val="windowText" lastClr="000000"/>
          </a:dk1>
          <a:lt1>
            <a:sysClr val="window" lastClr="FFFFFF"/>
          </a:lt1>
          <a:dk2>
            <a:srgbClr val="1F497D"/>
          </a:dk2>
          <a:lt2>
            <a:srgbClr val="EEECE1"/>
          </a:lt2>
          <a:accent1>
            <a:srgbClr val="4F81BD"/>
          </a:accent1>
          <a:accent2>
            <a:srgbClr val="C0504D"/>
          </a:accent2>
          <a:accent3>
            <a:srgbClr val="9BBB59"/>
          </a:accent3>
          <a:accent4>
            <a:srgbClr val="8064A2"/>
          </a:accent4>
          <a:accent5>
            <a:srgbClr val="4BACC6"/>
          </a:accent5>
          <a:accent6>
            <a:srgbClr val="F79646"/>
          </a:accent6>
          <a:hlink>
            <a:srgbClr val="0000FF"/>
          </a:hlink>
          <a:folHlink>
            <a:srgbClr val="800080"/>
          </a:folHlink>
        </a:clrScheme>
        <a:fontScheme name="Office">
          <a:majorFont>
            <a:latin typeface="Cambria"/>
            <a:ea typeface=""/>
            <a:cs typeface=""/>
            <a:font script="Jpan" typeface="ＭＳ Ｐゴシック"/>
            <a:font script="Hang" typeface="맑은 고딕"/>
            <a:font script="Hans" typeface="宋体"/>
            <a:font script="Hant" typeface="新細明體"/>
            <a:font script="Arab" typeface="Times New Roman"/>
            <a:font script="Hebr" typeface="Times New Roman"/>
            <a:font script="Thai" typeface="Tahoma"/>
            <a:font script="Ethi" typeface="Nyala"/>
            <a:font script="Beng" typeface="Vrinda"/>
            <a:font script="Gujr" typeface="Shruti"/>
            <a:font script="Khmr" typeface="MoolBoran"/>
            <a:font script="Knda" typeface="Tunga"/>
            <a:font script="Guru" typeface="Raavi"/>
            <a:font script="Cans" typeface="Euphemia"/>
            <a:font script="Cher" typeface="Plantagenet Cherokee"/>
            <a:font script="Yiii" typeface="Microsoft Yi Baiti"/>
            <a:font script="Tibt" typeface="Microsoft Himalaya"/>
            <a:font script="Thaa" typeface="MV Boli"/>
            <a:font script="Deva" typeface="Mangal"/>
            <a:font script="Telu" typeface="Gautami"/>
            <a:font script="Taml" typeface="Latha"/>
            <a:font script="Syrc" typeface="Estrangelo Edessa"/>
            <a:font script="Orya" typeface="Kalinga"/>
            <a:font script="Mlym" typeface="Kartika"/>
            <a:font script="Laoo" typeface="DokChampa"/>
            <a:font script="Sinh" typeface="Iskoola Pota"/>
            <a:font script="Mong" typeface="Mongolian Baiti"/>
            <a:font script="Viet" typeface="Times New Roman"/>
            <a:font script="Uigh" typeface="Microsoft Uighur"/>
            <a:font script="Geor" typeface="Sylfaen"/>
          </a:majorFont>
          <a:minorFont>
            <a:latin typeface="Calibri"/>
            <a:ea typeface=""/>
            <a:cs typeface=""/>
            <a:font script="Jpan" typeface="ＭＳ Ｐゴシック"/>
            <a:font script="Hang" typeface="맑은 고딕"/>
            <a:font script="Hans" typeface="宋体"/>
            <a:font script="Hant" typeface="新細明體"/>
            <a:font script="Arab" typeface="Arial"/>
            <a:font script="Hebr" typeface="Arial"/>
            <a:font script="Thai" typeface="Tahoma"/>
            <a:font script="Ethi" typeface="Nyala"/>
            <a:font script="Beng" typeface="Vrinda"/>
            <a:font script="Gujr" typeface="Shruti"/>
            <a:font script="Khmr" typeface="DaunPenh"/>
            <a:font script="Knda" typeface="Tunga"/>
            <a:font script="Guru" typeface="Raavi"/>
            <a:font script="Cans" typeface="Euphemia"/>
            <a:font script="Cher" typeface="Plantagenet Cherokee"/>
            <a:font script="Yiii" typeface="Microsoft Yi Baiti"/>
            <a:font script="Tibt" typeface="Microsoft Himalaya"/>
            <a:font script="Thaa" typeface="MV Boli"/>
            <a:font script="Deva" typeface="Mangal"/>
            <a:font script="Telu" typeface="Gautami"/>
            <a:font script="Taml" typeface="Latha"/>
            <a:font script="Syrc" typeface="Estrangelo Edessa"/>
            <a:font script="Orya" typeface="Kalinga"/>
            <a:font script="Mlym" typeface="Kartika"/>
            <a:font script="Laoo" typeface="DokChampa"/>
            <a:font script="Sinh" typeface="Iskoola Pota"/>
            <a:font script="Mong" typeface="Mongolian Baiti"/>
            <a:font script="Viet" typeface="Arial"/>
            <a:font script="Uigh" typeface="Microsoft Uighur"/>
            <a:font script="Geor" typeface="Sylfaen"/>
          </a:minorFont>
        </a:fontScheme>
        <a:fmtScheme name="Office">
          <a:fillStyleLst>
            <a:solidFill>
              <a:schemeClr val="phClr"/>
            </a:solidFill>
            <a:gradFill rotWithShape="1">
              <a:gsLst>
                <a:gs pos="0">
                  <a:schemeClr val="phClr">
                    <a:tint val="50000"/>
                    <a:satMod val="300000"/>
                  </a:schemeClr>
                </a:gs>
                <a:gs pos="35000">
                  <a:schemeClr val="phClr">
                    <a:tint val="37000"/>
                    <a:satMod val="300000"/>
                  </a:schemeClr>
                </a:gs>
                <a:gs pos="100000">
                  <a:schemeClr val="phClr">
                    <a:tint val="15000"/>
                    <a:satMod val="350000"/>
                  </a:schemeClr>
                </a:gs>
              </a:gsLst>
              <a:lin ang="16200000" scaled="1"/>
            </a:gradFill>
            <a:gradFill rotWithShape="1">
              <a:gsLst>
                <a:gs pos="0">
                  <a:schemeClr val="phClr">
                    <a:shade val="51000"/>
                    <a:satMod val="130000"/>
                  </a:schemeClr>
                </a:gs>
                <a:gs pos="80000">
                  <a:schemeClr val="phClr">
                    <a:shade val="93000"/>
                    <a:satMod val="130000"/>
                  </a:schemeClr>
                </a:gs>
                <a:gs pos="100000">
                  <a:schemeClr val="phClr">
                    <a:shade val="94000"/>
                    <a:satMod val="135000"/>
                  </a:schemeClr>
                </a:gs>
              </a:gsLst>
              <a:lin ang="16200000" scaled="0"/>
            </a:gradFill>
          </a:fillStyleLst>
          <a:lnStyleLst>
            <a:ln w="9525" cap="flat" cmpd="sng" algn="ctr">
              <a:solidFill>
                <a:schemeClr val="phClr">
                  <a:shade val="95000"/>
                  <a:satMod val="105000"/>
                </a:schemeClr>
              </a:solidFill>
              <a:prstDash val="solid"/>
            </a:ln>
            <a:ln w="25400" cap="flat" cmpd="sng" algn="ctr">
              <a:solidFill>
                <a:schemeClr val="phClr"/>
              </a:solidFill>
              <a:prstDash val="solid"/>
            </a:ln>
            <a:ln w="38100" cap="flat" cmpd="sng" algn="ctr">
              <a:solidFill>
                <a:schemeClr val="phClr"/>
              </a:solidFill>
              <a:prstDash val="solid"/>
            </a:ln>
          </a:lnStyleLst>
          <a:effectStyleLst>
            <a:effectStyle>
              <a:effectLst>
                <a:outerShdw blurRad="40000" dist="20000" dir="5400000" rotWithShape="0">
                  <a:srgbClr val="000000">
                    <a:alpha val="38000"/>
                  </a:srgbClr>
                </a:outerShdw>
              </a:effectLst>
            </a:effectStyle>
            <a:effectStyle>
              <a:effectLst>
                <a:outerShdw blurRad="40000" dist="23000" dir="5400000" rotWithShape="0">
                  <a:srgbClr val="000000">
                    <a:alpha val="35000"/>
                  </a:srgbClr>
                </a:outerShdw>
              </a:effectLst>
            </a:effectStyle>
            <a:effectStyle>
              <a:effectLst>
                <a:outerShdw blurRad="40000" dist="23000" dir="5400000" rotWithShape="0">
                  <a:srgbClr val="000000">
                    <a:alpha val="35000"/>
                  </a:srgbClr>
                </a:outerShdw>
              </a:effectLst>
              <a:scene3d>
                <a:camera prst="orthographicFront">
                  <a:rot lat="0" lon="0" rev="0"/>
                </a:camera>
                <a:lightRig rig="threePt" dir="t">
                  <a:rot lat="0" lon="0" rev="1200000"/>
                </a:lightRig>
              </a:scene3d>
              <a:sp3d>
                <a:bevelT w="63500" h="25400"/>
              </a:sp3d>
            </a:effectStyle>
          </a:effectStyleLst>
          <a:bgFillStyleLst>
            <a:solidFill>
              <a:schemeClr val="phClr"/>
            </a:solidFill>
            <a:gradFill rotWithShape="1">
              <a:gsLst>
                <a:gs pos="0">
                  <a:schemeClr val="phClr">
                    <a:tint val="40000"/>
                    <a:satMod val="350000"/>
                  </a:schemeClr>
                </a:gs>
                <a:gs pos="40000">
                  <a:schemeClr val="phClr">
                    <a:tint val="45000"/>
                    <a:shade val="99000"/>
                    <a:satMod val="350000"/>
                  </a:schemeClr>
                </a:gs>
                <a:gs pos="100000">
                  <a:schemeClr val="phClr">
                    <a:shade val="20000"/>
                    <a:satMod val="255000"/>
                  </a:schemeClr>
                </a:gs>
              </a:gsLst>
              <a:path path="circle">
                <a:fillToRect l="50000" t="-80000" r="50000" b="180000"/>
              </a:path>
            </a:gradFill>
            <a:gradFill rotWithShape="1">
              <a:gsLst>
                <a:gs pos="0">
                  <a:schemeClr val="phClr">
                    <a:tint val="80000"/>
                    <a:satMod val="300000"/>
                  </a:schemeClr>
                </a:gs>
                <a:gs pos="100000">
                  <a:schemeClr val="phClr">
                    <a:shade val="30000"/>
                    <a:satMod val="200000"/>
                  </a:schemeClr>
                </a:gs>
              </a:gsLst>
              <a:path path="circle">
                <a:fillToRect l="50000" t="50000" r="50000" b="50000"/>
              </a:path>
            </a:gradFill>
          </a:bgFillStyleLst>
        </a:fmtScheme>
      </a:themeElements>
      <a:objectDefaults/>
      <a:extraClrSchemeLst/>
    </a:theme>
  
    let $sheet1Rels :=
      <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
        <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/printerSettings" Target="../printerSettings/printerSettings1.bin"/>
      </Relationships>
  
    let $wkBookRels :=
      <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
        <Relationship Id="rId3" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>
        <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/theme" Target="theme/theme1.xml"/>
        <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/>
        <Relationship Id="rId5" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/calcChain" Target="calcChain.xml"/>
        <Relationship Id="rId4" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/sharedStrings" Target="sharedStrings.xml"/>
      </Relationships>
  
    let $relsRels :=
      <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
        <Relationship Id="rId3" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/extended-properties" Target="docProps/app.xml"/>
        <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/package/2006/relationships/metadata/core-properties" Target="docProps/core.xml"/>
        <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>
      </Relationships>

  let $c4  := $taxPlan/grossIncome/actual/c4/text()
  let $c5  := $taxPlan/grossIncome/actual/c5/text()
  let $c6  := $taxPlan/grossIncome/actual/c6/text()
  let $c7  := $taxPlan/grossIncome/actual/c7/text()
  let $c8  := $taxPlan/grossIncome/actual/c8/text()
  let $c9  := $taxPlan/grossIncome/actual/c9/text()
  let $c10 := $taxPlan/grossIncome/actual/c10/text()
  let $c11 := $taxPlan/grossIncome/actual/c11/text()

  let $c14 := $taxPlan/adjGrossIncome/actual/c14/text()
  let $c15 := $taxPlan/adjGrossIncome/actual/c15/text()
  let $c16 := $taxPlan/adjGrossIncome/actual/c16/text()
  let $c17 := $taxPlan/adjGrossIncome/actual/c17/text()
  let $c18 := $taxPlan/adjGrossIncome/actual/c18/text()
  let $c19 := $taxPlan/adjGrossIncome/actual/c19/text()

  let $c22 := $taxPlan/allowableItemizedDeductions/actual/c22/text()
  let $c23 := $taxPlan/allowableItemizedDeductions/actual/c23/text()
  let $c24 := $taxPlan/allowableItemizedDeductions/actual/c24/text()
  let $c25 := $taxPlan/allowableItemizedDeductions/actual/c25/text()
  let $c26 := $taxPlan/allowableItemizedDeductions/actual/c26/text()
  let $c27 := $taxPlan/allowableItemizedDeductions/actual/c27/text()
  let $c28 := $taxPlan/allowableItemizedDeductions/actual/c28/text()
  let $c29 := $taxPlan/allowableItemizedDeductions/actual/c29/text()
  let $c30 := $taxPlan/allowableItemizedDeductions/actual/c30/text()
  let $c31 := $taxPlan/allowableItemizedDeductions/actual/c31/text()
  let $c33 := $taxPlan/allowableItemizedDeductions/actual/c33/text()
  let $c34 := $taxPlan/allowableItemizedDeductions/actual/c34/text()

  let $d4  := $taxPlan/grossIncome/estimated/yearEnd/d4/text()
  let $d5  := $taxPlan/grossIncome/estimated/yearEnd/d5/text()
  let $d6  := $taxPlan/grossIncome/estimated/yearEnd/d6/text()
  let $d7  := $taxPlan/grossIncome/estimated/yearEnd/d7/text()
  let $d8  := $taxPlan/grossIncome/estimated/yearEnd/d8/text()
  let $d9  := $taxPlan/grossIncome/estimated/yearEnd/d9/text()
  let $d10 := $taxPlan/grossIncome/estimated/yearEnd/d10/text()
  let $d11 := $taxPlan/grossIncome/estimated/yearEnd/d11/text()

  let $d14 := $taxPlan/adjGrossIncome/estimated/yearEnd/d14/text()
  let $d15 := $taxPlan/adjGrossIncome/estimated/yearEnd/d15/text()
  let $d16 := $taxPlan/adjGrossIncome/estimated/yearEnd/d16/text()
  let $d17 := $taxPlan/adjGrossIncome/estimated/yearEnd/d17/text()
  let $d18 := $taxPlan/adjGrossIncome/estimated/yearEnd/d18/text()
  let $d19 := $taxPlan/adjGrossIncome/estimated/yearEnd/d19/text()

  let $d22 := $taxPlan/allowableItemizedDeductions/estimated/yearEnd/d22/text()
  let $d23 := $taxPlan/allowableItemizedDeductions/estimated/yearEnd/d23/text()
  let $d24 := $taxPlan/allowableItemizedDeductions/estimated/yearEnd/d24/text()
  let $d25 := $taxPlan/allowableItemizedDeductions/estimated/yearEnd/d25/text()
  let $d26 := $taxPlan/allowableItemizedDeductions/estimated/yearEnd/d26/text()
  let $d27 := $taxPlan/allowableItemizedDeductions/estimated/yearEnd/d27/text()
  let $d28 := $taxPlan/allowableItemizedDeductions/estimated/yearEnd/d28/text()
  let $d29 := $taxPlan/allowableItemizedDeductions/estimated/yearEnd/d29/text()
  let $d30 := $taxPlan/allowableItemizedDeductions/estimated/yearEnd/d30/text()

  let $e4  := $taxPlan/grossIncome/estimated/fullYear/e4/text()
  let $e5  := $taxPlan/grossIncome/estimated/fullYear/e5/text()
  let $e6  := $taxPlan/grossIncome/estimated/fullYear/e6/text()
  let $e7  := $taxPlan/grossIncome/estimated/fullYear/e7/text()
  let $e8  := $taxPlan/grossIncome/estimated/fullYear/e8/text()
  let $e9  := $taxPlan/grossIncome/estimated/fullYear/e9/text()
  let $e10 := $taxPlan/grossIncome/estimated/fullYear/e10/text()
  let $e11 := $taxPlan/grossIncome/estimated/fullYear/e11/text()

  let $e14 := $taxPlan/adjGrossIncome/estimated/fullYear/e14/text()
  let $e15 := $taxPlan/adjGrossIncome/estimated/fullYear/e15/text()
  let $e16 := $taxPlan/adjGrossIncome/estimated/fullYear/e16/text()
  let $e17 := $taxPlan/adjGrossIncome/estimated/fullYear/e17/text()
  let $e18 := $taxPlan/adjGrossIncome/estimated/fullYear/e18/text()
  let $e19 := $taxPlan/adjGrossIncome/estimated/fullYear/e19/text()

  let $e22 := $taxPlan/allowableItemizedDeductions/estimated/fullYear/e22/text()
  let $e23 := $taxPlan/allowableItemizedDeductions/estimated/fullYear/e23/text()
  let $e24 := $taxPlan/allowableItemizedDeductions/estimated/fullYear/e24/text()
  let $e25 := $taxPlan/allowableItemizedDeductions/estimated/fullYear/e25/text()
  let $e26 := $taxPlan/allowableItemizedDeductions/estimated/fullYear/e26/text()
  let $e27 := $taxPlan/allowableItemizedDeductions/estimated/fullYear/e27/text()
  let $e28 := $taxPlan/allowableItemizedDeductions/estimated/fullYear/e28/text()
  let $e29 := $taxPlan/allowableItemizedDeductions/estimated/fullYear/e29/text()
  let $e30 := $taxPlan/allowableItemizedDeductions/estimated/fullYear/e30/text()
  let $e32 := $taxPlan/allowableItemizedDeductions/estimated/fullYear/e32/text()
  let $e34 := $taxPlan/allowableItemizedDeductions/estimated/fullYear/e34/text()
  let $e35 := $taxPlan/allowableItemizedDeductions/estimated/fullYear/e35/text()
  let $e36 := $taxPlan/allowableItemizedDeductions/estimated/fullYear/e36/text()
  let $e37 := $taxPlan/allowableItemizedDeductions/estimated/fullYear/e37/text()
  let $e38 := $taxPlan/allowableItemizedDeductions/estimated/fullYear/e38/text()
  let $e39 := $taxPlan/allowableItemizedDeductions/estimated/fullYear/e39/text()
  
  let $f30 := $taxPlan/allowableItemizedDeductions/estimated/itemizedDeductionPct/text()

  let $sheet1 :=
    <worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"
      xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"
      xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006" mc:Ignorable="x14ac"
      xmlns:x14ac="http://schemas.microsoft.com/office/spreadsheetml/2009/9/ac">
      <sheetPr codeName="Sheet1" enableFormatConditionsCalculation="0">
        <tabColor indexed="44"/>
        <pageSetUpPr autoPageBreaks="0"/>
      </sheetPr>
      <dimension ref="A1:G39"/>
      <sheetViews>
        <sheetView showGridLines="0" tabSelected="1" zoomScaleNormal="100" workbookViewId="0"/>
      </sheetViews>
      <sheetFormatPr defaultRowHeight="12.75" x14ac:dyDescent="0.2"/>
      <cols>
        <col min="1" max="1" width="1.7109375" style="3" customWidth="1"/>
        <col min="2" max="2" width="46.5703125" style="3" customWidth="1"/>
        <col min="3" max="5" width="16.85546875" style="3" customWidth="1"/>
        <col min="6" max="6" width="4.7109375" style="3" customWidth="1"/>
        <col min="7" max="7" width="11.7109375" style="3" customWidth="1"/>
        <col min="8" max="16384" width="9.140625" style="3"/>
      </cols>
      <sheetData>
        <row r="1" spans="1:7" s="5" customFormat="1" ht="37.5" customHeight="1" x14ac:dyDescent="0.35">
          <c r="A1" s="4"/>
          <c r="B1" s="1" t="s">
            <v>40</v>
          </c>
          <c r="C1" s="36" t="s">
            <v>41</v>
          </c>
          <c r="D1" s="36"/>
          <c r="E1" s="12">
            <v>{$filingDate}</v>
          </c>
          <c r="F1" s="4"/>
        </row>
        <row r="2" spans="1:7" ht="15.95" customHeight="1" x14ac:dyDescent="0.2">
          <c r="A2" s="2"/>
          <c r="B2" s="33" t="s">
            <v>35</v>
          </c>
          <c r="C2" s="6" t="s">
            <v>0</v>
          </c>
          <c r="D2" s="37" t="s">
            <v>1</v>
          </c>
          <c r="E2" s="38"/>
          <c r="F2" s="2"/>
          <c r="G2" s="12"/>
        </row>
        <row r="3" spans="1:7" ht="15.95" customHeight="1" x14ac:dyDescent="0.2">
          <c r="A3" s="2"/>
          <c r="B3" s="34"/>
          <c r="C3" s="7" t="s">
            <v>2</v>
          </c>
          <c r="D3" s="8" t="s">
            <v>3</v>
          </c>
          <c r="E3" s="9" t="s">
            <v>4</v>
          </c>
          <c r="F3" s="2"/>
        </row>
        <row r="4" spans="1:7" ht="18" customHeight="1" x14ac:dyDescent="0.2">
          <c r="A4" s="2"/>
          <c r="B4" s="21" t="s">
            <v>7</v>
          </c>
          <c r="C4" s="22">
            <v>{$c4}</v>
          </c>
          <c r="D4" s="22">
            <v>{$d4}</v>
          </c>
          <c r="E4" s="10">
            <f t="shared" ref="E4:E10" si="0">IF(SUM(D4,C4),C4+D4,"")</f>
            <v>{$e4}</v>
          </c>
          <c r="F4" s="2"/>
        </row>
        <row r="5" spans="1:7" ht="18" customHeight="1" x14ac:dyDescent="0.2">
          <c r="A5" s="2"/>
          <c r="B5" s="23" t="s">
            <v>8</v>
          </c>
          <c r="C5" s="24">
            <v>{$c5}</v>
          </c>
          <c r="D5" s="24">
            <v>{$d5}</v>
          </c>
          <c r="E5" s="11">
            <f t="shared" si="0"/>
            <v>{$e5}</v>
          </c>
          <c r="F5" s="2"/>
        </row>
        <row r="6" spans="1:7" ht="18" customHeight="1" x14ac:dyDescent="0.2">
          <c r="A6" s="2"/>
          <c r="B6" s="23" t="s">
            <v>9</v>
          </c>
          <c r="C6" s="24">
            <v>{$c6}</v>
          </c>
          <c r="D6" s="24">
            <v>{$d6}</v>
          </c>
          <c r="E6" s="11">
            <f t="shared" si="0"/>
            <v>{$e6}</v>
          </c>
          <c r="F6" s="2"/>
        </row>
        <row r="7" spans="1:7" ht="18" customHeight="1" x14ac:dyDescent="0.2">
          <c r="A7" s="2"/>
          <c r="B7" s="23" t="s">
            <v>10</v>
          </c>
          <c r="C7" s="24">
            <v>{$c7}</v>
          </c>
          <c r="D7" s="24">
            <v>{$d7}</v>
          </c>
          <c r="E7" s="11">
            <f t="shared" si="0"/>
            <v>{$e7}</v>
          </c>
          <c r="F7" s="2"/>
        </row>
        <row r="8" spans="1:7" ht="18" customHeight="1" x14ac:dyDescent="0.2">
          <c r="A8" s="2"/>
          <c r="B8" s="23" t="s">
            <v>11</v>
          </c>
          <c r="C8" s="24">
            <v>{$c8}</v>
          </c>
          <c r="D8" s="24">
            <v>{$d8}</v>
          </c>
          <c r="E8" s="11">
            <f t="shared" si="0"/>
            <v>{$e8}</v>
          </c>
          <c r="F8" s="2"/>
        </row>
        <row r="9" spans="1:7" ht="18" customHeight="1" x14ac:dyDescent="0.2">
          <c r="A9" s="2"/>
          <c r="B9" s="23" t="s">
            <v>12</v>
          </c>
          <c r="C9" s="24">
            <v>{$c9}</v>
          </c>
          <c r="D9" s="24">
            <v>{$d9}</v>
          </c>
          <c r="E9" s="11">
            <f t="shared" si="0"/>
            <v>{$e9}</v>
          </c>
          <c r="F9" s="2"/>
        </row>
        <row r="10" spans="1:7" ht="18" customHeight="1" x14ac:dyDescent="0.2">
          <c r="A10" s="2"/>
          <c r="B10" s="23" t="s">
            <v>13</v>
          </c>
          <c r="C10" s="24">
            <v>{$c10}</v>
          </c>
          <c r="D10" s="24">
            <v>{$d10}</v>
          </c>
          <c r="E10" s="11">
            <f t="shared" si="0"/>
            <v>{$e10}</v>
          </c>
          <c r="F10" s="2"/>
        </row>
        <row r="11" spans="1:7" ht="18" customHeight="1" x14ac:dyDescent="0.2">
          <c r="A11" s="2"/>
          <c r="B11" s="13" t="s">
            <v>36</v>
          </c>
          <c r="C11" s="11">
            <f>IF(SUM(C4:C10),SUM(C4:C10),"")</f>
            <v>{$c11}</v>
          </c>
          <c r="D11" s="11">
            <f>IF(SUM(D4:D10),SUM(D4:D10),"")</f>
            <v>{$d11}</v>
          </c>
          <c r="E11" s="11">
            <f>IF(SUM(E4:E10),SUM(E4:E10),"")</f>
            <v>{$e11}</v>
          </c>
          <c r="F11" s="2"/>
        </row>
        <row r="12" spans="1:7" ht="15.95" customHeight="1" x14ac:dyDescent="0.2">
          <c r="A12" s="2"/>
          <c r="B12" s="35" t="s">
            <v>34</v>
          </c>
          <c r="C12" s="6" t="s">
            <v>0</v>
          </c>
          <c r="D12" s="37" t="s">
            <v>1</v>
          </c>
          <c r="E12" s="39"/>
          <c r="F12" s="2"/>
        </row>
        <row r="13" spans="1:7" ht="15.95" customHeight="1" x14ac:dyDescent="0.2">
          <c r="A13" s="2"/>
          <c r="B13" s="34"/>
          <c r="C13" s="7" t="s">
            <v>2</v>
          </c>
          <c r="D13" s="8" t="s">
            <v>3</v>
          </c>
          <c r="E13" s="9" t="s">
            <v>4</v>
          </c>
          <c r="F13" s="2"/>
        </row>
        <row r="14" spans="1:7" ht="18" customHeight="1" x14ac:dyDescent="0.2">
          <c r="A14" s="2"/>
          <c r="B14" s="21" t="s">
            <v>14</v>
          </c>
          <c r="C14" s="22">
            <v>{$c14}</v>
          </c>
          <c r="D14" s="22">
            <v>{$d14}</v>
          </c>
          <c r="E14" s="10">
            <f>IF(AND(D14=0,C14=0),"",C14+D14)</f>
            <v>{$e14}</v>
          </c>
          <c r="F14" s="2"/>
        </row>
        <row r="15" spans="1:7" ht="18" customHeight="1" x14ac:dyDescent="0.2">
          <c r="A15" s="2"/>
          <c r="B15" s="23" t="s">
            <v>15</v>
          </c>
          <c r="C15" s="24">
            <v>{$c15}</v>
          </c>
          <c r="D15" s="24">
            <v>{$d15}</v>
          </c>
          <c r="E15" s="11">
            <f>IF(SUM(D15,C15),C15+D15,"")</f>
            <v>{$e15}</v>
          </c>
          <c r="F15" s="2"/>
        </row>
        <row r="16" spans="1:7" ht="18" customHeight="1" x14ac:dyDescent="0.2">
          <c r="A16" s="2"/>
          <c r="B16" s="23" t="s">
            <v>16</v>
          </c>
          <c r="C16" s="24">
            <v>{$c16}</v>
          </c>
          <c r="D16" s="24">
            <v>{$d16}</v>
          </c>
          <c r="E16" s="11">
            <f>IF(SUM(D16,C16),C16+D16,"")</f>
            <v>{$e16}</v>
          </c>
          <c r="F16" s="2"/>
        </row>
        <row r="17" spans="1:6" ht="18" customHeight="1" x14ac:dyDescent="0.2">
          <c r="A17" s="2"/>
          <c r="B17" s="23" t="s">
            <v>17</v>
          </c>
          <c r="C17" s="24">
            <v>{$c17}</v>
          </c>
          <c r="D17" s="24">
            <v>{$d17}</v>
          </c>
          <c r="E17" s="11">
            <f>IF(SUM(D17,C17),C17+D17,"")</f>
            <v>{$e17}</v>
          </c>
          <c r="F17" s="2"/>
        </row>
        <row r="18" spans="1:6" ht="18" customHeight="1" x14ac:dyDescent="0.2">
          <c r="A18" s="2"/>
          <c r="B18" s="13" t="s">
            <v>37</v>
          </c>
          <c r="C18" s="11">
            <f>IF(SUM(C14:C17),SUM(C14:C17),"")</f>
            <v>{$c18}</v>
          </c>
          <c r="D18" s="11">
            <f>IF(SUM(D14:D17),SUM(D14:D17),"")</f>
            <v>{$d18}</v>
          </c>
          <c r="E18" s="11">
            <f>IF(SUM(E14:E17),SUM(E14:E17),"")</f>
            <v>{$e18}</v>
          </c>
          <c r="F18" s="2"/>
        </row>
        <row r="19" spans="1:6" ht="18" customHeight="1" x14ac:dyDescent="0.2">
          <c r="A19" s="2"/>
          <c r="B19" s="13" t="s">
            <v>33</v>
          </c>
          <c r="C19" s="14">
            <f>IF(AND(SUM(C18)=0,SUM(C11)=0),"",SUM(C11)-SUM(C18))</f>
            <v>{$c19}</v>
          </c>
          <c r="D19" s="11">
            <f>IF(AND(SUM(D18)=0,SUM(D11)=0),"",SUM(D11)-SUM(D18))</f>
            <v>{$d19}</v>
          </c>
          <c r="E19" s="11">
            <f>IF(AND(SUM(E18)=0,SUM(E11)=0),"",SUM(E11)-SUM(E18))</f>
            <v>{$e19}</v>
          </c>
          <c r="F19" s="2"/>
        </row>
        <row r="20" spans="1:6" ht="15.95" customHeight="1" x14ac:dyDescent="0.2">
          <c r="A20" s="2"/>
          <c r="B20" s="35" t="s">
            <v>32</v>
          </c>
          <c r="C20" s="6" t="s">
            <v>0</v>
          </c>
          <c r="D20" s="37" t="s">
            <v>1</v>
          </c>
          <c r="E20" s="38"/>
          <c r="F20" s="2"/>
        </row>
        <row r="21" spans="1:6" ht="15.95" customHeight="1" x14ac:dyDescent="0.2">
          <c r="A21" s="2"/>
          <c r="B21" s="34"/>
          <c r="C21" s="7" t="s">
            <v>2</v>
          </c>
          <c r="D21" s="8" t="s">
            <v>3</v>
          </c>
          <c r="E21" s="9" t="s">
            <v>4</v>
          </c>
          <c r="F21" s="2"/>
        </row>
        <row r="22" spans="1:6" ht="18" customHeight="1" x14ac:dyDescent="0.2">
          <c r="A22" s="2"/>
          <c r="B22" s="21" t="s">
            <v>5</v>
          </c>
          <c r="C22" s="22">
            <v>{$c22}</v>
          </c>
          <c r="D22" s="22">
            <v>{$d22}</v>
          </c>
          <c r="E22" s="10">
            <f t="shared" ref="E22:E29" si="1">IF(SUM(D22,C22),C22+D22,"")</f>
            <v>{$e22}</v>
          </c>
          <c r="F22" s="2"/>
        </row>
        <row r="23" spans="1:6" ht="18" customHeight="1" x14ac:dyDescent="0.2">
          <c r="A23" s="2"/>
          <c r="B23" s="23" t="s">
            <v>6</v>
          </c>
          <c r="C23" s="24">
            <v>{$c23}</v>
          </c>
          <c r="D23" s="24">
            <v>{$d23}</v>
          </c>
          <c r="E23" s="11">
            <f t="shared" si="1"/>
            <v>{$e23}</v>
          </c>
          <c r="F23" s="2"/>
        </row>
        <row r="24" spans="1:6" ht="18" customHeight="1" x14ac:dyDescent="0.2">
          <c r="A24" s="2"/>
          <c r="B24" s="23" t="s">
            <v>18</v>
          </c>
          <c r="C24" s="24">
            <v>{$c24}</v>
          </c>
          <c r="D24" s="24">
            <v>{$d24}</v>
          </c>
          <c r="E24" s="11">
            <f t="shared" si="1"/>
            <v>{$e24}</v>
          </c>
          <c r="F24" s="2"/>
        </row>
        <row r="25" spans="1:6" ht="18" customHeight="1" x14ac:dyDescent="0.2">
          <c r="A25" s="2"/>
          <c r="B25" s="23" t="s">
            <v>19</v>
          </c>
          <c r="C25" s="24">
            <v>{$c25}</v>
          </c>
          <c r="D25" s="24">
            <v>{$d25}</v>
          </c>
          <c r="E25" s="11">
            <f t="shared" si="1"/>
            <v>{$e25}</v>
          </c>
          <c r="F25" s="2"/>
        </row>
        <row r="26" spans="1:6" ht="18" customHeight="1" x14ac:dyDescent="0.2">
          <c r="A26" s="2"/>
          <c r="B26" s="23" t="s">
            <v>20</v>
          </c>
          <c r="C26" s="24">
            <v>{$c26}</v>
          </c>
          <c r="D26" s="24">
            <v>{$d26}</v>
          </c>
          <c r="E26" s="11">
            <f t="shared" si="1"/>
            <v>{$e26}</v>
          </c>
          <c r="F26" s="2"/>
        </row>
        <row r="27" spans="1:6" ht="18" customHeight="1" x14ac:dyDescent="0.2">
          <c r="A27" s="2"/>
          <c r="B27" s="23" t="s">
            <v>21</v>
          </c>
          <c r="C27" s="24">
            <v>{$c27}</v>
          </c>
          <c r="D27" s="24">
            <v>{$d27}</v>
          </c>
          <c r="E27" s="11">
            <f t="shared" si="1"/>
            <v>{$e27}</v>
          </c>
          <c r="F27" s="2"/>
        </row>
        <row r="28" spans="1:6" ht="18" customHeight="1" x14ac:dyDescent="0.2">
          <c r="A28" s="2"/>
          <c r="B28" s="23" t="s">
            <v>22</v>
          </c>
          <c r="C28" s="25">
            <v>{$c28}</v>
          </c>
          <c r="D28" s="24">
            <v>{$d28}</v>
          </c>
          <c r="E28" s="11">
            <f t="shared" si="1"/>
            <v>{$e28}</v>
          </c>
          <c r="F28" s="2"/>
        </row>
        <row r="29" spans="1:6" ht="18" customHeight="1" x14ac:dyDescent="0.2">
          <c r="A29" s="2"/>
          <c r="B29" s="23" t="s">
            <v>23</v>
          </c>
          <c r="C29" s="24">
            <v>{$c29}</v>
          </c>
          <c r="D29" s="24">
            <v>{$d29}</v>
          </c>
          <c r="E29" s="11">
            <f t="shared" si="1"/>
            <v>{$e29}</v>
          </c>
          <c r="F29" s="2"/>
        </row>
        <row r="30" spans="1:6" ht="18" customHeight="1" x14ac:dyDescent="0.2">
          <c r="A30" s="2"/>
          <c r="B30" s="13" t="s">
            <v>38</v>
          </c>
          <c r="C30" s="11">
            <f>IF(SUM(C22:C29)=0,"",SUM(C22:C29))</f>
            <v>{$c30}</v>
          </c>
          <c r="D30" s="11">
            <f>IF(SUM(D22:D29)=0,"",SUM(D22:D29))</f>
            <v>{$d30}</v>
          </c>
          <c r="E30" s="11">
            <f>IF(SUM(E22:E29)=0,"",SUM(E22:E29))</f>
            <v>{$e30}</v>
          </c>
          <c r="F30" s="2"/>
        </row>
        <row r="31" spans="1:6" ht="18" customHeight="1" x14ac:dyDescent="0.2">
          <c r="A31" s="2"/>
          <c r="B31" s="26" t="s">
            <v>24</v>
          </c>
          <c r="C31" s="27">
            <v>{$c31}</v>
          </c>
          <c r="D31" s="15"/>
          <c r="E31" s="16"/>
          <c r="F31" s="2"/>
        </row>
        <row r="32" spans="1:6" ht="18" customHeight="1" x14ac:dyDescent="0.2">
          <c r="A32" s="2"/>
          <c r="B32" s="28" t="s">
            <v>25</v>
          </c>
          <c r="C32" s="29"/>
          <c r="D32" s="16"/>
          <c r="E32" s="17">
            <f>IF(OR(SUM(E30)&gt;0,C31),MAX(E30,C31),"")</f>
            <v>{$e32}</v>
          </c>
          <c r="F32" s="2"/>
        </row>
        <row r="33" spans="1:6" ht="18" customHeight="1" x14ac:dyDescent="0.2">
          <c r="A33" s="2"/>
          <c r="B33" s="23" t="s">
            <v>26</v>
          </c>
          <c r="C33" s="30">
            <v>{$c33}</v>
          </c>
          <c r="D33" s="18"/>
          <c r="E33" s="15"/>
          <c r="F33" s="2"/>
        </row>
        <row r="34" spans="1:6" ht="18" customHeight="1" x14ac:dyDescent="0.2">
          <c r="A34" s="2"/>
          <c r="B34" s="26" t="s">
            <v>27</v>
          </c>
          <c r="C34" s="31">
            <v>5</v>
          </c>
          <c r="D34" s="18"/>
          <c r="E34" s="19">
            <f>IF(AND(C34&gt;0,C33),C34*C33,"")</f>
            <v>{$e34}</v>
          </c>
          <c r="F34" s="2"/>
        </row>
        <row r="35" spans="1:6" ht="18" customHeight="1" x14ac:dyDescent="0.2">
          <c r="A35" s="2"/>
          <c r="B35" s="20" t="s">
            <v>39</v>
          </c>
          <c r="C35" s="16"/>
          <c r="D35" s="18"/>
          <c r="E35" s="17">
            <f>IF(OR(SUM(E32)&gt;0,C33),E32+C33*C34,"")</f>
            <v>{$e35}</v>
          </c>
          <c r="F35" s="2"/>
        </row>
        <row r="36" spans="1:6" ht="18" customHeight="1" x14ac:dyDescent="0.2">
          <c r="A36" s="2"/>
          <c r="B36" s="28" t="s">
            <v>28</v>
          </c>
          <c r="C36" s="16"/>
          <c r="D36" s="18"/>
          <c r="E36" s="17">
            <f>IF(OR(SUM(E19)&gt;0,SUM(E35)),SUM(E19)-SUM(E35),"")</f>
            <v>{$e36}</v>
          </c>
          <c r="F36" s="2"/>
        </row>
        <row r="37" spans="1:6" ht="18" customHeight="1" x14ac:dyDescent="0.2">
          <c r="A37" s="2"/>
          <c r="B37" s="28" t="s">
            <v>29</v>
          </c>
          <c r="C37" s="16"/>
          <c r="D37" s="16"/>
          <c r="E37" s="32">
            <v>{$e37}</v>
          </c>
          <c r="F37" s="2"/>
        </row>
        <row r="38" spans="1:6" ht="18" customHeight="1" x14ac:dyDescent="0.2">
          <c r="A38" s="2"/>
          <c r="B38" s="28" t="s">
            <v>30</v>
          </c>
          <c r="C38" s="16"/>
          <c r="D38" s="16"/>
          <c r="E38" s="30">
            <v>{$e38}</v>
          </c>
          <c r="F38" s="2"/>
        </row>
        <row r="39" spans="1:6" ht="18" customHeight="1" x14ac:dyDescent="0.2">
          <c r="A39" s="2"/>
          <c r="B39" s="28" t="s">
            <v>31</v>
          </c>
          <c r="C39" s="16"/>
          <c r="D39" s="16"/>
          <c r="E39" s="32">
            <v>{$e39}</v>
          </c>
          <c r="F39" s="2"/>
        </row>
      </sheetData>
      <dataConsolidate/>
      <mergeCells count="7">
        <mergeCell ref="B2:B3"/>
        <mergeCell ref="B12:B13"/>
        <mergeCell ref="B20:B21"/>
        <mergeCell ref="C1:D1"/>
        <mergeCell ref="D20:E20"/>
        <mergeCell ref="D12:E12"/>
        <mergeCell ref="D2:E2"/>
      </mergeCells>
      <phoneticPr fontId="0" type="noConversion"/>
      <printOptions horizontalCentered="1"/>
      <pageMargins left="0.65" right="0.65" top="0.65" bottom="0.65" header="0.5" footer="0.5"/>
      <pageSetup scale="94" orientation="portrait" horizontalDpi="300" verticalDpi="300" r:id="rId1"/>
      <headerFooter alignWithMargins="0"/>
      <ignoredErrors>
        <ignoredError sqref="E16:E17 C18:D18 E22:E29 C30:D30 E32 E34:E35 E4:E10 C11:D11 E14:E15"
          emptyCellReference="1"/>
      </ignoredErrors>
    </worksheet>

  let $binDoc :=
    ssheet:generate-simple-xl-ooxml(
      $contentTypes,
      $appDoc,
      $coreDoc,
      $calcChain,
      $sharedStrings,
      $styles,
      $workBook,
      $printerBinDoc,
      $theme,
      $sheet1,
      $sheet1Rels,
      $wkBookRels,
      $relsRels
     )

  return
  (
    (: xdmp:document-insert($fileUri, $binDoc, xdmp:default-permissions(), ("binary")), :)
    $binDoc
  )
};

