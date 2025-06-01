#!/usr/bin/env groovy
import org.openqa.selenium.By
import org.openqa.selenium.WebDriver
import org.openqa.selenium.firefox.FirefoxDriver
import org.openqa.selenium.firefox.FirefoxOptions
import org.yaml.snakeyaml.Yaml
import picocli.CommandLine
import picocli.CommandLine.Option

@Grab(group = 'org.seleniumhq.selenium', module = 'selenium-api', version = '4.33.0')
@Grab(group = 'org.seleniumhq.selenium', module = 'selenium-http', version = '4.33.0')
@Grab(group = 'org.seleniumhq.selenium', module = 'selenium-support', version = '4.33.0')
@Grab(group = 'org.seleniumhq.selenium', module = 'selenium-firefox-driver', version = '4.33.0')
@Grab(group = 'org.yaml', module = 'snakeyaml', version = '2.4')
@Grab(group = 'com.google.errorprone', module = 'error_prone_annotations', version = '2.38.0')
@Grab(group = 'info.picocli', module = 'picocli', version = '4.7.7')
//@Grab(group = 'org.seleniumhq.selenium', module = 'selenium-java', version = '4.33.0')


// ./seleniumVersionChecker.sh --input seleniumVersionChecker.yaml --output seleniumVersionChecker.csv
class CliArgs {

    @Option(names = ["--name"], description = "Package name", required = false)
    String packageName

    @Option(names = ["--input"], description = "YAML config file", required = false)
    String configFile

    @Option(names = ["--output"], description = "Output CSV file", required = false)
    String outputFile
}

class InputData {

}

static void main(String[] args) {
    def cliArgs = new CliArgs()
    new CommandLine(cliArgs).parseArgs(args)

    def yaml = new Yaml()
    def config = yaml.load(new File(cliArgs.configFile).text)
    /*
    def url = config.url ?: "https://maven.apache.org/download.cgi"
    def packageExtension = config.extension ?: ".tar.gz"
    def includePattern = config.includePattern ?: "apache-maven-"
    def excludePattern = config.excludePattern ?: "rc"
    */

    def osName = System.getProperty("os.name").toLowerCase()
    def geckoDriverPath = ""
    def firefoxBinaryPath = ""

    if (osName.contains("win")) {
        geckoDriverPath = "C:\\pub\\setmy.info\\lib\\geckodriver.exe"
        firefoxBinaryPath = "C:\\Program Files\\Mozilla Firefox\\firefox.exe"
    } else if (osName.contains("mac")) {
        geckoDriverPath = "/usr/local/bin/geckodriver"
        firefoxBinaryPath = "/Applications/Firefox.app/Contents/MacOS/firefox"
    } else if (osName.contains("nix") || osName.contains("nux") || osName.contains("aix")) {
        geckoDriverPath = "/opt/setmy.info/bin/geckodriver"
        firefoxBinaryPath = "/opt/firefox/firefox"
    } else {
        throw new RuntimeException("Unsupported OS: $osName")
    }

    def packageExtensions = [
        ".tar", ".tar.gz", ".tgz", ".tar.bz2", ".tbz2", ".tar.xz", ".txz", ".tar.Z",
        ".zip", ".gz", ".bz2", ".xz", ".7z",
        ".deb", ".rpm",
        ".run", ".sh", ".bin",
        ".appimage",
        ".jar",
        ".dmg",
        ".exe"
    ]

    def options = new FirefoxOptions()
    options.setBinary(firefoxBinaryPath)
    System.setProperty("webdriver.gecko.driver", geckoDriverPath);
    WebDriver driver = new FirefoxDriver(options);

    try {
        def url = "https://maven.apache.org/download.cgi"
        driver.get(url)
        println "✅ Page loaded: ${url}"

        def links = driver.findElements(By.tagName("a"))
        def hrefs = links.collect { it.getAttribute("href") }.findAll { it != null }

        def filteredHrefs = hrefs.findAll { href ->
            packageExtensions.any { ext ->
                href.toLowerCase().endsWith(ext)
            }
        }

        println "🔗 Found links:"
        filteredHrefs.each { println it }

        String packageExtension = ".tar.gz"
        def versionPattern = ~/(?<![a-zA-Z0-9])(\d+\.\d+\.\d+)(?![a-zA-Z0-9])/

        def finalFiltered = filteredHrefs.findAll { href ->
            href = href.toLowerCase()
            if (!href.endsWith(packageExtension)) return false
            if (!href.contains("apache-maven-")) return false
            if (href.contains("rc")) return false

            def matcher = (href =~ versionPattern)
            if (!matcher.find()) return false
            //def version = matcher.group(1)
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
        println "❌ Viga: ${e.message}"
    } finally {
        driver.quit()
    }
}
