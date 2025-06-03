#!/usr/bin/env groovy
import org.openqa.selenium.By
import org.openqa.selenium.WebDriver
import org.openqa.selenium.firefox.FirefoxDriver
import org.openqa.selenium.firefox.FirefoxOptions
import picocli.CommandLine
import picocli.CommandLine.Option

import java.lang.System

@Grab(group = 'org.seleniumhq.selenium', module = 'selenium-api', version = '4.33.0')
@Grab(group = 'org.seleniumhq.selenium', module = 'selenium-http', version = '4.33.0')
@Grab(group = 'org.seleniumhq.selenium', module = 'selenium-support', version = '4.33.0')
@Grab(group = 'org.seleniumhq.selenium', module = 'selenium-firefox-driver', version = '4.33.0')
@Grab(group = 'org.yaml', module = 'snakeyaml', version = '2.4')
@Grab(group = 'com.google.errorprone', module = 'error_prone_annotations', version = '2.38.0')
@Grab(group = 'info.picocli', module = 'picocli', version = '4.7.7')
//@Grab(group = 'org.seleniumhq.selenium', module = 'selenium-java', version = '4.33.0')
/*
https://search.maven.org/solrsearch/select?q=g:org.apache.maven+AND+a:maven&core=gav&rows=20&wt=json
https://search.maven.org/solrsearch/select?q=g:org.apache.maven+AND+a:maven&core=gav&rows=1&wt=json&sort=version+desc
LAst added artifacts: https://search.maven.org/solrsearch/select?q=*:*&rows=10&wt=json&sort=timestamp+desc
curl -s 'https://search.maven.org/solrsearch/select?q=g:org.apache.maven+AND+a:maven&rows=20&wt=json' | jq '.response.docs[].v'
https://search.maven.org/solrsearch/select
curl 'https://search.maven.org/solrsearch/select?q=g:org.apache.maven&a:maven&rows=100&wt=json'
curl 'https://search.maven.org/solrsearch/select?q=g:org.apache.maven+AND+a:maven&rows=1&wt=json&sort=timestamp+desc'

*/

// ./seleniumVersionChecker.sh --input seleniumVersionChecker.yaml --output seleniumVersionChecker.csv
class CliArgs {

    @Option(names = ["--name"], description = "Package name", required = false)
    String packageName

    CommandLine commandLine

    CliArgs parseArgs(String[] args) {
        commandLine = new CommandLine(this)
        commandLine.parseArgs(args)
        this
    }
}

interface Name {
    String getName()
}

class OperatingSystem implements Name {
    String getName() {
        return System.getProperty("os.name").toLowerCase()
    }
}

interface Init {
    void init()
}

interface FilePath {
    String getPath()
}

class GeckoDriver implements FilePath, Init {
    OperatingSystem operatingSystem

    @Override
    String getPath() {
        def osName = operatingSystem.getName()
        if (osName.contains("win")) {
            "C:\\pub\\setmy.info\\lib\\geckodriver.exe"
        } else if (osName.contains("mac")) {
            "/usr/local/bin/geckodriver"
        } else if (osName.contains("nix") || osName.contains("nux") || osName.contains("aix")) {
            "/opt/setmy.info/bin/geckodriver"
        } else {
            throw new RuntimeException("Unsupported OS: $osName")
        }
    }

    @Override
    void init() {
        System.setProperty("webdriver.gecko.driver", getPath())
    }
}

class Firefox implements FilePath, Init {
    OperatingSystem operatingSystem
    FirefoxOptions options
    @Delegate
    WebDriver driver

    @Override
    String getPath() {
        def osName = operatingSystem.getName()
        if (osName.contains("win")) {
            "C:\\Program Files\\Mozilla Firefox\\firefox.exe"
        } else if (osName.contains("mac")) {
            "/Applications/Firefox.app/Contents/MacOS/firefox"
        } else if (osName.contains("nix") || osName.contains("nux") || osName.contains("aix")) {
            "/opt/firefox/firefox"
        } else {
            throw new RuntimeException("Unsupported OS: $osName")
        }
    }

    @Override
    void init() {
        options = new FirefoxOptions(binary: getPath())
        driver = new FirefoxDriver(options)
    }
}

class RulesRegister {
    Map<String, DriverExecute> rulesMap = new HashMap()

    void putAt(String name, DriverExecute rule) {
        rulesMap[name] = rule
    }

    DriverExecute getAt(String name) {
        return rulesMap[name]
    }
}

interface DriverExecute {
    void execute(WebDriver driver)
}

abstract class DriverExecuteBase {
    static final List<String> packageExtensions = [
            ".tar", ".tar.gz", ".tgz", ".tar.bz2", ".tbz2", ".tar.xz", ".txz", ".tar.Z",
            ".zip", ".gz", ".bz2", ".xz", ".7z",
            ".deb", ".rpm",
            ".run", ".sh", ".bin",
            ".appimage",
            ".jar",
            ".dmg",
            ".exe"
    ]
}

class MavenDriverExecute extends DriverExecuteBase implements DriverExecute, Name {

    @Override
    void execute(WebDriver driver) {

        try {
            def url = "https://maven.apache.org/download.cgi"
            driver.get(url)
            println "✅ Page loaded: ${url}"

            def links = driver.findElements(By.tagName("a"))
            def hrefs = links.collect { it.getAttribute("href") }.findAll { it != null }

            def filteredHrefs = hrefs.findAll { href ->
                def hrefLowerCase = href.toLowerCase()
                packageExtensions.any { ext ->
                    hrefLowerCase.endsWith(ext)
                }
            }

            println "🔗 Found links:"
            filteredHrefs.each { println it }

            def finalFiltered = filteredHrefs.findAll { href ->
                href = href.toLowerCase()
                if (!href.endsWith(".tar.gz")) return false
                if (!href.contains("apache-maven-")) return false
                if (href.contains("rc")) return false

                def versionPattern = ~/(?<![a-zA-Z0-9])(\d+\.\d+\.\d+)(?![a-zA-Z0-9])/
                def matcher = (href =~ versionPattern)
                if (!matcher.find()) return false
                def version = matcher.group(1)
                println "🔗 Version: ${version}"

                return true
            }

            println "🔗 Version and package extension links:"
            finalFiltered.each { println it }

            def sortedByUrl = finalFiltered.sort { a, b -> a <=> b }

            println "🔗 Sorted links:"
            sortedByUrl.each { println it }

            println "🔗 Last"
            println "${sortedByUrl.last()}"

        } catch (Exception e) {
            println "❌ Error: ${e.message}"
        } finally {
            driver.quit()
        }
    }

    @Override
    String getName() {
        return "mvn"
    }
}

static void main(String[] args) {
    final OperatingSystem operatingSystem = new OperatingSystem()
    final FilePath geckoDriver = new GeckoDriver(operatingSystem: operatingSystem)
    final FilePath firefox = new Firefox(operatingSystem: operatingSystem)
    final RulesRegister rulesRegister = fillWithRules(new RulesRegister())
    final CliArgs cliArgs = new CliArgs().parseArgs(args)
    /*
    def yaml = new Yaml()
    def config = yaml.load(new File(cliArgs.configFile).text)
    */

    geckoDriver.init()
    firefox.init()
    println "Package name: ${cliArgs.getPackageName()}"
    def rule = rulesRegister[cliArgs.getPackageName()]
    println "Found rule: ${(rule as Name).getName()}"
    rule.execute(firefox)
}

static RulesRegister fillWithRules(RulesRegister rulesRegister) {
    def driverExecute = new MavenDriverExecute()
    rulesRegister[(driverExecute as Name).getName()] = driverExecute
    return rulesRegister
}
