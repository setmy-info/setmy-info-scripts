#!/usr/bin/env groovy

// EXPERIMENT!!!

@Grab(group='org.seleniumhq.selenium', module='selenium-java', version='4.33.0')
@Grab(group='org.seleniumhq.selenium', module='selenium-firefox-driver', version='4.33.0')
@Grab(group='org.yaml', module='snakeyaml', version='2.4')

import org.openqa.selenium.WebDriver;
import org.openqa.selenium.firefox.FirefoxDriver
import org.openqa.selenium.firefox.FirefoxOptions
import org.openqa.selenium.JavascriptExecutor
import org.yaml.snakeyaml.Yaml
import java.util.regex.Pattern

// C:\pub\setmy.info\lib
// geckodriver.exe

class InputData {

}

static void main(String[] args) {
    def options = new FirefoxOptions()
    options.setBinary("C:\\Program Files\\Mozilla Firefox\\firefox.exe")
    System.setProperty("webdriver.gecko.driver", "C:\\pub\\setmy.info\\lib\\geckodriver.exe");
    WebDriver driver = new FirefoxDriver(options);

    driver.quit()
    def inputData = new InputData()
    println "Hello World"
}
