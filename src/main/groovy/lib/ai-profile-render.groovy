// Copyright (C) 2026 Imre Tabur <imre.tabur@mail.ee>
// Usage: groovy ai-profile-render.groovy <profile1> [profile2] ...
// Profile format: name or name:cat1,cat2
// Requires JWT_TOKEN environment variable for authentication.
// Variable overrides: ai.sh in current directory (KEY=VALUE)
// Env: AI_KNOWLEDGE_APP_URL (default: http://localhost:8800)

import java.util.regex.Matcher
import java.util.regex.Pattern

def knowledgeAppUrl = System.getenv('AI_KNOWLEDGE_APP_URL') ?: 'http://localhost:8800'
def jwtToken = System.getenv('JWT_TOKEN') ?: ''

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

args.each { profileArg ->
    def parts = profileArg.split(':', 2)
    def profileName = parts[0]
    def categories = parts.length > 1 ? parts[1].split(',').toList() : []

    def content = fetchProfile(profileName, categories)
    if (content) {
        print renderContent(content)
    }
}
