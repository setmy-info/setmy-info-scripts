#!/usr/bin/env groovy

// chmod +x checkUpdates.groovy
// ./checkUpdates.groovy

/*
latest_gradle=$(curl -s https://gradle.org/releases/ | grep -Po 'gradle-[0-9]+\.[0-9]+(\.[0-9]+)?-bin.zip' | sort -V | tail -1)
echo "New Gradle: $latest_gradle"

latest_mvnd=$(curl -s https://api.github.com/repos/mvndaemon/mvnd/releases/latest | jq -r '.tag_name')
echo "New mvnd: $latest_mvnd"
*/

@Grab('org.yaml:snakeyaml:2.2')
import org.yaml.snakeyaml.Yaml
import groovy.json.JsonSlurper
import java.util.regex.*
import java.net.HttpURLConnection

def yaml = new Yaml()
def config = yaml.load(new File('tools.yaml').text)

config.each { tool, cfg ->
    println "🔍 Kontrollin $tool..."
    try {
        def version = null
        def url = cfg.check_url
        def conn = new URL(url).openConnection()
        conn.setRequestProperty("User-Agent", "curl")
        def data = conn.inputStream.text

        switch (cfg.type) {
            case 'html':
                def matcher = data =~ cfg.pattern
                if (matcher.find()) {
                    version = matcher.group(1)
                }
                break

            case 'json':
                def json = new JsonSlurper().parseText(data)
                version = json[cfg.version_key]
                break

            case 'json_array':
                def jsonArr = new JsonSlurper().parseText(data)
                def item = cfg.filter ? jsonArr.find { it[cfg.filter] } : jsonArr[0]
                version = item[cfg.version_key]
                break

            case 'text':
                version = data.trim()
                break

            default:
                println "❌ Tundmatu tüüp: ${cfg.type}"
        }

        if (version) {
            def dlUrl = cfg.download_template.replace('{version}', version)
            println "✅ Uusim versioon: $version"
            println "📦 Allalaadimise URL: $dlUrl\n"
        } else {
            println "⚠️ Ei suutnud leida versiooni"
        }

    } catch (Exception e) {
        println "❌ Viga töötlusel: ${e.message}\n"
    }
}
