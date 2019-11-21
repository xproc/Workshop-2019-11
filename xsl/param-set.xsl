<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:foo="http://acme.com/foo"
  xmlns:xpu="http://xproc.org/ns/util"
  xmlns:c="http://www.w3.org/ns/xproc-step"
  xmlns:map="http://www.w3.org/2005/xpath-functions/map"
  version="3.0">
  
  <!-- invocation: saxon.sh -it -xsl:param-set.xsl -->
  
  <xsl:template name="xsl:initial-template">
    <xsl:result-document indent="true" omit-xml-declaration="false">
      <xsl:sequence select="xpu:param-set($param1)"/>  
    </xsl:result-document>
  </xsl:template>

  <xsl:variable name="doc" as="document-node()">
    <xsl:document>
      <doc attribute="value"/>
    </xsl:document>
  </xsl:variable>
  
  <xsl:variable name="param1" as="map(xs:QName, item()*)" 
    select="map{xs:QName('num'): 43.0,
                xs:QName('xs:name'): 'foo', 
                xs:QName('foo:test'): ($doc, 'f'), 
                xs:QName('foo:test0'): ([45.7, 'g', true()], [-2, 4.3]), 
                xs:QName('foo:test1'): [45.7, 'g', true()], 
                xs:QName('foo:test2'): ($doc, $doc/*), 
                xs:QName('foo:test3'): [[45.7, 'g', true()], [-2, 4.3]], 
                xs:QName('foo:test4'): (([45.7, 'g', true()]), ([-2, 4.3])), 
                xs:QName('bar'): map{'baz': ['a', 1]},
                xs:QName('third'): ($doc, $doc/*/@*)}"/>
  
  <xsl:function name="xpu:param-set" as="document-node(element(c:param-set))">
    <xsl:param name="_map" as="map(xs:QName, item()*)"/>
    <xsl:document>
      <c:param-set>
        <xsl:for-each select="map:keys($_map)">
          <xsl:sort select="xs:string(.)"/>
          <c:param name="{.}">
            <xsl:choose>
              <xsl:when test="$_map(.) instance of xs:anyAtomicType">
                <xsl:attribute name="value" select="$_map(.)"/>
              </xsl:when>
              <xsl:when test="$_map(.) instance of node()+">
                <xsl:choose>
                  <xsl:when test="exists($_map(.)/self::attribute())">
                    <xsl:sequence select="xpu:adaptive($_map(.))"/>
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:attribute name="method" select="'xml'"/>
                    <xsl:sequence select="$_map(.)"/>    
                  </xsl:otherwise>
                </xsl:choose>
              </xsl:when>
              <xsl:when test="$_map(.) instance of map(*)+
                              or
                              $_map(.) instance of array(*)+">
                <xsl:try>
                  <xsl:attribute name="method" select="'json-to-xml'"/>
                  <xsl:for-each select="$_map(.)">
                    <xsl:sequence select="json-to-xml(serialize(., map{'method': 'json'}))"/>  
                  </xsl:for-each>
                  <xsl:catch>
                    <xsl:sequence select="xpu:adaptive($_map(.))"/>
                  </xsl:catch>
                </xsl:try>
              </xsl:when>
              <xsl:otherwise>
                <xsl:sequence select="xpu:adaptive($_map(.))"/>
              </xsl:otherwise>
            </xsl:choose>
          </c:param>
        </xsl:for-each>
      </c:param-set>
    </xsl:document>
  </xsl:function>
  
  <xsl:function name="xpu:adaptive">
    <xsl:param name="arg" as="item()*"/>
    <xsl:attribute name="method" select="'adaptive'"/>
    <!-- this will not be reversible when casting a c:param-set from application/xml to text/json --> 
    <xsl:attribute name="value" select="serialize($arg, map{'method': 'adaptive'})"/>
  </xsl:function>
  
</xsl:stylesheet>