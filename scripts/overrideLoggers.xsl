<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:loggers="http://loggers" >

    <xsl:output method="xml" encoding="UTF-8" indent="yes" xalan:indent-amount="2" xmlns:xalan="http://xml.apache.org/xalan" />

    <xsl:param name="overrides"/>

    <xsl:variable name="logbackXml" select="/"/>

    <xsl:variable name="overridesXml" select="document($overrides)"/>    

    <xsl:template match="configuration">
        <xsl:copy>
            <!-- First, copy everything, and apply the "logger" template. -->
            <xsl:apply-templates select="@*|node()"/>
            <!-- Then, insert new loggers using the "loggers:loggerOverride" template. -->
            <xsl:apply-templates select="$overridesXml//loggers:loggerOverride"/>
        </xsl:copy>
    </xsl:template>

    <!-- Special case for the root logger. -->
    <xsl:template match="root">

        <xsl:variable name="useroverride" select="$overridesXml//loggers:loggerOverride[@name='ROOT']/text()"/>    

        <xsl:choose>
            <xsl:when test="$useroverride" >
                <xsl:message terminate = "no" >Changing root logger from <xsl:value-of select="@level" /> to <xsl:value-of select="$useroverride" /></xsl:message>
                <xsl:copy>
			              <xsl:attribute name="level"><xsl:value-of select="$useroverride" /></xsl:attribute>
                    <xsl:apply-templates select="node()" />
                </xsl:copy>
            </xsl:when>
            <xsl:otherwise>
                <xsl:copy>
                    <xsl:apply-templates select="@*|node()"/>
                </xsl:copy>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- This will match only within the input document. -->
    <xsl:template match="logger">

        <xsl:variable name="loggerName" select="@name"/>

        <xsl:variable name="useroverride" select="$overridesXml//loggers:loggerOverride[@name=$loggerName]/text()"/>    

        <xsl:choose>
            <xsl:when test="$useroverride" >
                <xsl:message terminate = "no" >Changing logger "<xsl:value-of select="$loggerName" />" from <xsl:value-of select="level/@value" /> to <xsl:value-of select="$useroverride" /></xsl:message>
                <xsl:copy>
                    <xsl:apply-templates select="@*|text()" />
			              <level><xsl:attribute name="value"><xsl:value-of select="$useroverride" /></xsl:attribute></level>
                </xsl:copy>
            </xsl:when>
            <xsl:otherwise>
                <xsl:copy>
                    <xsl:apply-templates select="@*|node()"/>
                </xsl:copy>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- This will match only within the overridesXml document. -->
    <xsl:template match="loggers:loggerOverride">

        <xsl:variable name="loggerName" select="@name"/>

        <xsl:variable name="preexisting" select="$logbackXml//logger[@name=$loggerName]"/>    

        <xsl:choose>
            <xsl:when test="$loggerName='ROOT'" >
                <!-- Never add a logger for ROOT. -->
            </xsl:when>
            <xsl:when test="$preexisting" >
                <!-- The override was already applied in the "logger" template. -->
            </xsl:when>
            <xsl:otherwise>
                <xsl:message terminate = "no" >Adding logger "<xsl:value-of select="$loggerName" />" as <xsl:value-of select="text()" /></xsl:message>
                <xsl:element name="logger">
                    <xsl:attribute name="name"><xsl:value-of select="$loggerName" /></xsl:attribute>
			              <xsl:element name="level"><xsl:attribute name="value"><xsl:value-of select="text()" /></xsl:attribute></xsl:element>
                </xsl:element>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="@*|node()">
        <xsl:copy>
            <xsl:apply-templates select="@*|node()"/>
        </xsl:copy>
    </xsl:template>

</xsl:stylesheet>