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
        def versionPattern = ~/(?<![a-zA-Z0-9])(\d+\.\d+(\.\d+)?)(?![a-zA-Z0-9])/
        def matcher = (url =~ versionPattern)
        if (matcher.find()) {
            return matcher.group(1)
        }
        ""
    }

    List<String> getHrefs(WebDriver driver) {
        sleep(5000)
        def elements = driver.findElements(tag("a"))
        //println " DEBUG:Elements found: ${elements.size()}"
        def hrefs = elements
            .collect { 
                try {
                    return it.getAttribute("href")
                } catch (Exception e) {
                    return null
                }
            }
            .findAll { it != null }
        //println "DEBUG: Hrefs found: ${hrefs.size()}"
        if (hrefs.size() > 0) {
            //println "DEBUG: Sample hrefs:"
            hrefs.findAll { it.contains("releases/tag") }.take(5).each { /*println "  $it"*/ }
        }
        hrefs
    }

    String sortAndLast(List<String> hrefs) {
        if (!hrefs) {
            throw new RuntimeException("Empty hrefs list for sortAndLast")
        }
        sort(hrefs).last()
    }

    String sortAndFirst(List<String> hrefs) {
        if (!hrefs) {
            throw new RuntimeException("Empty hrefs list for sortAndFirst")
        }
        sort(hrefs).first()
    }

    List<String> sort(List<String> hrefs) {
        hrefs.sort { a, b -> a <=> b }
    }
}

class MavenDriverExecute extends DriverExecuteBase implements DriverExecute, Name, Url {

    @Override
    void execute(WebDriver driver) {
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
        if (!sortedByUrl) {
            throw new RuntimeException("No maven packages found at ${getUrl()}")
        }
        def lastItem = sortedByUrl.last()
        def versionPattern = ~/(?<![a-zA-Z0-9])(\d+\.\d+\.\d+)(?![a-zA-Z0-9])/
        def matcher = (lastItem =~ versionPattern)
        if (matcher.find()) {
            def version = matcher.group(1)
            //println "${version}"
        }
        println "${lastItem}"
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
        driver.get(getUrl())
        String firstHref = "https://jdk.java.net/"
        def links = driver.findElements(tag("a"))
        def hrefs = links
            .collect { it.getAttribute("href") }
            .findAll { it != null }
            .findAll { it.toLowerCase().startsWith(firstHref) && it.length() > firstHref.length() }
        //https://jdk.java.net/24
        //Begins with: https://jdk.java.net/ and is longer than that
        if (!hrefs) {
            throw new RuntimeException("No JDK versions found at ${getUrl()}")
        }
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
        driver.get(getUrl())
        def links = driver.findElements(tag("a"))
        def hrefs = links
            .collect { it.getAttribute("href") }
            .findAll { it != null }

        def finalFiltered = hrefs.findAll { href ->
            href = href.toLowerCase()
            if (!href.endsWith("bin.zip")) return false
            return true
        }

        //https://gradle.org/next-steps/?version=8.14.1&format=bin
        if (!finalFiltered) {
            throw new RuntimeException("No gradle download links found at ${getUrl()}")
        }
        def gradleDownloadPageUrl = finalFiltered.first()
        def version = gradleDownloadPageUrl
            .replace("https://gradle.org/next-steps/?version=", "")
            .replace("&format=bin", "")
        //println gradleDownloadPageUrl
        //println version
        // https://services.gradle.org/distributions/gradle-9.3.1-bin.zip
        def downloadUrl = "https://services.gradle.org/distributions/gradle-${version}-bin.zip"
        println downloadUrl
    }

    @Override
    String getUrl() {
        return "https://gradle.org/releases/"
    }

    @Override
    String getName() {
        return "gradle"
    }
}

class CmakeDriverExecute extends DriverExecuteBase implements DriverExecute, Name, Url {

    @Override
    void execute(WebDriver driver) {
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
        if (!finalFiltered) {
            throw new RuntimeException("No cmake packages found at ${getUrl()}")
        }
        def lastItem = finalFiltered.last()
        println lastItem
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
        driver.get(getUrl())
        sleep(1000)
        def links = driver.findElements(tag("a"))
        def filteredHrefs = packageHrefs(links)
        //filteredHrefs.each { println it }
        def finalFiltered = filteredHrefs.findAll { href ->
            href = href.toLowerCase()
            //println "🔗: ${href}"
            //https://nodejs.org/dist/v22.16.0/node-v22.16.0-linux-x64.tar.xz
            //https://nodejs.org/dist/v22.19.0/node-v22.19.0-linux-x64.tar.xz
            //https://nodejs.org/dist/v22.19.0/node-v22.19.0-win-x64.zip
            //https://nodejs.org/dist/v22.19.0/node-v22.19.0.tar.gz
            if (href.endsWith(".tar.xz") && href.contains("-linux") && href.contains("-x64"))
                return true
            if (href.endsWith(".zip") && href.contains("-win") && href.contains("-x64"))
                return true
            return false
        }
        finalFiltered = finalFiltered.sort { a, b -> a <=> b }
        finalFiltered.each { println it }
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
        //https://groovy.jfrog.io/ui/native/dist-release-local/groovy-zips/apache-groovy-sdk-4.0.27.zip
        driver.get(getUrl())
        def button = driver.findElements(id("big-download-button"))
        if (!button) {
            throw new RuntimeException("Download button not found at ${getUrl()}")
        }
        button = button.first()
        def version = button.getText()
            .replace("Download ", "")
        //println version
        def downloadUrl = "https://groovy.jfrog.io/ui/native/dist-release-local/groovy-zips/apache-groovy-sdk-${version}.zip"
        println downloadUrl
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
        driver.get(getUrl())
        def spanElement = driver.findElements(cssSelector(".c-release-version"))
        if (!spanElement) {
            throw new RuntimeException("Release version span not found at ${getUrl()}")
        }
        spanElement = spanElement.first()
        def version = spanElement.getText()
        def downloadUrl = "https://download-installer.cdn.mozilla.net/pub/firefox/releases/${version}/linux-x86_64/en-US/firefox-${version}.tar.xz"
        println downloadUrl
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
        driver.get(getUrl())
        def hrefs = getHrefs(driver).findAll(getSearcher()).unique()
        if (!hrefs) {
            throw new RuntimeException("No thunderbird download links found at ${getUrl()}")
        }
        def version = hrefs.first()
            .replaceAll("https://download.mozilla.org/?", "")
            .replaceAll("lang=en-US", "")
            .replaceAll("os=linux64", "")
            .replaceAll("os=win64", "")
            .replaceAll("-SSL", "")
            .replaceAll("product=thunderbird-", "")
            .replaceAll("&", "")
            .replaceAll("\\?", "")
        println "https://download-installer.cdn.mozilla.net/pub/thunderbird/releases/${version}/linux-x86_64/en-US/thunderbird-${version}.tar.xz"
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
        driver.get(getUrl())
        def first = sortAndFirst(getHrefs(driver).findAll(getSearcher()))
        println first
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
        driver.get(getUrl())
        def first = sortAndFirst(getHrefs(driver).findAll(getSearcher()))
        println first
    }

    Closure<Boolean> getSearcher() {
        return { href ->
            // https://github.com/infinispan/infinispan/releases/download/15.2.0.Final/infinispan-server-15.2.0.Final.zip
            // https://github.com/infinispan/infinispan/releases/download/16.1.0/infinispan-server-16.1.0.zip
            if (!href.contains("/infinispan/infinispan/releases/download/")) return false
            if (!href.contains("/infinispan-server-")) return false
            if (!href.endsWith(".zip")) return false
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
        driver.get(getUrl())
        //sleep(3000)
        def first = sortAndFirst(getHrefs(driver).findAll(getSearcher()))
        println first
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
        driver.get(getUrl())
        def first = sortAndFirst(getHrefs(driver).findAll(getSearcher()))
        println first
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
        return "https://julialang.org/downloads/manual-downloads/"
    }

    @Override
    String getName() {
        return "julia"
    }
}

class HsqldbDriverExecute extends DriverExecuteBase implements DriverExecute, Name, Url {
    @Override
    void execute(WebDriver driver) {
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
        driver.get(getUrl())
        def first = sortAndFirst(getHrefs(driver).findAll(getSearcher()))
        println first
    }

    Closure<Boolean> getSearcher() {
        return { href ->
            // println "🔗: ${href}"
            // https://github.com/grails/grails-forge/releases/download/v6.2.3/grails-cli-6.2.3.zip
            // https://github.com/apache/grails-forge/releases/download/v6.2.3/grails-cli-6.2.3.zip
            // https://www.apache.org/dyn/closer.lua/grails/core/7.0.4/distribution/apache-grails-7.0.4-bin.zip?action=download
            // https://www.apache.org/dyn/closer.lua/grails/core/7.0.7/distribution/apache-grails-7.0.7-bin.zip?action=download
            // https://dlcdn.apache.org/grails/core/7.0.7/distribution/apache-grails-7.0.7-bin.zip
            if (!(href.contains("/apache/grails-forge/releases/download/v") || href.contains("/dyn/closer.lua/grails/core"))) return false
            if (!href.contains("-bin.zip")) return false
            return true
        }
    }

    @Override
    String getUrl() {
        return "https://grails.apache.org/"
    }

    @Override
    String getName() {
        return "grails"
    }
}

class JenkinsDriverExecute extends DriverExecuteBase implements DriverExecute, Name, Url, Search {
    @Override
    void execute(WebDriver driver) {
        driver.get(getUrl())
        def first = sortAndFirst(getHrefs(driver).findAll(getSearcher()))
        println first
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
        driver.get(getUrl())
        def first = sortAndFirst(getHrefs(driver).findAll(getSearcher()))
        println first
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
        driver.get(getUrl())
        def last = sortAndLast(getHrefs(driver).findAll(getSearcher()))
        def version = last.split("mozilla/geckodriver/releases/tag/v")[1]
        println "https://github.com/mozilla/geckodriver/releases/download/v${version}/geckodriver-v${version}-linux64.tar.gz"
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
        driver.get(getUrl())
        def last = sortAndLast(getHrefs(driver).findAll(getSearcher()))
        def version = last.split("bazelbuild/bazel/releases/tag/")[1]
        println "https://github.com/bazelbuild/bazel/releases/download/${version}/bazel_nojdk-${version}-linux-x86_64"
    }

    Closure<Boolean> getSearcher() {
        return { href ->
            // https://github.com/bazelbuild/bazel/releases/tag/8.2.1
            href = href.toLowerCase()
            if (!href.contains("/bazelbuild/bazel/releases/tag/")) return false
            if (href.contains("rc")) return false
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
        driver.get(getUrl())
        def last = sortAndLast(getHrefs(driver).findAll(getSearcher()))
        def version = last.split("janet-lang/janet/releases/tag/v")[1]
        println "https://github.com/janet-lang/janet/releases/download/v${version}/janet-v${version}-linux-x64.tar.gz"
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
        driver.get(getUrl())
        def elements = driver.findElements(cssSelector("html body section#stable.status-ok p code"))
        if (!elements) {
            throw new RuntimeException("Stable version code element not found at ${getUrl()}")
        }
        def version = elements.first().getText()
        println "https://storage.googleapis.com/chrome-for-testing-public/${version}/linux64/chrome-linux64.zip"
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
        //TODO
        driver.get(getUrl())
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
        // https://dlcdn.apache.org/netbeans/netbeans/26/netbeans-26-bin.zip
        // https://netbeans.apache.org/front/main/download/nb28
        driver.get(getUrl())
        def first = sortAndFirst(getHrefs(driver).findAll(getSearcher()))
        def version = first.split("/apache/netbeans/releases/tag/")[1]
        println "https://dlcdn.apache.org/netbeans/netbeans/${version}/netbeans-${version}-bin.zip"
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
        driver.get(getUrl())
        def first = sortAndFirst(getHrefs(driver).findAll(getSearcher()))
        def version = first.split("/h2-")[1].replace(".jar", "")
        println "https://search.maven.org/remotecontent?filepath=com/h2database/h2/${version}/h2-${version}.jar"
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
        driver.get(getUrl())
        def last = sortAndLast(getHrefs(driver).findAll(getSearcher()))
        def version = last.split("argoproj/argo-workflows/releases/tag/v")[1]
        println "https://github.com/argoproj/argo-workflows/releases/download/v${version}/argo-linux-amd64.gz"
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

class MITMProxyDriverExecute extends DriverExecuteBase implements DriverExecute, Name, Url, Search {
    @Override
    void execute(WebDriver driver) {
        // https://downloads.mitmproxy.org/12.1.2/mitmproxy-12.1.2-linux-x86_64.tar.gz
        driver.get(getUrl())
        sleep(1000)
        def hrefs = getHrefs(driver)
        //println "🔗: ${hrefs}"
        hrefs = hrefs.findAll(getSearcher())
        //println "🔗: ${hrefs}"
        def last = sortAndLast(hrefs)
        def version = last.split("downloads/#")[1].replace("/", "")
        println "https://downloads.mitmproxy.org/${version}/mitmproxy-${version}-linux-x86_64.tar.gz"
    }

    Closure<Boolean> getSearcher() {
        return { href ->
            // https://www.mitmproxy.org/downloads/#12.1.2/
            href = href.toLowerCase()
            if (!href.contains("mitmproxy.org/downloads/#")) return false
            if (!href.endsWith("/")) return false
            return true
        }
    }

    @Override
    String getUrl() {
        return "https://www.mitmproxy.org/downloads/"
    }

    @Override
    String getName() {
        return "mitmproxy"
    }
}

class SolrDriverExecute extends DriverExecuteBase implements DriverExecute, Name, Url, Search {
    @Override
    void execute(WebDriver driver) {
        //https://dlcdn.apache.org/solr/solr/9.8.1/solr-9.8.1.tgz
        //https://dlcdn.apache.org/solr/solr/9.9.0/solr-9.9.0.tgz
        driver.get(getUrl())
        def last = sortAndLast(getHrefs(driver).findAll(getSearcher()))
        //println "🔗: ${last}"
        def version = last.split("/solr/solr/")[1].split("/")[0]//.replace("/", "")
        println "https://dlcdn.apache.org/solr/solr/${version}/solr-${version}.tgz"
    }

    Closure<Boolean> getSearcher() {
        return { href ->
            // println "🔗: ${href}"
            // https://www.apache.org/dyn/closer.lua/solr/solr/9.9.0/solr-9.9.0.tgz?action=download
            href = href.toLowerCase()
            if (!href.contains("/solr/solr")) return false
            if (!href.contains("solr-")) return false
            if (!href.contains(".tgz")) return false
            return true
        }
    }

    @Override
    String getUrl() {
        return "https://solr.apache.org/downloads.html"
    }

    @Override
    String getName() {
        return "solr"
    }
}

class LibreOfficeDriverExecute extends DriverExecuteBase implements DriverExecute, Name, Url, Search {

    @Override
    void execute(WebDriver driver) {
        //https://www.libreoffice.org/donate/dl/rpm-x86_64/25.8.1/en-US/LibreOffice_25.8.1_Linux_x86-64_rpm.tar.gz
        driver.get(getUrl())
        def hrefs = getHrefs(driver)
        // println "🔗: ${hrefs}"
        hrefs = hrefs.findAll(getSearcher())
        def last = sortAndLast(hrefs)
        // println "🔗: ${last}"
        def version = last.replace("_Linux_x86-64_rpm.tar.gz", "").split("/LibreOffice_")[1]
        println "https://www.libreoffice.org/donate/dl/rpm-x86_64/${version}/en-US/LibreOffice_${version}_Linux_x86-64_rpm.tar.gz"
    }

    Closure<Boolean> getSearcher() {
        return { href ->
            // println "🔗: ${href}"
            // https://www.libreoffice.org/donate/dl/win-x86_64/26.2.0/en-US/LibreOffice_26.2.0_Win_x86-64.msi
            // https://www.libreoffice.org/donate/dl/rpm-x86_64/25.8.1/en-US/LibreOffice_25.8.1_Linux_x86-64_rpm.tar.gz
            return (href.contains("/rpm-x86_64/") || href.contains("/win-x86_64/"))
                && href.contains("/en-US/LibreOffice_")
                && (href.endsWith(".tar.gz") || href.endsWith(".msi"))
        }
    }

    @Override
    String getUrl() {
        return "https://www.libreoffice.org/download/download-libreoffice/"
    }

    @Override
    String getName() {
        return "libreoffice"
    }
}

class MvndDriverExecute extends DriverExecuteBase implements DriverExecute, Name, Url, Search {
    @Override
    void execute(WebDriver driver) {
        driver.get(getUrl())
        def hrefs = getHrefs(driver)
        def filtered = hrefs.findAll(getSearcher())
        if (!filtered) {
             // Fallback if full URLs are not present (GitHub sometimes uses relative links)
             filtered = hrefs.findAll { it.contains("/apache/maven-mvnd/releases/tag/") }.collect { it.startsWith("/") ? "https://github.com" + it : it }.findAll(getSearcher())
        }
        def last = sortAndLast(filtered)
        def version = last.split("maven-mvnd/releases/tag/")[1]
        // https://github.com/apache/maven-mvnd/releases/download/1.0.3/maven-mvnd-1.0.3-linux-amd64.tar.gz
        println "https://github.com/apache/maven-mvnd/releases/download/${version}/maven-mvnd-${version}-linux-amd64.tar.gz"
    }

    Closure<Boolean> getSearcher() {
        return { href ->
            // https://github.com/apache/maven-mvnd/releases/tag/1.0.3
            if (!href.contains("/apache/maven-mvnd/releases/tag/")) return false
            def lower = href.toLowerCase()
            if (lower.contains("-m") || lower.contains("-alpha") || lower.contains("-beta") || lower.contains("-rc")) return false
            return true
        }
    }

    @Override
    String getUrl() {
        return "https://github.com/apache/maven-mvnd/releases"
    }

    @Override
    String getName() {
        return "mvnd"
    }
}

class CmDriverExecute extends DriverExecuteBase implements DriverExecute, Name, Url, Search {
    @Override
    void execute(WebDriver driver) {
        driver.get(getUrl())
        def last = sortAndLast(getHrefs(driver).findAll(getSearcher()))
        def version = last.split("camunda-modeler/releases/tag/v")[1]
        println "https://github.com/camunda/camunda-modeler/releases/download/v${version}/camunda-modeler-${version}-linux-x64.tar.gz"
    }

    Closure<Boolean> getSearcher() {
        return { href ->
            // https://github.com/camunda/camunda-modeler/releases/tag/v5.32.0
            href = href.toLowerCase()
            if (!href.contains("/camunda/camunda-modeler/releases/tag/v")) return false
            return true
        }
    }

    @Override
    String getUrl() {
        return "https://github.com/camunda/camunda-modeler/releases"
    }

    @Override
    String getName() {
        return "cm"
    }
}

class GitFlowNextDriverExecute extends DriverExecuteBase implements DriverExecute, Name, Url, Search {
    @Override
    void execute(WebDriver driver) {
        driver.get(getUrl())
        def hrefs = getHrefs(driver)
        def filtered = hrefs.findAll(getSearcher())
        if (!filtered) {
             filtered = hrefs.findAll { it.contains("/gittower/git-flow-next/releases/tag/") }.collect { it.startsWith("/") ? "https://github.com" + it : it }.findAll(getSearcher())
        }
        def last = sortAndLast(filtered)
        def version = last.split("git-flow-next/releases/tag/")[1]
        println "https://github.com/gittower/git-flow-next/releases/download/${version}/git-flow-next-${version}-linux-amd64.tar.gz"
    }

    Closure<Boolean> getSearcher() {
        return { href ->
            // "https://github.com/gittower/git-flow-next/tag/0.4.0
            // https://github.com/gittower/git-flow-next/releases/download/v1.0.0/git-flow-next-v1.0.0-linux-amd64.tar.gz
            if (!href.contains("/gittower/git-flow-next/releases/tag/")) return false
            return true
        }
    }

    @Override
    String getUrl() {
        return "https://github.com/gittower/git-flow-next/releases"
    }

    @Override
    String getName() {
        return "git-flow-next"
    }
}

class GraphvizDriverExecute extends DriverExecuteBase implements DriverExecute, Name, Url, Search {
    @Override
    void execute(WebDriver driver) {
        driver.get(getUrl())
        def first = sortAndFirst(getHrefs(driver).findAll(getSearcher()))
        println first
    }

    Closure<Boolean> getSearcher() {
        return { href ->
            // https://gitlab.com/api/v4/projects/4207231/packages/generic/graphviz-releases/12.2.1/windows_10_cmake_Release_graphviz-install-12.2.1-win64.exe
            href = href.toLowerCase()
            if (!href.contains("/packages/generic/graphviz-releases/")) return false
            if (!href.endsWith("-win64.exe")) return false
            return true
        }
    }

    @Override
    String getUrl() {
        return "https://graphviz.org/download/"
    }

    @Override
    String getName() {
        return "graphviz"
    }
}

class InnosetupDriverExecute extends DriverExecuteBase implements DriverExecute, Name, Url, Search {
    @Override
    void execute(WebDriver driver) {
        driver.get(getUrl())
        def first = sortAndFirst(getHrefs(driver).findAll(getSearcher()))
        println first
    }

    Closure<Boolean> getSearcher() {
        return { href ->
            // https://jrsoftware.org/download.php/is.exe
            if (href.endsWith("is.exe")) return true
            return false
        }
    }

    @Override
    String getUrl() {
        return "https://jrsoftware.org/isdl.php"
    }

    @Override
    String getName() {
        return "innosetup"
    }
}

class NsisDriverExecute extends DriverExecuteBase implements DriverExecute, Name, Url, Search {
    @Override
    void execute(WebDriver driver) {
        driver.get(getUrl())
        def first = sortAndFirst(getHrefs(driver).findAll(getSearcher()))
        println first
    }

    Closure<Boolean> getSearcher() {
        return { href ->
            // https://prdownloads.sourceforge.net/nsis/nsis-3.11-setup.exe?download
            // https://unlimited.dl.sourceforge.net/project/nsis/NSIS%203/3.11/nsis-3.11-setup.exe?viasf=1
            if (!href.toLowerCase().contains("/nsis/nsis-")) return false
            if (!href.toLowerCase().endsWith("-setup.exe?download")) return false
            return true
        }
    }

    @Override
    String getUrl() {
        return "https://nsis.sourceforge.io/Download"
    }

    @Override
    String getName() {
        return "nsis"
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
            rulesRegister.rulesMap.each { entry ->
                def rule = entry.value
                def name = (rule as Name).getName()
                def url = (rule as Url).getUrl()
                try {
                    rule.execute(firefox.getDriver())
                } catch (Exception e) {
                    println "❌ Error [${name}] from ${url}: ${e.message}"
                }
            }
        } else {
            cliArgs.getPackageNames().each { name ->
                def rule = requireNonNull(rulesRegister[name], "❌ Missing rule: '${name}'")
                def url = (rule as Url).getUrl()
                try {
                    rule.execute(firefox.getDriver())
                } catch (Exception e) {
                    println "❌ Error [${name}] from ${url}: ${e.message}"
                }
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
    fillWithRules(new MITMProxyDriverExecute(), rulesRegister)
    fillWithRules(new SolrDriverExecute(), rulesRegister)
    fillWithRules(new LibreOfficeDriverExecute(), rulesRegister)
    fillWithRules(new MvndDriverExecute(), rulesRegister)
    fillWithRules(new CmDriverExecute(), rulesRegister)
    fillWithRules(new GitFlowNextDriverExecute(), rulesRegister)
    fillWithRules(new GraphvizDriverExecute(), rulesRegister)
    fillWithRules(new InnosetupDriverExecute(), rulesRegister)
    fillWithRules(new NsisDriverExecute(), rulesRegister)
    return rulesRegister
}

static RulesRegister fillWithRules(DriverExecute driverExecute, RulesRegister rulesRegister) {
    rulesRegister[(driverExecute as Name).getName()] = driverExecute
    return rulesRegister
}
