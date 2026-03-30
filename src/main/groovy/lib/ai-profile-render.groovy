// Copyright (C) 2026 Imre Tabur <imre.tabur@mail.ee>
// Usage: groovy ai-profile-render.groovy <profile1> [profile2] ...
// Profile format: name or name:cat1,cat2
// Requires JWT_TOKEN environment variable for authentication.
// Variable overrides: ai.sh in current directory (KEY=VALUE)
// Config: $(smi-etc-location)/ai.conf, $(smi-home-location)/ai.conf (KEY=VALUE)
// Env: AI_KNOWLEDGE_APP_URL overrides config files (default: http://localhost:8800)

import java.util.regex.Matcher
import java.util.regex.Pattern

def vars = new LinkedHashMap<String, String>(System.getenv())

def loadKeyValueFile = { File f ->
    if (f.exists()) {
        f.eachLine { line ->
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
}

def runCommand = { String cmd ->
    try {
        def proc = cmd.execute()
        proc.waitFor()
        return proc.text.trim()
    } catch (Exception e) {
        return ''
    }
}

def etcDir = runCommand('smi-etc-location')
def homeDir = runCommand('smi-home-location')
if (etcDir) loadKeyValueFile(new File("${etcDir}/ai.conf"))
if (homeDir) loadKeyValueFile(new File("${homeDir}/ai.conf"))

def shFile = new File('ai.sh')
loadKeyValueFile(shFile)

// Environment variables override config files
System.getenv().each { k, v -> vars[k] = v }

def knowledgeAppUrl = vars['AI_KNOWLEDGE_APP_URL'] ?: 'http://localhost:8800'
def jwtToken = vars['JWT_TOKEN'] ?: ''

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

def fetchProfile = { String profileName, List<String> categories ->
    def profileEntry
    if (categories) {
        def catsJson = categories.collect { "\"${it}\"" }.join(',')
        profileEntry = "{\"name\":\"${profileName}\",\"categories\":[${catsJson}]}"
    } else {
        profileEntry = "{\"name\":\"${profileName}\"}"
    }
    def requestBody = "{\"ai\":[${profileEntry}]}"

    def url = new URL("${knowledgeAppUrl}/api/ai")
    def connection = url.openConnection() as HttpURLConnection
    connection.setRequestMethod('POST')
    connection.setDoOutput(true)
    connection.setRequestProperty('Content-Type', 'application/json')
    connection.setRequestProperty('Accept', 'text/markdown, */*')
    if (jwtToken) {
        connection.setRequestProperty('Authorization', "Bearer ${jwtToken}")
    }

    connection.outputStream.withWriter('UTF-8') { writer ->
        writer.write(requestBody)
    }

    def responseCode = connection.responseCode
    if (responseCode == 200) {
        return connection.inputStream.getText('UTF-8')
    } else {
        System.err.println("ERROR: Failed to fetch profile '${profileName}': HTTP ${responseCode}")
        return ''
    }
}

if (args.length == 0) {
    System.err.println 'Usage: ai-profile-render <profile1> [profile2] ...'
    System.exit(1)
}

if (!jwtToken) {
    System.err.println 'ERROR: JWT_TOKEN environment variable is not set'
    System.exit(1)
}

def defaultRequested = args.any { it.split(':', 2)[0] == 'default' }

args.each { profileArg ->
    def parts = profileArg.split(':', 2)
    def profileName = parts[0]
    def categories = parts.length > 1 ? parts[1].split(',').toList() : []

    def content = fetchProfile(profileName, categories)
    if (content) {
        print renderContent(content)
    }
}

if (!defaultRequested) {
    def content = fetchProfile('default', [])
    if (content) {
        print renderContent(content)
    }
}
