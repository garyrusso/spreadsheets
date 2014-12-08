<xsl:stylesheet version="2.0" exclude-result-prefixes="html"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns="http://www.w3.org/1999/xhtml"
  xmlns:xdmp="http://marklogic.com/xdmp"
  xmlns:html="http://www.w3.org/1999/xhtml"
  xmlns:_1="http://tax.thomsonreuters.com">
  <xsl:output omit-xml-declaration="yes" indent="yes"/>
  
  <xsl:template match="/">
    <html>
      <body style="font-family:Calibri, Arial, Helvetica, sans-serif; font-size:16px;">
        <xsl:apply-templates/> 
      </body>
    </html>
  </xsl:template>
  
  <xsl:template match="_1:workbook">
    <xsl:variable name="uri" select="xdmp:node-uri(.)"/>
    <p>
      <table border="1" width="100%">
        <tr bgcolor="#A4B7BB">
          <th colspan="2" align="left" width="100%">
            <table width="100%" border="0">
              <tr>
                <td align="left">Workpaper Spreadsheet Data</td>
                <td align="right">
                  <a><xsl:attribute name='href' select='concat("../application/custom/get-db-file.xqy?uri=", $uri)'/>[Source XML]</a>
                </td>
              </tr>
            </table>
          </th>
        </tr>
        <tr>
          <td bgcolor="#E8ECED" valign="top">Document URI</td>
          <td><xsl:value-of select="$uri"/></td>
        </tr>
        <tr>
          <td width="15%" bgcolor="#E8ECED" valign="top">User</td>
          <td width="85%"><xsl:value-of select="_1:meta/_1:user"/></td>
        </tr>
        <tr>
          <td width="15%" bgcolor="#E8ECED" valign="top">Type</td>
          <td width="85%"><xsl:value-of select="_1:meta/_1:type"/></td>
        </tr>
        <tr>
          <td width="15%" bgcolor="#E8ECED" valign="top">Client</td>
          <td width="85%"><xsl:value-of select="_1:meta/_1:client"/></td>
        </tr>
        <tr>
          <td width="15%" bgcolor="#E8ECED" valign="top">File</td>
          <td width="85%"><xsl:value-of select="_1:meta/_1:file"/></td>
        </tr>
        <tr>
          <td width="15%" bgcolor="#E8ECED" valign="top">lastModifiedBy</td>
          <td width="85%"><xsl:value-of select="_1:meta/_1:lastModifiedBy"/></td>
        </tr>
        <tr>
          <td width="15%" bgcolor="#E8ECED" valign="top">Created</td>
          <td width="85%"><xsl:value-of select="_1:meta/_1:created"/></td>
        </tr>
        <tr>
          <td width="15%" bgcolor="#E8ECED" valign="top">Modified</td>
          <td width="85%"><xsl:value-of select="_1:meta/_1:modified"/></td>
        </tr>
        <tr>
          <td bgcolor="#E8ECED" valign="top">Named Fields</td>
          <td>
            <table border="1" width="100%">
              <xsl:for-each select="_1:feed/_1:definedNames/_1:definedName">
                <tr>
                  <td>
                    <table border="1" width="100%">
                      <tr>
                        <td width="20%" bgcolor="#E8ECED" valign="top">Name</td>
                        <td width="80%"><xsl:value-of select="_1:dname"/></td>
                      </tr>
                      <tr>
                        <td width="20%" bgcolor="#E8ECED" valign="top">Row Label</td>
                        <td width="80%"><xsl:value-of select="_1:rowLabel"/></td>
                      </tr>
                      <tr>
                        <td width="20%" bgcolor="#E8ECED" valign="top">Column Label</td>
                        <td width="80%"><xsl:value-of select="_1:columnLabel"/></td>
                      </tr>
                      <tr>
                        <td width="20%" bgcolor="#E8ECED" valign="top">Defined Value</td>
                        <td width="80%"><xsl:value-of select="_1:dvalue"/></td>
                      </tr>
                      <tr>
                        <td width="20%" bgcolor="#E8ECED" valign="top">Worksheet</td>
                        <td width="80%"><xsl:value-of select="_1:sheet"/></td>
                      </tr>
                      <tr>
                        <td width="20%" bgcolor="#E8ECED" valign="top">Cell Position</td>
                        <td width="80%"><xsl:value-of select="_1:pos"/></td>
                      </tr>
                      <tr>
                        <td width="20%" bgcolor="#E8ECED" valign="top">Cell Row</td>
                        <td width="80%"><xsl:value-of select="_1:row"/></td>
                      </tr>
                      <tr>
                        <td width="20%" bgcolor="#E8ECED" valign="top">Cell Column</td>
                        <td width="80%"><xsl:value-of select="_1:col"/></td>
                      </tr>
                    </table>
                  </td>
                </tr>
              </xsl:for-each>
            </table>
          </td>
        </tr>
        <tr>
          <td bgcolor="#E8ECED" valign="top">Worksheets</td>
          <td>
            <table border="1" width="100%">
              <xsl:for-each select="_1:feed/_1:worksheets/_1:worksheet">
                <tr>
                  <td>
                    <table border="1" width="100%">
                      <tr>
                        <td width="20%" bgcolor="#E8ECED" valign="top">Name</td>
                        <td width="80%"><xsl:value-of select="_1:name"/></td>
                      </tr>
                      <tr>
                        <td width="20%" bgcolor="#E8ECED" valign="top">Key</td>
                        <td width="80%"><xsl:value-of select="_1:key"/></td>
                      </tr>
                      <tr>
                        <td width="20%" bgcolor="#E8ECED" valign="top">Dimension Top Left</td>
                        <td width="80%"><xsl:value-of select="_1:dimension/_1:topLeft"/></td>
                      </tr>
                      <tr>
                        <td width="20%" bgcolor="#E8ECED" valign="top">Dimension Bottom Right</td>
                        <td width="80%"><xsl:value-of select="_1:dimension/_1:bottomRight"/></td>
                      </tr>
                      <tr>
                        <td width="20%" bgcolor="#E8ECED" valign="top">Sheet Data</td>
                        <td>
                          <table border="1" width="100%">
                            <xsl:for-each select="_1:sheetData/_1:cell">
                              <tr>
                                <td>
                                  <table border="1" width="100%">
                                    <tr>
                                      <td width="20%" bgcolor="#E8ECED" valign="top">Position</td>
                                      <td width="80%"><xsl:value-of select="_1:pos"/></td>
                                    </tr>
                                    <tr>
                                      <td width="20%" bgcolor="#E8ECED" valign="top">Value</td>
                                      <td width="80%"><xsl:value-of select="_1:val"/></td>
                                    </tr>
                                    <tr>
                                      <td width="20%" bgcolor="#E8ECED" valign="top">Type</td>
                                      <td width="80%"><xsl:value-of select="_1:type"/></td>
                                    </tr>
                                    <tr>
                                      <td width="20%" bgcolor="#E8ECED" valign="top">Column</td>
                                      <td width="80%"><xsl:value-of select="_1:col"/></td>
                                    </tr>
                                    <tr>
                                      <td width="20%" bgcolor="#E8ECED" valign="top">Row</td>
                                      <td width="80%"><xsl:value-of select="_1:row"/></td>
                                    </tr>
                                  </table>
                                </td>
                              </tr>
                            </xsl:for-each>
                          </table>
                        </td>
                      </tr>
                    </table>
                  </td>
                </tr>
              </xsl:for-each>
            </table>
          </td>
        </tr>
      </table>
    </p>
  </xsl:template>

  <xsl:template match="html:*">
    <xsl:copy><xsl:copy-of select="@*"/><xsl:apply-templates/></xsl:copy>
  </xsl:template>
  
</xsl:stylesheet>
