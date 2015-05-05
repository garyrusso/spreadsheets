xquery version "1.0-ml";

module namespace suggest = "http://marklogic.com/roxy/lib/suggest-lib";

import module namespace search = "http://marklogic.com/appservices/search" at "/MarkLogic/appservices/search/search.xqy";

declare variable $suggest:OPTIONS as element () :=
<search:options xmlns:search="http://marklogic.com/appservices/search">
  <search:quality-weight>0</search:quality-weight>
  <search:search-option>unfiltered</search:search-option>
  <search:page-length>10</search:page-length>
  <search:term apply="term">
    <search:empty apply="all-results"/>
    <search:term-option>punctuation-insensitive</search:term-option>
  </search:term>
  <search:grammar>
    <search:quotation>"</search:quotation>
    <search:implicit>
      <cts:and-query strength="20" xmlns:cts="http://marklogic.com/cts"/>
    </search:implicit>
    <search:starter strength="30" apply="grouping" delimiter=")">(</search:starter>
    <search:starter strength="40" apply="prefix" element="cts:not-query">-</search:starter>
    <search:joiner strength="10" apply="infix" element="cts:or-query" tokenize="word">OR</search:joiner>
    <search:joiner strength="20" apply="infix" element="cts:and-query" tokenize="word">AND</search:joiner>
    <search:joiner strength="30" apply="infix" element="cts:near-query" tokenize="word">NEAR</search:joiner>
    <search:joiner strength="30" apply="near2" consume="2" element="cts:near-query">NEAR/</search:joiner>
    <search:joiner strength="32" apply="boost" element="cts:boost-query" tokenize="word">BOOST</search:joiner>
    <search:joiner strength="35" apply="not-in" element="cts:not-in-query" tokenize="word">NOT_IN</search:joiner>
    <search:joiner strength="50" apply="constraint">:</search:joiner>
    <search:joiner strength="50" apply="constraint" compare="LT" tokenize="word">LT</search:joiner>
    <search:joiner strength="50" apply="constraint" compare="LE" tokenize="word">LE</search:joiner>
    <search:joiner strength="50" apply="constraint" compare="GT" tokenize="word">GT</search:joiner>
    <search:joiner strength="50" apply="constraint" compare="GE" tokenize="word">GE</search:joiner>
    <search:joiner strength="50" apply="constraint" compare="NE" tokenize="word">NE</search:joiner>
  </search:grammar>
  <search:constraint name="averageVariance">
    <search:range type="xs:decimal" facet="true">
      <search:facet-option>frequency-order</search:facet-option>
      <search:facet-option>descending</search:facet-option>
      <search:facet-option>limit=10</search:facet-option>
      <search:element ns="http://tax.thomsonreuters.com" name="averageVariance"/>
    </search:range>
  </search:constraint>
  <search:constraint name="client">
    <search:range collation="http://marklogic.com/collation/" type="xs:string" facet="true">
      <search:facet-option>frequency-order</search:facet-option>
      <search:facet-option>descending</search:facet-option>
      <search:facet-option>limit=10</search:facet-option>
      <search:element ns="http://tax.thomsonreuters.com" name="client"/>
    </search:range>
  </search:constraint>
  <search:constraint name="country">
    <search:range collation="http://marklogic.com/collation/" type="xs:string" facet="true">
      <search:facet-option>frequency-order</search:facet-option>
      <search:facet-option>descending</search:facet-option>
      <search:facet-option>limit=10</search:facet-option>
      <search:element ns="http://tax.thomsonreuters.com" name="country"/>
    </search:range>
  </search:constraint>
  <search:constraint name="filingEntity">
    <search:range collation="http://marklogic.com/collation/" type="xs:string" facet="true">
      <search:facet-option>frequency-order</search:facet-option>
      <search:facet-option>descending</search:facet-option>
      <search:facet-option>limit=10</search:facet-option>
      <search:element ns="http://tax.thomsonreuters.com" name="filingEntity"/>
    </search:range>
  </search:constraint>
  <search:constraint name="fiscalYear">
    <search:range collation="http://marklogic.com/collation/" type="xs:string" facet="true">
      <search:facet-option>frequency-order</search:facet-option>
      <search:facet-option>descending</search:facet-option>
      <search:facet-option>limit=10</search:facet-option>
      <search:element ns="http://tax.thomsonreuters.com" name="fiscalYear"/>
    </search:range>
  </search:constraint>
  <search:constraint name="preTaxBookIncomeVariance">
    <search:range type="xs:decimal" facet="true">
      <search:facet-option>frequency-order</search:facet-option>
      <search:facet-option>descending</search:facet-option>
      <search:facet-option>limit=10</search:facet-option>
      <search:element ns="http://tax.thomsonreuters.com" name="preTaxBookIncomeVariance"/>
    </search:range>
  </search:constraint>
  <search:constraint name="rangeName">
    <search:range collation="http://marklogic.com/collation/" type="xs:string" facet="true">
      <search:facet-option>frequency-order</search:facet-option>
      <search:facet-option>descending</search:facet-option>
      <search:facet-option>limit=10</search:facet-option>
      <search:element ns="http://tax.thomsonreuters.com" name="rangeName"/>
    </search:range>
  </search:constraint>
  <search:constraint name="returnBasisProvisionVariance">
    <search:range type="xs:decimal" facet="true">
      <search:facet-option>frequency-order</search:facet-option>
      <search:facet-option>descending</search:facet-option>
      <search:facet-option>limit=10</search:facet-option>
      <search:element ns="http://tax.thomsonreuters.com" name="returnBasisProvisionVariance"/>
    </search:range>
  </search:constraint>
  <search:constraint name="state">
    <search:range collation="http://marklogic.com/collation/" type="xs:string" facet="true">
      <search:facet-option>frequency-order</search:facet-option>
      <search:facet-option>descending</search:facet-option>
      <search:facet-option>limit=10</search:facet-option>
      <search:element ns="http://tax.thomsonreuters.com" name="state"/>
    </search:range>
  </search:constraint>
  <search:constraint name="type">
    <search:range collation="http://marklogic.com/collation/" type="xs:string" facet="true">
      <search:facet-option>frequency-order</search:facet-option>
      <search:facet-option>descending</search:facet-option>
      <search:facet-option>limit=10</search:facet-option>
      <search:element ns="http://tax.thomsonreuters.com" name="type"/>
    </search:range>
  </search:constraint>
  <search:constraint name="user">
    <search:range collation="http://marklogic.com/collation/" type="xs:string" facet="true">
      <search:facet-option>frequency-order</search:facet-option>
      <search:facet-option>descending</search:facet-option>
      <search:facet-option>limit=10</search:facet-option>
      <search:element ns="http://tax.thomsonreuters.com" name="user"/>
    </search:range>
  </search:constraint>
  <search:operator name="sort">
    <search:state name="relevance">
      <search:sort-order>
	<search:score/>
      </search:sort-order>
    </search:state>
    <search:state name="type">
      <search:sort-order direction="descending" type="xs:string" collation="http://marklogic.com/collation/">
	<search:element ns="http://tax.thomsonreuters.com" name="type"/>
      </search:sort-order>
      <search:sort-order>
	<search:score/>
      </search:sort-order>
    </search:state>
  </search:operator>
  <search:transform-results apply="snippet">
    <search:preferred-elements><search:element ns="http://tax.thomsonreuters.com" name="val"/><search:element ns="http://tax.thomsonreuters.com" name="dtype"/><search:element ns="http://tax.thomsonreuters.com" name="pos"/><search:element ns="http://tax.thomsonreuters.com" name="sheet"/></search:preferred-elements>
    <search:max-matches>2</search:max-matches>
    <search:max-snippet-chars>150</search:max-snippet-chars>
    <search:per-match-tokens>20</search:per-match-tokens>
  </search:transform-results>
  <search:return-query>1</search:return-query>
  <search:operator name="results">
    <search:state name="compact">
      <search:transform-results apply="snippet">
	<search:preferred-elements><search:element ns="http://tax.thomsonreuters.com" name="val"/><search:element ns="http://tax.thomsonreuters.com" name="dtype"/><search:element ns="http://tax.thomsonreuters.com" name="pos"/><search:element ns="http://tax.thomsonreuters.com" name="sheet"/></search:preferred-elements>
	<search:max-matches>2</search:max-matches>
	<search:max-snippet-chars>150</search:max-snippet-chars>
	<search:per-match-tokens>20</search:per-match-tokens>
      </search:transform-results>
    </search:state>
    <search:state name="detailed">
      <search:transform-results apply="snippet">
	<search:preferred-elements><search:element ns="http://tax.thomsonreuters.com" name="val"/><search:element ns="http://tax.thomsonreuters.com" name="dtype"/><search:element ns="http://tax.thomsonreuters.com" name="pos"/><search:element ns="http://tax.thomsonreuters.com" name="sheet"/></search:preferred-elements>
	<search:max-matches>2</search:max-matches>
	<search:max-snippet-chars>400</search:max-snippet-chars>
	<search:per-match-tokens>30</search:per-match-tokens>
      </search:transform-results>
    </search:state>
  </search:operator>
  <search:values name="averageVariance">
    <search:range type="xs:decimal" facet="true">
      <search:element ns="http://tax.thomsonreuters.com" name="averageVariance"/>
    </search:range>
    <search:aggregate apply="min"/>
    <search:aggregate apply="max"/>
  </search:values>
  <search:values name="preTaxBookIncomeVariance">
    <search:range type="xs:decimal" facet="true">
      <search:element ns="http://tax.thomsonreuters.com" name="preTaxBookIncomeVariance"/>
    </search:range>
    <search:aggregate apply="min"/>
    <search:aggregate apply="max"/>
  </search:values>
  <search:values name="returnBasisProvisionVariance">
    <search:range type="xs:decimal" facet="true">
      <search:element ns="http://tax.thomsonreuters.com" name="returnBasisProvisionVariance"/>
    </search:range>
    <search:aggregate apply="min"/>
    <search:aggregate apply="max"/>
  </search:values>
  <search:extract-metadata>
    <search:qname elem-ns="http://tax.thomsonreuters.com" elem-name="type"/>
    <search:qname elem-ns="http://tax.thomsonreuters.com" elem-name="client"/>
    <search:qname elem-ns="http://tax.thomsonreuters.com" elem-name="state"/>
    <search:qname elem-ns="http://tax.thomsonreuters.com" elem-name="country"/>
    <search:qname elem-ns="http://tax.thomsonreuters.com" elem-name="filingEntity"/>
    <search:qname elem-ns="http://tax.thomsonreuters.com" elem-name="fiscalYear"/>
    <search:qname elem-ns="http://tax.thomsonreuters.com" elem-name="rangeName"/>
    <search:qname elem-ns="http://tax.thomsonreuters.com" elem-name="rangeLabel"/>
    <search:qname elem-ns="http://tax.thomsonreuters.com" elem-name="user"/>
    <search:qname elem-ns="http://tax.thomsonreuters.com" elem-name="rowLabel"/>
    <search:qname elem-ns="http://tax.thomsonreuters.com" elem-name="columnLabel"/>
    <search:qname elem-ns="http://tax.thomsonreuters.com" elem-name="taxBracket"/>
    <search:qname elem-ns="http://tax.thomsonreuters.com" elem-name="deductionPct"/>
    <search:qname elem-ns="http://tax.thomsonreuters.com" elem-name="totalGrossInc"/>
    <search:qname elem-ns="http://tax.thomsonreuters.com" elem-name="taxableInc"/>
    <search:qname elem-ns="http://tax.thomsonreuters.com" elem-name="averageVariance"/>
    <search:qname elem-ns="http://tax.thomsonreuters.com" elem-name="preTaxBookIncomeVariance"/>
    <search:qname elem-ns="http://tax.thomsonreuters.com" elem-name="returnBasisProvisionVariance"/>
    <search:qname elem-ns="http://tax.thomsonreuters.com" elem-name="taxableIncomeVariance"/>
    <search:qname elem-ns="http://tax.thomsonreuters.com" elem-name="fileName"/>
    <search:constraint-value ref="averageVariance"/>
    <search:constraint-value ref="client"/>
    <search:constraint-value ref="country"/>
    <search:constraint-value ref="filingEntity"/>
    <search:constraint-value ref="fiscalYear"/>
    <search:constraint-value ref="preTaxBookIncomeVariance"/>
    <search:constraint-value ref="rangeName"/>
    <search:constraint-value ref="returnBasisProvisionVariance"/>
    <search:constraint-value ref="state"/>
    <search:constraint-value ref="type"/>
    <search:constraint-value ref="user"/>
  </search:extract-metadata>
  <annotation xmlns="http://marklogic.com/appservices/search">Delta options here</annotation>
</search:options>;

declare function suggest:getSuggestions($pqtxt as xs:string)
{
  let $results := search:suggest($pqtxt, $suggest:OPTIONS)

  return
    json:to-array($results)
};

