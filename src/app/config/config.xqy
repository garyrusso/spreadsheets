(:
Copyright 2012 MarkLogic Corporation

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
:)
xquery version "1.0-ml";

module namespace c = "http://marklogic.com/roxy/config";

import module namespace def  = "http://marklogic.com/roxy/defaults" at "/roxy/config/defaults.xqy";
import module namespace olib = "http://marklogic.com/roxy/lib/origin-lib" at "/app/lib/origin-lib.xqy";

declare namespace rest = "http://marklogic.com/appservices/rest";

(:
 : ***********************************************
 : Overrides for the Default Roxy control options
 :
 : See /roxy/config/defaults.xqy for the complete list of stuff that you can override.
 : Roxy will check this file (config.xqy) first. If no overrides are provided then it will use the defaults.
 :
 : Go to https://github.com/marklogic/roxy/wiki/Overriding-Roxy-Options for more details
 :
 : ***********************************************
 :)
declare variable $c:ROXY-OPTIONS :=
  <options>
    <layouts>
      <layout format="html">two-column</layout>
    </layouts>
  </options>;

(:
 : ***********************************************
 : Overrides for the Default Roxy scheme
 :
 : See /roxy/config/defaults.xqy for the default routes
 : Roxy will check this file (config.xqy) first. If no overrides are provided then it will use the defaults.
 :
 : Go to https://github.com/marklogic/roxy/wiki/Roxy-URL-Rewriting for more details
 :
 : ***********************************************
 :)
declare variable $c:ROXY-ROUTES :=
  <routes xmlns="http://marklogic.com/appservices/rest">
    <request uri="^/my/awesome/route" />
    {
      $def:ROXY-ROUTES/rest:request
    }
  </routes>;

(:
 : ***********************************************
 : A decent place to put your appservices search config
 : and various other search options.
 : The examples below are used by the appbuilder style
 : default application.
 : ***********************************************
 :)
declare variable $c:DEFAULT-PAGE-LENGTH as xs:int := 10;

declare variable $c:REST-SEARCH-OPTIONS :=
  <options xmlns="http://marklogic.com/appservices/search">
    <search-option>unfiltered</search-option>
    <term>
      <term-option>case-insensitive</term-option>
    </term>
    <constraint name="ImportedUnitCodes">
      <range type="xs:string">
        <bucket ge="RU01501" name="RU-1500s">RU-1500s</bucket>
        <bucket lt="RU01501" ge="RU01001" name="RU-1000s">RU-1000s</bucket>
        <bucket lt="RU01001" ge="RU00501" name="RU-500s">RU-500s</bucket>
        <bucket lt="RU00501" name="RU-0s">RU-0s</bucket>
        <element ns="http://tax.thomsonreuters.com" name="importedUnitCode"/>
        <facet-option>descending</facet-option>
        <facet-option>limit=10</facet-option>
      </range>
    </constraint>
    <constraint name="ImportedAccountCodes">
      <range type="xs:string">
        <bucket ge="AC01501" name="AC-1500s">AC-1500s</bucket>
        <bucket lt="AC01501" ge="AC01001" name="AC-1000s">AC-1000s</bucket>
        <bucket lt="AC01001" ge="AC00501" name="AC-500s">AC-500s</bucket>
        <bucket lt="AC00501" name="AC-0s">AC-0s</bucket>
        <element ns="http://tax.thomsonreuters.com" name="importedAccountCode"/>
        <facet-option>descending</facet-option>
        <facet-option>limit=10</facet-option>
      </range>
    </constraint>
    <constraint name="EndingBalances">
      <range type="xs:float">
        <bucket ge="9000" name="9000s">9000s</bucket>
        <bucket lt="9000" ge="8000" name="8000s">8000s</bucket>
        <bucket lt="8000" ge="7000" name="7000s">7000s</bucket>
        <bucket lt="7000" ge="6000" name="6000s">6000s</bucket>
        <bucket lt="6000" ge="5000" name="5000s">5000s</bucket>
        <bucket lt="5000" ge="4000" name="4000s">4000s</bucket>
        <bucket lt="4000" ge="3000" name="3000s">3000s</bucket>
        <bucket lt="3000" ge="2000" name="2000s">2000s</bucket>
        <bucket lt="1000" name="1000s">1000s</bucket>
        <element ns="http://tax.thomsonreuters.com" name="endingBalance"/>
        <facet-option>descending</facet-option>
        <facet-option>limit=10</facet-option>
      </range>
    </constraint>
    <constraint name="types">
      <range type="xs:string">
        <element ns="http://tax.thomsonreuters.com" name="type"/>
        <facet-option>descending</facet-option>
        <facet-option>limit=10</facet-option>
      </range>
    </constraint>
    <constraint name="users">
      <range type="xs:string">
        <element ns="http://tax.thomsonreuters.com" name="user"/>
        <facet-option>descending</facet-option>
        <facet-option>limit=10</facet-option>
      </range>
    </constraint>
    <constraint name="dnames">
      <range type="xs:string">
        <element ns="http://tax.thomsonreuters.com" name="dname"/>
        <facet-option>descending</facet-option>
        <facet-option>limit=10</facet-option>
      </range>
    </constraint>
    <constraint name="id">
      <word>
        <element ns="http://tax.thomsonreuters.com" name="id"/>
      </word>
    </constraint>
    <constraint name="importedUnitCode">
      <word>
        <element ns="http://tax.thomsonreuters.com" name="importedUnitCode"/>
      </word>
    </constraint>
    <constraint name="importedAccountCode">
      <word>
        <element ns="http://tax.thomsonreuters.com" name="importedAccountCode"/>
      </word>
    </constraint>
    <constraint name="beginningBalance">
      <word>
        <element ns="http://tax.thomsonreuters.com" name="beginningBalance"/>
      </word>
    </constraint>
    <constraint name="endingBalance">
      <word>
        <element ns="http://tax.thomsonreuters.com" name="endingBalance"/>
      </word>
    </constraint>
    <constraint name="type">
      <word>
        <element ns="http://tax.thomsonreuters.com" name="type"/>
      </word>
    </constraint>
    <constraint name="user">
      <word>
        <element ns="http://tax.thomsonreuters.com" name="user"/>
      </word>
    </constraint>
    <constraint name="dname">
      <word>
        <element ns="http://tax.thomsonreuters.com" name="dname"/>
      </word>
    </constraint>
    <constraint name="dvalue">
      <word>
        <element ns="http://tax.thomsonreuters.com" name="dvalue"/>
      </word>
    </constraint>
    <transform-results ns="http://marklogic.com/roxy/lib/origin-lib" apply="rest-origin-snippet" at="/app/lib/origin-lib.xqy">
      <preferred-elements>
        <element ns="http://tax.thomsonreuters.com" name="type"/>
        <element ns="http://tax.thomsonreuters.com" name="id"/>
        <element ns="http://tax.thomsonreuters.com" name="importFileId"/>
        <element ns="http://tax.thomsonreuters.com" name="importedUnitCode"/>
        <element ns="http://tax.thomsonreuters.com" name="importedAccountCode"/>
        <element ns="http://tax.thomsonreuters.com" name="beginningBalance"/>
        <element ns="http://tax.thomsonreuters.com" name="endingBalance"/>
      </preferred-elements>
    </transform-results>
    <return-results>true</return-results>
    <return-query>true</return-query>
  </options>;

declare variable $c:SEARCH-OPTIONS :=
  <options xmlns="http://marklogic.com/appservices/search">
    <search-option>unfiltered</search-option>
    <term>
      <term-option>case-insensitive</term-option>
    </term>
    <additional-query>{cts:and-query(cts:collection-query(("RESTful", "customer", "order", "origin", "spreadsheet")))}</additional-query>
    <constraint name="types">
      <range type="xs:string">
        <element ns="http://tax.thomsonreuters.com" name="type"/>
        <facet-option>descending</facet-option>
        <facet-option>limit=10</facet-option>
      </range>
    </constraint>
    <constraint name="users">
      <range type="xs:string">
        <element ns="http://tax.thomsonreuters.com" name="user"/>
        <facet-option>descending</facet-option>
        <facet-option>limit=10</facet-option>
      </range>
    </constraint>
    <constraint name="dnames">
      <range type="xs:string">
        <element ns="http://tax.thomsonreuters.com" name="dname"/>
        <facet-option>descending</facet-option>
        <facet-option>limit=20</facet-option>
      </range>
    </constraint>
    <constraint name="id">
      <word>
        <element ns="http://tax.thomsonreuters.com" name="id"/>
      </word>
    </constraint>
    <constraint name="type">
      <word>
        <element ns="http://tax.thomsonreuters.com" name="type"/>
      </word>
    </constraint>
    <constraint name="user">
      <word>
        <element ns="http://tax.thomsonreuters.com" name="user"/>
      </word>
    </constraint>
    <constraint name="dname">
      <word>
        <element ns="http://tax.thomsonreuters.com" name="dname"/>
      </word>
    </constraint>
    <constraint name="dvalue">
      <word>
        <element ns="http://tax.thomsonreuters.com" name="dvalue"/>
      </word>
    </constraint>
    <transform-results apply="snippet">
      <preferred-elements>
        <element ns="http://tax.thomsonreuters.com" name="type"/>
        <element ns="http://tax.thomsonreuters.com" name="user"/>
        <element ns="http://tax.thomsonreuters.com" name="rowLabel"/>
        <element ns="http://tax.thomsonreuters.com" name="columnLabel"/>
        <element ns="http://tax.thomsonreuters.com" name="dname"/>
      </preferred-elements>
    </transform-results>
    <operator name="results">
      <state name="compact">
        <transform-results apply="metadata-snippet">
          <preferred-elements>
            <element ns="http://tax.thomsonreuters.com" name="type"/>
            <element ns="http://tax.thomsonreuters.com" name="id"/>
            <element ns="http://tax.thomsonreuters.com" name="importFileId"/>
            <element ns="http://tax.thomsonreuters.com" name="importedUnitCode"/>
            <element ns="http://tax.thomsonreuters.com" name="importedAccountCode"/>
            <element ns="http://tax.thomsonreuters.com" name="beginningBalance"/>
            <element ns="http://tax.thomsonreuters.com" name="endingBalance"/>
            <element ns="http://tax.thomsonreuters.com" name="user"/>
            <element ns="http://tax.thomsonreuters.com" name="rowLabel"/>
            <element ns="http://tax.thomsonreuters.com" name="columnLabel"/>
            <element ns="http://tax.thomsonreuters.com" name="dname"/>
          </preferred-elements>
          <per-match-tokens>30</per-match-tokens>
          <max-matches>4</max-matches>
          <max-snippet-chars>200</max-snippet-chars>
        </transform-results>
      </state>
      <state name="detailed">
        <transform-results apply="metadata-snippet">
          <preferred-elements>
            <element ns="http://tax.thomsonreuters.com" name="type"/>
            <element ns="http://tax.thomsonreuters.com" name="id"/>
            <element ns="http://tax.thomsonreuters.com" name="importFileId"/>
            <element ns="http://tax.thomsonreuters.com" name="importedUnitCode"/>
            <element ns="http://tax.thomsonreuters.com" name="importedAccountCode"/>
            <element ns="http://tax.thomsonreuters.com" name="beginningBalance"/>
            <element ns="http://tax.thomsonreuters.com" name="endingBalance"/>
            <element ns="http://tax.thomsonreuters.com" name="user"/>
            <element ns="http://tax.thomsonreuters.com" name="rowLabel"/>
            <element ns="http://tax.thomsonreuters.com" name="columnLabel"/>
            <element ns="http://tax.thomsonreuters.com" name="dname"/>
          </preferred-elements>
          <per-match-tokens>30</per-match-tokens>
          <max-matches>4</max-matches>
          <max-snippet-chars>200</max-snippet-chars>
        </transform-results>
      </state>
    </operator>
    <return-results>true</return-results>
    <return-query>true</return-query>
  </options>;

(:
 : Labels are used by appbuilder faceting code to provide internationalization
 :)
declare variable $c:LABELS :=
  <labels xmlns="http://marklogic.com/xqutils/labels">
    <label key="importedUnitCode">
      <value xml:lang="en">Imported Unit Code</value>
    </label>
    <label key="importedAccountCode">
      <value xml:lang="en">Imported Account Code</value>
    </label>
    <label key="endingBalances">
      <value xml:lang="en">Ending Balances</value>
    </label>
    <label key="types">
      <value xml:lang="en">Types</value>
    </label>
  </labels>;
