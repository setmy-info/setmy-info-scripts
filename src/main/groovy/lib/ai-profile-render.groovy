// Copyright (C) 2026 Imre Tabur <imre.tabur@mail.ee>
// Usage: groovy ai-profile-render.groovy <profile1> [profile2] ...
// Variable overrides: ai.sh in current directory (KEY=VALUE)

import java.util.regex.Matcher
import java.util.regex.Pattern

def smiLibDir         = System.getenv('SMI_LIB_DIR') ?: 'C:\\pub\\setmy.info\\lib'
def systemProfilesDir = new File("${smiLibDir}${File.separator}ai")
def homeDir           = System.getenv('USERPROFILE') ?: System.getenv('HOME') ?: '.'
def homeProfilesDir   = new File("${homeDir}${File.separator}.setmy.info${File.separator}ai")

def vars = new LinkedHashMap<String, String>(System.getenv())

def shFile = new File('ai.sh')
if (shFile.exists()) {
    shFile.eachLine { line ->
        def trimmed = line.trim()
        if (trimmed && !trimmed.startsWith('#')) {
            def assignment = trimmed.replaceFirst(/^export\s+/, '')
            def eq = assignment.indexOf('=')
            if (eq > 0) {
                def key = assignment.substring(0, eq).trim()
                def val = assignment.substring(eq + 1).trim().replaceAll(/^(['"])(.*)\1$/, '$2')
                vars[key] = val
            }
        }
    }
}

def varPattern = Pattern.compile(/\$\{([A-Za-z_][A-Za-z0-9_]*)\}/)

def renderContent = { String content ->
    def m = varPattern.matcher(content)
    def sb = new StringBuffer()
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
    def found = false
    if (homeFile.exists()) {
        print renderContent(homeFile.text)
        found = true
    }
    if (systemFile.exists()) {
        print renderContent(systemFile.text)
        found = true
    }
}
