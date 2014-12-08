import module namespace search="http://marklogic.com/appservices/search" at "/MarkLogic/appservices/search/search.xqy";

let $options :=
  <options xmlns="http://marklogic.com/appservices/search">
    <search-option>unfiltered</search-option>
    <term>
      <term-option>case-insensitive</term-option>
    </term>
    <constraint name="dnames">
      <range type="xs:string">
        <element ns="http://tax.thomsonreuters.com" name="dname"/>
        <facet-option>descending</facet-option>
        <facet-option>limit=10</facet-option>
      </range>
    </constraint>
    <constraint name="dname">
      <word>
        <element ns="http://tax.thomsonreuters.com" name="dname"/>
      </word>
    </constraint>
    <constraint name="type">
      <word>
        <element ns="http://tax.thomsonreuters.com" name="type"/>
      </word>
    </constraint>
    <transform-results apply="metadata-snippet">
      <preferred-elements>
        <element ns="http://tax.thomsonreuters.com" name="dname"/>
        <element ns="http://tax.thomsonreuters.com" name="type"/>
      </preferred-elements>
    </transform-results>
    <operator name="results">
      <state name="compact">
        <transform-results apply="metadata-snippet">
          <preferred-elements>
            <element ns="http://tax.thomsonreuters.com" name="dname"/>
            <element ns="http://tax.thomsonreuters.com" name="type"/>
          </preferred-elements>
          <per-match-tokens>30</per-match-tokens>
          <max-matches>4</max-matches>
          <max-snippet-chars>200</max-snippet-chars>
        </transform-results>
      </state>
      <state name="detailed">
        <transform-results apply="metadata-snippet">
          <preferred-elements>
            <element ns="http://tax.thomsonreuters.com" name="dname"/>
            <element ns="http://tax.thomsonreuters.com" name="type"/>
          </preferred-elements>
          <per-match-tokens>30</per-match-tokens>
          <max-matches>4</max-matches>
          <max-snippet-chars>200</max-snippet-chars>
        </transform-results>
      </state>
    </operator>
    <return-results>true</return-results>
    <return-query>true</return-query>
  </options>

let $query := "dname:AMOUNT"

return
  search:search($query, $options, 1, 10)

