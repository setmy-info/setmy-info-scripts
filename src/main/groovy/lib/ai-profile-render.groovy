// Copyright (C) 2026 Imre Tabur <imre.tabur@mail.ee>
// Usage: groovy ai-profile-render.groovy <profile1> [profile2] ...
// Variable overrides: ai.properties in current directory (KEY=VALUE)

import java.util.regex.Matcher
import java.util.regex.Pattern

def smiLibDir         = System.getenv('SMI_LIB_DIR') ?: 'C:\\pub\\setmy.info\\lib'
def systemProfilesDir = new File("${smiLibDir}${File.separator}ai")
def homeDir           = System.getenv('USERPROFILE') ?: System.getenv('HOME') ?: '.'
def homeProfilesDir   = new File("${homeDir}${File.separator}.setmy.info${File.separator}ai")

def vars = new LinkedHashMap<String, String>(System.getenv())

def propsFile = new File('ai.properties')
if (propsFile.exists()) {
    def props = new Properties()
    propsFile.withInputStream { props.load(it) }
    props.each { k, v -> vars[k as String] = v as String }
}

def defaultPattern = Pattern.compile(/\$\{([A-Za-z_][A-Za-z0-9_]*):-([^}]*)\}/)
def simplePattern  = Pattern.compile(/\$\{([A-Za-z_][A-Za-z0-9_]*)\}/)

def renderContent = { String content ->
    def m = defaultPattern.matcher(content)
    def sb = new StringBuffer()
    while (m.find()) {
        def val = (vars.containsKey(m.group(1)) && vars[m.group(1)]) ? vars[m.group(1)] : m.group(2)
        m.appendReplacement(sb, Matcher.quoteReplacement(val as String))
    }
    m.appendTail(sb)
    content = sb.toString()

    m = simplePattern.matcher(content)
    sb = new StringBuffer()
    while (m.find()) {
        def val = vars.containsKey(m.group(1)) ? vars[m.group(1)] : m.group(0)
        m.appendReplacement(sb, Matcher.quoteReplacement(val as String))
    }
    m.appendTail(sb)
    return sb.toString()
}

if (args.length == 0) {
    System.err.println 'Usage: ai-profile-render <profile1> [profile2] ...'
    System.exit(1)
}

args.each { profileName ->
    def homeFile   = new File(homeProfilesDir, "${profileName}.md")
    def systemFile = new File(systemProfilesDir, "${profileName}.md")
    def file = homeFile.exists() ? homeFile : systemFile
    if (file.exists()) {
        print renderContent(file.text)
    } else {
        System.err.println "Profile not found: ${profileName}"
    }
}
