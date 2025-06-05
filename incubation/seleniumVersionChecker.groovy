#!/usr/bin/env groovy
import org.openqa.selenium.By
import org.openqa.selenium.WebDriver
import org.openqa.selenium.firefox.FirefoxDriver
import org.openqa.selenium.firefox.FirefoxOptions
import picocli.CommandLine
import picocli.CommandLine.Option

import static java.util.Objects.requireNonNull

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

interface Name {
    String getName()
}

interface Init {
    void init()
}

interface Close {
    void close()
}

interface FilePath {
    String getPath()
}

interface DriverExecute {
    void execute(WebDriver driver)
}

interface Url {
    String getUrl()
}

class CliArgs {

    @Option(names = ["--name", "-n"], description = "Package name", required = false)
    List<String> packageNames

    @Option(names = ["--all", "-a"], description = "All packages", defaultValue = false, required = false)
    boolean all

    CommandLine commandLine

    CliArgs parseArgs(String[] args) {
        commandLine = new CommandLine(this)
        commandLine.parseArgs(args)
        this
    }
}

class OperatingSystem implements Name {
    String name = System.getProperty("os.name").toLowerCase()
}

class GeckoDriver implements FilePath, Init {
    OperatingSystem operatingSystem

    @Override
    String getPath() {
        def osName = operatingSystem.getName()
        if (osName.contains("win")) {
            "C:\\pub\\setmy.info\\bin\\geckodriver.exe"
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

class Firefox implements FilePath, Init, Close {
    OperatingSystem operatingSystem
    FirefoxOptions options
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

    @Override
    void close() {
        driver.close()
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

    By tag(String name) {
        By.tagName(name)
    }

    By id(String id) {
        By.id(id)
    }

    By className(String id) {
        By.className(id)
    }

    By cssSelector(String id) {
        By.cssSelector(id)
    }

    By xpath(String id) {
        By.xpath(id)
    }

    List<String> packageHrefs(List<String> links) {
        def hrefs = links.collect { it.getAttribute("href") }.findAll { it != null }
        def filteredHrefs = hrefs.findAll { href ->
            def hrefLowerCase = href.toLowerCase()
            packageExtensions.any { ext ->
                hrefLowerCase.endsWith(ext)
            }
        }
        return filteredHrefs
    }

    String getVersion(String url) {
        def versionPattern = ~/(?<![a-zA-Z0-9])(\d+\.\d+\.\d+)(?![a-zA-Z0-9])/
        //def versionPattern = ~/(\d+\.\d+\.\d+)/
        def matcher = (url =~ versionPattern)
        if (matcher.find()) {
            def version = matcher.group(1)
            version
        }
        ""
    }

    List<String> getHrefs(WebDriver driver) {
        def hrefs = driver
            .findElements(tag("a"))
            .collect { it.getAttribute("href") }
            .findAll { it != null }
        hrefs
    }
}

class MavenDriverExecute extends DriverExecuteBase implements DriverExecute, Name, Url {

    @Override
    void execute(WebDriver driver) {
        try {
            driver.get(getUrl())
            def links = driver.findElements(tag("a"))
            def filteredHrefs = packageHrefs(links)
            //filteredHrefs.each { println it }
            def finalFiltered = filteredHrefs.findAll { href ->
                href = href.toLowerCase()
                if (!href.endsWith(".tar.gz")) return false
                if (!href.contains("apache-maven-")) return false
                if (href.contains("rc")) return false

                return true
            }
            //finalFiltered.each { println it }
            def sortedByUrl = finalFiltered.sort { a, b -> a <=> b }
            //sortedByUrl.each { println it }
            def lastItem = sortedByUrl.last()
            def versionPattern = ~/(?<![a-zA-Z0-9])(\d+\.\d+\.\d+)(?![a-zA-Z0-9])/
            def matcher = (lastItem =~ versionPattern)
            if (matcher.find()) {
                def version = matcher.group(1)
                //println "${version}"
            }
            println "${lastItem}"
        } catch (Exception e) {
            println "❌ Error: ${e.message}"
        }
    }

    @Override
    String getUrl() {
        return "https://maven.apache.org/download.cgi"
    }

    @Override
    String getName() {
        return "mvn"
    }
}

class JdkDriverExecute extends DriverExecuteBase implements DriverExecute, Name, Url {

    @Override
    void execute(WebDriver driver) {
        try {
            driver.get(getUrl())
            String firstHref = "https://jdk.java.net/"
            def links = driver.findElements(tag("a"))
            def hrefs = links
                .collect { it.getAttribute("href") }
                .findAll { it != null }
                .findAll { it.toLowerCase().startsWith(firstHref) && it.length() > firstHref.length() }
            //https://jdk.java.net/24
            //Begins with: https://jdk.java.net/ and is longer than that
            def jdkDownloadPageUrl = hrefs.first()
            //println "jdkDownloadPageUrl ${jdkDownloadPageUrl}"
            driver.get(jdkDownloadPageUrl)
            links = driver.findElements(tag("a"))
            //https://download.java.net/java/GA/jdk24.0.1/24a58e0e276943138bf3e963e6291ac2/9/GPL/openjdk-24.0.1_linux-x64_bin.tar.gz
            def filteredHrefs = packageHrefs(links)
            //filteredHrefs.each { println it }

            def finalFiltered = filteredHrefs.findAll { href ->
                href = href.toLowerCase()
                if (!href.endsWith(".tar.gz")) return false
                if (!href.contains("linux")) return false
                if (!href.contains("x64")) return false
                return true
            }
            finalFiltered.each { println it }
        } catch (Exception e) {
            println "❌ Error: ${e.message}"
        }
    }

    @Override
    String getUrl() {
        return "https://openjdk.org/"
    }

    @Override
    String getName() {
        return "jdk"
    }
}

class GradleDriverExecute extends DriverExecuteBase implements DriverExecute, Name, Url {

    @Override
    void execute(WebDriver driver) {
        try {
            driver.get(getUrl())
            def links = driver.findElements(tag("a"))
            def hrefs = links
                .collect { it.getAttribute("href") }
                .findAll { it != null }

            def finalFiltered = hrefs.findAll { href ->
                href = href.toLowerCase()
                if (!href.endsWith("&format=bin")) return false
                return true
            }

            //https://gradle.org/next-steps/?version=8.14.1&format=bin
            def gradleDownloadPageUrl = finalFiltered.first()
            def version = gradleDownloadPageUrl
                .replace("https://gradle.org/next-steps/?version=", "")
                .replace("&format=bin", "")
            //println gradleDownloadPageUrl
            //println version
            def downloadUrl = "https://services.gradle.org/distributions/gradle-${version}-bin.zip"
            println downloadUrl
        } catch (Exception e) {
            println "❌ Error: ${e.message}"
        }
    }

    @Override
    String getUrl() {
        return "https://gradle.org/install/"
    }

    @Override
    String getName() {
        return "gradle"
    }
}

class CmakeDriverExecute extends DriverExecuteBase implements DriverExecute, Name, Url {

    @Override
    void execute(WebDriver driver) {
        try {
            driver.get(getUrl())
            def links = driver.findElements(tag("a"))
            def filteredHrefs = packageHrefs(links)
            def finalFiltered = filteredHrefs.findAll { href ->
                href = href.toLowerCase()
                //linux-x86_64.tar.gz
                if (!href.endsWith(".tar.gz")) return false
                if (!href.contains("linux")) return false
                if (!href.contains("x86_64")) return false
                if (href.contains("-rc")) return false
                return true
            }
            finalFiltered = finalFiltered.sort { a, b -> a <=> b }
            //finalFiltered.each { println it }
            def lastItem = finalFiltered.last()
            println lastItem
        } catch (Exception e) {
            println "❌ Error: ${e.message}"
        }
    }

    @Override
    String getUrl() {
        return "https://cmake.org/download/"
    }

    @Override
    String getName() {
        return "cmake"
    }
}

class NodeDriverExecute extends DriverExecuteBase implements DriverExecute, Name, Url {

    @Override
    void execute(WebDriver driver) {
        try {
            driver.get(getUrl())
            sleep(1000)
            def links = driver.findElements(tag("a"))
            def filteredHrefs = packageHrefs(links)
            //filteredHrefs.each { println it }
            def finalFiltered = filteredHrefs.findAll { href ->
                href = href.toLowerCase()
                //https://nodejs.org/dist/v22.16.0/node-v22.16.0-linux-x64.tar.xz
                if (!href.endsWith(".tar.xz")) return false
                if (!href.contains("-linux")) return false
                if (!href.contains("-x64")) return false
                return true
            }
            finalFiltered = finalFiltered.sort { a, b -> a <=> b }
            finalFiltered.each { println it }
        } catch (Exception e) {
            println "❌ Error: ${e.message}"
        }
    }

    @Override
    String getUrl() {
        return "https://nodejs.org/en/download"
    }

    @Override
    String getName() {
        return "node"
    }
}

class GroovyDriverExecute extends DriverExecuteBase implements DriverExecute, Name, Url {

    @Override
    void execute(WebDriver driver) {
        try {
            //https://groovy.jfrog.io/ui/native/dist-release-local/groovy-zips/apache-groovy-sdk-4.0.27.zip
            driver.get(getUrl())
            def button = driver.findElements(id("big-download-button"))
            button = button.first()
            def version = button.getText()
                .replace("Download ", "")
            //println version
            def downloadUrl = "https://groovy.jfrog.io/ui/native/dist-release-local/groovy-zips/apache-groovy-sdk-${version}.zip"
            println downloadUrl
        } catch (Exception e) {
            println "❌ Error: ${e.message}"
        }
    }

    @Override
    String getUrl() {
        return "https://groovy.apache.org/download.html"
    }

    @Override
    String getName() {
        return "groovy"
    }
}

class FirefoxDriverExecute extends DriverExecuteBase implements DriverExecute, Name, Url {

    @Override
    void execute(WebDriver driver) {
        try {
            driver.get(getUrl())
            def spanElement = driver.findElements(cssSelector(".c-release-version"))
            spanElement = spanElement.first()
            def version = spanElement.getText()
            def downloadUrl = "https://download-installer.cdn.mozilla.net/pub/firefox/releases/139.0.1/linux-x86_64/en-US/firefox-${version}.tar.xz"
            println downloadUrl
        } catch (Exception e) {
            println "❌ Error: ${e.message}"
        }
    }

    @Override
    String getUrl() {
        return "https://www.mozilla.org/en-US/firefox/notes/"
    }

    @Override
    String getName() {
        return "firefox"
    }
}

class ThunderbirdDriverExecute extends DriverExecuteBase implements DriverExecute, Name, Url {

    @Override
    void execute(WebDriver driver) {
        try {
            driver.get(getUrl())
            def downloadButton = driver.findElements(id("download-btn"))
            def version = downloadButton.first().getAttribute("href")
                .replace("https://download.mozilla.org/?product=thunderbird-", "")
                .replace("-SSL&os=win64&lang=en-US", "");
            println "https://download-installer.cdn.mozilla.net/pub/thunderbird/releases/${version}/linux-x86_64/en-US/thunderbird-${version}.tar.xz"
        } catch (Exception e) {
            println "❌ Error: ${e.message}"
        }
    }

    @Override
    String getUrl() {
        return "https://www.thunderbird.net/en-US/thunderbird/all/"
    }

    @Override
    String getName() {
        return "thunderbird"
    }
}

class SbclDriverExecute extends DriverExecuteBase implements DriverExecute, Name, Url {
    @Override
    void execute(WebDriver driver) {
        try {
            driver.get(getUrl())
        } catch (Exception e) {
            println "❌ Error: ${e.message}"
        }
    }

    @Override
    String getUrl() {
        return "https://example.com/"
    }

    @Override
    String getName() {
        return "xxxxxxx"
    }
}

class InfinispanDriverExecute extends DriverExecuteBase implements DriverExecute, Name, Url {
    @Override
    void execute(WebDriver driver) {
        try {
            driver.get(getUrl())
        } catch (Exception e) {
            println "❌ Error: ${e.message}"
        }
    }

    @Override
    String getUrl() {
        return "https://example.com/"
    }

    @Override
    String getName() {
        return "xxxxxxx"
    }
}

class GoDriverExecute extends DriverExecuteBase implements DriverExecute, Name, Url {
    @Override
    void execute(WebDriver driver) {
        try {
            driver.get(getUrl())
        } catch (Exception e) {
            println "❌ Error: ${e.message}"
        }
    }

    @Override
    String getUrl() {
        return "https://example.com/"
    }

    @Override
    String getName() {
        return "xxxxxxx"
    }
}

class JuliaDriverExecute extends DriverExecuteBase implements DriverExecute, Name, Url {
    @Override
    void execute(WebDriver driver) {
        try {
            driver.get(getUrl())
        } catch (Exception e) {
            println "❌ Error: ${e.message}"
        }
    }

    @Override
    String getUrl() {
        return "https://example.com/"
    }

    @Override
    String getName() {
        return "xxxxxxx"
    }
}

class HsqldbDriverExecute extends DriverExecuteBase implements DriverExecute, Name, Url {
    @Override
    void execute(WebDriver driver) {
        try {
            driver.get(getUrl())
        } catch (Exception e) {
            println "❌ Error: ${e.message}"
        }
    }

    @Override
    String getUrl() {
        return "https://example.com/"
    }

    @Override
    String getName() {
        return "xxxxxxx"
    }
}

class GrailsDriverExecute extends DriverExecuteBase implements DriverExecute, Name, Url {
    @Override
    void execute(WebDriver driver) {
        try {
            driver.get(getUrl())
        } catch (Exception e) {
            println "❌ Error: ${e.message}"
        }
    }

    @Override
    String getUrl() {
        return "https://example.com/"
    }

    @Override
    String getName() {
        return "xxxxxxx"
    }
}

class JenkinsDriverExecute extends DriverExecuteBase implements DriverExecute, Name, Url {
    @Override
    void execute(WebDriver driver) {
        try {
            driver.get(getUrl())
        } catch (Exception e) {
            println "❌ Error: ${e.message}"
        }
    }

    @Override
    String getUrl() {
        return "https://example.com/"
    }

    @Override
    String getName() {
        return "xxxxxxx"
    }
}

class SeleniumDriverExecute extends DriverExecuteBase implements DriverExecute, Name, Url {
    @Override
    void execute(WebDriver driver) {
        try {
            driver.get(getUrl())
        } catch (Exception e) {
            println "❌ Error: ${e.message}"
        }
    }

    @Override
    String getUrl() {
        return "https://example.com/"
    }

    @Override
    String getName() {
        return "xxxxxxx"
    }
}

class GeckodriverDriverExecute extends DriverExecuteBase implements DriverExecute, Name, Url {
    @Override
    void execute(WebDriver driver) {
        try {
            driver.get(getUrl())
        } catch (Exception e) {
            println "❌ Error: ${e.message}"
        }
    }

    @Override
    String getUrl() {
        return "https://example.com/"
    }

    @Override
    String getName() {
        return "xxxxxxx"
    }
}

class ChromedriverDriverExecute extends DriverExecuteBase implements DriverExecute, Name, Url {
    @Override
    void execute(WebDriver driver) {
        try {
            driver.get(getUrl())
        } catch (Exception e) {
            println "❌ Error: ${e.message}"
        }
    }

    @Override
    String getUrl() {
        return "https://example.com/"
    }

    @Override
    String getName() {
        return "xxxxxxx"
    }
}

class TomcatDriverExecute extends DriverExecuteBase implements DriverExecute, Name, Url {
    @Override
    void execute(WebDriver driver) {
        try {
            driver.get(getUrl())
        } catch (Exception e) {
            println "❌ Error: ${e.message}"
        }
    }

    @Override
    String getUrl() {
        return "https://example.com/"
    }

    @Override
    String getName() {
        return "xxxxxxx"
    }
}

class NetbeansDriverExecute extends DriverExecuteBase implements DriverExecute, Name, Url {
    @Override
    void execute(WebDriver driver) {
        try {
            driver.get(getUrl())
        } catch (Exception e) {
            println "❌ Error: ${e.message}"
        }
    }

    @Override
    String getUrl() {
        return "https://example.com/"
    }

    @Override
    String getName() {
        return "xxxxxxx"
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
    try {
        geckoDriver.init()
        firefox.init()
        //println "Package name: ${cliArgs.getPackageName()}"
        if (!cliArgs.all) {
            cliArgs.getPackageNames().each {
                def rule = requireNonNull(rulesRegister[it], "❌ Missing rule: '${it}'")
                rule.execute(firefox.getDriver())
            }
        } else {//All
            def valuesList = rulesRegister.values()
            valuesList.each {it.execute(firefox.getDriver())}
        }
    } catch (Exception exception) {
        println "❌ Error: ${exception.message}"
    } finally {
        (firefox as Close).close()
    }
}

static RulesRegister fillWithRules(RulesRegister rulesRegister) {
    fillWithRules(new MavenDriverExecute(), rulesRegister)
    fillWithRules(new JdkDriverExecute(), rulesRegister)
    fillWithRules(new GradleDriverExecute(), rulesRegister)
    fillWithRules(new CmakeDriverExecute(), rulesRegister)
    fillWithRules(new NodeDriverExecute(), rulesRegister)
    fillWithRules(new GroovyDriverExecute(), rulesRegister)
    fillWithRules(new FirefoxDriverExecute(), rulesRegister)
    fillWithRules(new ThunderbirdDriverExecute(), rulesRegister)
    /*
    fillWithRules(new SbclDriverExecute(), rulesRegister)
    fillWithRules(new InfinispanDriverExecute(), rulesRegister)
    fillWithRules(new GoDriverExecute(), rulesRegister)
    fillWithRules(new JuliaDriverExecute(), rulesRegister)
    fillWithRules(new HsqldbDriverExecute(), rulesRegister)
    fillWithRules(new GrailsDriverExecute(), rulesRegister)
    fillWithRules(new JenkinsDriverExecute(), rulesRegister)
    fillWithRules(new SeleniumDriverExecute(), rulesRegister)
    fillWithRules(new GeckodriverDriverExecute(), rulesRegister)
    fillWithRules(new ChromedriverDriverExecute(), rulesRegister)
    fillWithRules(new TomcatDriverExecute(), rulesRegister)
    fillWithRules(new NetbeansDriverExecute(), rulesRegister)
    */
    return rulesRegister
}

static RulesRegister fillWithRules(DriverExecute driverExecute, RulesRegister rulesRegister) {
    rulesRegister[(driverExecute as Name).getName()] = driverExecute
    return rulesRegister
}
