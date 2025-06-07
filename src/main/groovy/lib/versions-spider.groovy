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

//@Grab(group='org.xerial', module='sqlite-jdbc', version='3.49.1.0')
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

// smi-versions-spider -n=mvn
// smi-versions-spider -a

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

interface Search {
    Closure<Boolean> getSearcher()
}

class CliArgs {

    @Option(names = ["--name", "-n"], description = "Package name", required = false)
    List<String> packageNames

    @Option(names = ["--all", "-a"], description = "All packages")
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

    By cssSelector(String selector) {
        By.cssSelector(selector)
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

    String sortAndLast(List<String> hrefs) {
        sort(hrefs).last()
    }

    String sortAndFirst(List<String> hrefs) {
        sort(hrefs).first()
    }

    List<String> sort(List<String> hrefs) {
        hrefs.sort { a, b -> a <=> b }
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

class ThunderbirdDriverExecute extends DriverExecuteBase implements DriverExecute, Name, Url, Search {

    @Override
    void execute(WebDriver driver) {
        try {
            driver.get(getUrl())
            def version = getHrefs(driver).findAll(getSearcher()).unique().first()
                .replaceAll("https://download.mozilla.org/?", "")
                .replaceAll("lang=en-US", "")
                .replaceAll("os=linux64", "")
                .replaceAll("os=win64", "")
                .replaceAll("-SSL", "")
                .replaceAll("product=thunderbird-", "")
                .replaceAll("&", "")
                .replaceAll("\\?", "")
            println "https://download-installer.cdn.mozilla.net/pub/thunderbird/releases/${version}/linux-x86_64/en-US/thunderbird-${version}.tar.xz"
        } catch (Exception e) {
            println "❌ Error: ${e.message}"
        }
    }

    Closure<Boolean> getSearcher() {
        return { href ->
            // https://download.mozilla.org/?product=thunderbird-139.0.1-SSL&os=linux64&lang=en-US
            if (!href.contains("product=thunderbird-")) return false
            if (!href.contains("download")) return false
            if (!href.contains("os=linux64")) return false
            if (!href.contains("lang=en-US")) return false
            return true
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

class SbclDriverExecute extends DriverExecuteBase implements DriverExecute, Name, Url, Search {
    @Override
    void execute(WebDriver driver) {
        try {
            driver.get(getUrl())
            def first = getHrefs(driver).findAll(getSearcher()).first()
            println first
        } catch (Exception e) {
            println "❌ Error: ${e.message}"
        }
    }

    Closure<Boolean> getSearcher() {
        return { href ->
            // http://prdownloads.sourceforge.net/sbcl/sbcl-2.5.5-x86-64-linux-binary.tar.bz2
            if (!href.contains("/sbcl/sbcl-")) return false
            if (!href.endsWith("-x86-64-linux-binary.tar.bz2")) return false
            return true
        }
    }

    @Override
    String getUrl() {
        return "https://www.sbcl.org/platform-table.html"
    }

    @Override
    String getName() {
        return "sbcl"
    }
}

class InfinispanDriverExecute extends DriverExecuteBase implements DriverExecute, Name, Url, Search {
    @Override
    void execute(WebDriver driver) {
        try {
            driver.get(getUrl())
            def first = getHrefs(driver).findAll(getSearcher()).first()
            println first
        } catch (Exception e) {
            println "❌ Error: ${e.message}"
        }
    }

    Closure<Boolean> getSearcher() {
        return { href ->
            // https://github.com/infinispan/infinispan/releases/download/15.2.0.Final/infinispan-server-15.2.0.Final.zip
            if (!href.contains("/infinispan/infinispan/releases/download/")) return false
            if (!href.contains("/infinispan-server-")) return false
            if (!href.endsWith(".Final.zip")) return false
            return true
        }
    }

    @Override
    String getUrl() {
        return "https://infinispan.org/download/"
    }

    @Override
    String getName() {
        return "infinispan"
    }
}

class GoDriverExecute extends DriverExecuteBase implements DriverExecute, Name, Url, Search {
    @Override
    void execute(WebDriver driver) {
        try {
            driver.get(getUrl())
            //sleep(3000)
            def first = getHrefs(driver).findAll(getSearcher()).first()
            println first
        } catch (Exception e) {
            println "❌ Error: ${e.message}"
        }
    }

    Closure<Boolean> getSearcher() {
        return { href ->
            // https://go.dev/dl/go1.24.4.linux-amd64.tar.gz
            if (!href.contains(".dev/dl/go")) return false
            if (!href.endsWith(".linux-amd64.tar.gz")) return false
            return true
        }
    }

    @Override
    String getUrl() {
        return "https://go.dev/dl/"
    }

    @Override
    String getName() {
        return "go"
    }
}

class JuliaDriverExecute extends DriverExecuteBase implements DriverExecute, Name, Url, Search {
    @Override
    void execute(WebDriver driver) {
        try {
            driver.get(getUrl())
            def first = getHrefs(driver).findAll(getSearcher()).first()
            println first
        } catch (Exception e) {
            println "❌ Error: ${e.message}"
        }
    }

    Closure<Boolean> getSearcher() {
        return { href ->
            // https://julialang-s3.julialang.org/bin/linux/x64/1.11/julia-1.11.5-linux-x86_64.tar.gz
            if (!href.contains("/bin/linux/x64/")) return false
            if (!href.endsWith("-linux-x86_64.tar.gz")) return false
            return true
        }
    }

    @Override
    String getUrl() {
        return "https://julialang.org/downloads/"
    }

    @Override
    String getName() {
        return "julia"
    }
}

class HsqldbDriverExecute extends DriverExecuteBase implements DriverExecute, Name, Url {
    @Override
    void execute(WebDriver driver) {
        try {
            //html body div#mid_cont div#sb_left.sidebar_home p font a
            driver.get(getUrl())
            def versions = driver
                .findElements(cssSelector("div#sb_left.sidebar_home p font a"))
                .collect { it.getText() }
                .findAll { it != null && it.contains("latest version ") && it.contains("Download") }
            versions.each {
                def cleaned = it.replace("Download latest version ", "").trim()
                println "https://altushost-swe.dl.sourceforge.net/project/hsqldb/hsqldb/hsqldb_2_7/hsqldb-${cleaned}.zip"
            }
        } catch (Exception e) {
            println "❌ Error: ${e.message}"
        }
    }

    @Override
    String getUrl() {
        return "https://hsqldb.org/"
    }

    @Override
    String getName() {
        return "hsqldb"
    }
}

class GrailsDriverExecute extends DriverExecuteBase implements DriverExecute, Name, Url, Search {
    @Override
    void execute(WebDriver driver) {
        try {
            driver.get(getUrl())
            def first = getHrefs(driver).findAll(getSearcher()).first()
            println first
        } catch (Exception e) {
            println "❌ Error: ${e.message}"
        }
    }

    Closure<Boolean> getSearcher() {
        return { href ->
            // https://github.com/grails/grails-forge/releases/download/v6.2.3/grails-cli-6.2.3.zip
            if (!href.contains("/grails/grails-forge/releases/download/v")) return false
            if (!href.endsWith(".zip")) return false
            return true
        }
    }

    @Override
    String getUrl() {
        return "https://grails.org/"
    }

    @Override
    String getName() {
        return "grails"
    }
}

class JenkinsDriverExecute extends DriverExecuteBase implements DriverExecute, Name, Url, Search {
    @Override
    void execute(WebDriver driver) {
        try {
            driver.get(getUrl())
            def first = getHrefs(driver).findAll(getSearcher()).first()
            println first
        } catch (Exception e) {
            println "❌ Error: ${e.message}"
        }
    }

    Closure<Boolean> getSearcher() {
        return { href ->
            // https://get.jenkins.io/war-stable/2.504.2/jenkins.war
            if (!href.contains("/war-stable/")) return false
            if (!href.endsWith("/jenkins.war")) return false
            return true
        }
    }

    @Override
    String getUrl() {
        return "https://www.jenkins.io/download/"
    }

    @Override
    String getName() {
        return "jenkins"
    }
}

class SeleniumDriverExecute extends DriverExecuteBase implements DriverExecute, Name, Url, Search {
    @Override
    void execute(WebDriver driver) {
        try {
            driver.get(getUrl())
            def first = getHrefs(driver).findAll(getSearcher()).first()
            println first
        } catch (Exception e) {
            println "❌ Error: ${e.message}"
        }
    }

    Closure<Boolean> getSearcher() {
        return { href ->
            // https://github.com/SeleniumHQ/selenium/releases/download/selenium-4.33.0/selenium-server-4.33.0.jar
            if (!href.contains("/SeleniumHQ/selenium/releases/download/selenium-")) return false
            if (!href.endsWith(".jar")) return false
            if (!href.contains("selenium-server-")) return false
            if (href.contains("-alpha")) return false
            if (href.contains("-beta")) return false
            if (href.contains("-rc")) return false
            if (href.contains("selenium-server-standalone-")) return false
            return true
        }
    }

    @Override
    String getUrl() {
        return "https://www.selenium.dev/downloads/"
    }

    @Override
    String getName() {
        return "selenium"
    }
}

class GeckodriverDriverExecute extends DriverExecuteBase implements DriverExecute, Name, Url, Search {
    @Override
    void execute(WebDriver driver) {
        try {
            driver.get(getUrl())
            def last = sortAndLast(getHrefs(driver).findAll(getSearcher()))
            def version = last.split("mozilla/geckodriver/releases/tag/v")[1]
            println "https://github.com/mozilla/geckodriver/releases/download/v${version}/geckodriver-v${version}-linux64.tar.gz"
        } catch (Exception e) {
            println "❌ Error: ${e.message}"
        }
    }

    Closure<Boolean> getSearcher() {
        return { href ->
            // https://github.com/mozilla/geckodriver/releases/tag/v0.36.0
            href = href.toLowerCase()
            if (!href.contains("/mozilla/geckodriver/releases/tag/v")) return false
            return true
        }
    }

    @Override
    String getUrl() {
        return "https://github.com/mozilla/geckodriver/releases"
    }

    @Override
    String getName() {
        return "geckodriver"
    }
}

class BazelDriverExecute extends DriverExecuteBase implements DriverExecute, Name, Url, Search {
    @Override
    void execute(WebDriver driver) {
        try {
            driver.get(getUrl())
            def last = sortAndLast(getHrefs(driver).findAll(getSearcher()))
            def version = last.split("bazelbuild/bazel/releases/tag/")[1]
            println "https://github.com/bazelbuild/bazel/releases/download/${version}/bazel_nojdk-${version}-linux-x86_64"
        } catch (Exception e) {
            println "❌ Error: ${e.message}"
        }
    }

    Closure<Boolean> getSearcher() {
        return { href ->
            // https://github.com/bazelbuild/bazel/releases/tag/8.2.1
            href = href.toLowerCase()
            if (!href.contains("/bazelbuild/bazel/releases/tag/")) return false
            return true
        }
    }

    @Override
    String getUrl() {
        return "https://github.com/bazelbuild/bazel/releases"
    }

    @Override
    String getName() {
        return "bazel"
    }
}

class JanetDriverExecute extends DriverExecuteBase implements DriverExecute, Name, Url, Search {
    @Override
    void execute(WebDriver driver) {
        try {
            driver.get(getUrl())
            def last = sortAndLast(getHrefs(driver).findAll(getSearcher()))
            def version = last.split("janet-lang/janet/releases/tag/v")[1]
            println "https://github.com/janet-lang/janet/releases/download/v${version}/janet-v${version}-linux-x64.tar.gz"
        } catch (Exception e) {
            println "❌ Error: ${e.message}"
        }
    }

    Closure<Boolean> getSearcher() {
        return { href ->
            // https://github.com/janet-lang/janet/releases/tag/v1.38.0
            href = href.toLowerCase()
            if (!href.contains("/janet-lang/janet/releases/tag/v")) return false
            return true
        }
    }

    @Override
    String getUrl() {
        return "https://github.com/janet-lang/janet/releases"
    }

    @Override
    String getName() {
        return "janet"
    }
}

class ChromedriverDriverExecute extends DriverExecuteBase implements DriverExecute, Name, Url {
    @Override
    void execute(WebDriver driver) {
        try {
            driver.get(getUrl())
            def version = driver.findElements(cssSelector("html body section#stable.status-ok p code"))//Version label in page
                .first()
                .getText()
            println "https://storage.googleapis.com/chrome-for-testing-public/${version}/linux64/chrome-linux64.zip"
        } catch (Exception e) {
            println "❌ Error: ${e.message}"
        }
    }

    @Override
    String getUrl() {
        return "https://googlechromelabs.github.io/chrome-for-testing/"
    }

    @Override
    String getName() {
        return "chromedriver"
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
        return "https://tomcat.apache.org/"
    }

    @Override
    String getName() {
        return "tomcat"
    }
}

class NetbeansDriverExecute extends DriverExecuteBase implements DriverExecute, Name, Url, Search {
    @Override
    void execute(WebDriver driver) {
        try {
            // https://dlcdn.apache.org/netbeans/netbeans/26/netbeans-26-bin.zip
            driver.get(getUrl())
            def first = getHrefs(driver).findAll(getSearcher()).first()
            def version = first.split("/apache/netbeans/releases/tag/")[1]
            println "https://dlcdn.apache.org/netbeans/netbeans/${version}/netbeans-${version}-bin.zip"
        } catch (Exception e) {
            println "❌ Error: ${e.message}"
        }
    }

    Closure<Boolean> getSearcher() {
        return { href ->
            href = href.toLowerCase()
            if (!href.contains("/apache/netbeans/releases/tag/")) return false
            if (href.contains("-rc")) return false
            return true
        }
    }

    @Override
    String getUrl() {
        return "https://github.com/apache/netbeans/releases"
    }

    @Override
    String getName() {
        return "netbeans"
    }
}

class PythonDriverExecute extends DriverExecuteBase implements DriverExecute, Name, Url {
    @Override
    void execute(WebDriver driver) {
        try {
            driver.get(getUrl())
            def allowedPrefixes = ['3.9.', '3.10.', '3.11.', '3.12.', '3.13.', '3.14.', '3.15.', '3.16.']
            def versions = driver
                .findElements(cssSelector("li span.release-number a"))
                .collect { it.getText() }
                .findAll { it != null }
                .collect { it.replace('Python ', '') }
                .take(10)

            def filteredVersions = allowedPrefixes.collect { prefix ->
                versions.find { v -> v.startsWith(prefix) }
            }.findAll { it != null }
            filteredVersions.each {
                println "https://www.python.org/ftp/python/${it}/Python-${it}.tgz"
            }
        } catch (Exception e) {
            println "❌ Error: ${e.message}"
        }
    }

    @Override
    String getUrl() {
        return "https://www.python.org/downloads/"
    }

    @Override
    String getName() {
        return "python"
    }
}

class H2DriverExecute extends DriverExecuteBase implements DriverExecute, Name, Url, Search {
    @Override
    void execute(WebDriver driver) {
        try {
            driver.get(getUrl())
            def first = getHrefs(driver).findAll(getSearcher()).first()
            def version = first.split("/h2-")[1].replace(".jar", "")
            println "https://search.maven.org/remotecontent?filepath=com/h2database/h2/${version}/h2-${version}.jar"
        } catch (Exception e) {
            println "❌ Error: ${e.message}"
        }
    }

    Closure<Boolean> getSearcher() {
        return { href ->
            // https://search.maven.org/remotecontent?filepath=com/h2database/h2/2.3.232/h2-2.3.232.jar
            href = href.toLowerCase()
            if (!href.contains("com/h2database/h2/")) return false
            if (!href.endsWith(".jar")) return false
            if (!href.startsWith("https://search.maven.org/remotecontent")) return false
            return true
        }
    }

    @Override
    String getUrl() {
        return "https://www.h2database.com/html/download.html"
    }

    @Override
    String getName() {
        return "h2"
    }
}

class ArgoDriverExecute extends DriverExecuteBase implements DriverExecute, Name, Url, Search {
    @Override
    void execute(WebDriver driver) {
        try {
            driver.get(getUrl())
            def last = sortAndLast(getHrefs(driver).findAll(getSearcher()))
            def version = last.split("argoproj/argo-workflows/releases/tag/v")[1]
            println "https://github.com/argoproj/argo-workflows/releases/download/v${version}/argo-linux-amd64.gz"
        } catch (Exception e) {
            println "❌ Error: ${e.message}"
        }
    }

    Closure<Boolean> getSearcher() {
        return { href ->
            // https://github.com/argoproj/argo-workflows/releases/tag/v3.6.10
            href = href.toLowerCase()
            if (!href.contains("/argoproj/argo-workflows/releases/tag/v")) return false
            if (href.contains("-rc")) return false
            return true
        }
    }

    @Override
    String getUrl() {
        return "https://github.com/argoproj/argo-workflows/releases/"
    }

    @Override
    String getName() {
        return "argo"
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
        if (cliArgs.isAll()) {
            rulesRegister.rulesMap.each { it.value.execute(firefox.getDriver()) }
        } else {
            cliArgs.getPackageNames().each {
                def rule = requireNonNull(rulesRegister[it], "❌ Missing rule: '${it}'")
                rule.execute(firefox.getDriver())
            }
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
    fillWithRules(new SeleniumDriverExecute(), rulesRegister)
    fillWithRules(new GeckodriverDriverExecute(), rulesRegister)
    fillWithRules(new ChromedriverDriverExecute(), rulesRegister)
    fillWithRules(new SbclDriverExecute(), rulesRegister)
    fillWithRules(new InfinispanDriverExecute(), rulesRegister)
    fillWithRules(new GoDriverExecute(), rulesRegister)
    fillWithRules(new JuliaDriverExecute(), rulesRegister)
    fillWithRules(new HsqldbDriverExecute(), rulesRegister)
    fillWithRules(new GrailsDriverExecute(), rulesRegister)
    fillWithRules(new JenkinsDriverExecute(), rulesRegister)
    fillWithRules(new TomcatDriverExecute(), rulesRegister)
    fillWithRules(new NetbeansDriverExecute(), rulesRegister)
    fillWithRules(new PythonDriverExecute(), rulesRegister)
    fillWithRules(new BazelDriverExecute(), rulesRegister)
    fillWithRules(new JanetDriverExecute(), rulesRegister)
    fillWithRules(new H2DriverExecute(), rulesRegister)
    fillWithRules(new ArgoDriverExecute(), rulesRegister)
    return rulesRegister
}

static RulesRegister fillWithRules(DriverExecute driverExecute, RulesRegister rulesRegister) {
    rulesRegister[(driverExecute as Name).getName()] = driverExecute
    return rulesRegister
}
