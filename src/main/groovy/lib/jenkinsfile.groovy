#!/usr/bin/env groovy
import org.codehaus.groovy.ast.ClassCodeExpressionTransformer
import org.codehaus.groovy.ast.ClassNode
import org.codehaus.groovy.ast.expr.ClosureExpression
import org.codehaus.groovy.ast.expr.Expression
import org.codehaus.groovy.ast.expr.MethodCallExpression
import org.codehaus.groovy.classgen.GeneratorContext
import org.codehaus.groovy.control.CompilePhase
import org.codehaus.groovy.control.CompilerConfiguration
import org.codehaus.groovy.control.SourceUnit
import org.codehaus.groovy.control.customizers.CompilationCustomizer
import picocli.CommandLine
import picocli.CommandLine.Command
import picocli.CommandLine.Option
import picocli.CommandLine.Parameters

@Grab(group = 'info.picocli', module = 'picocli', version = '4.7.7')

// smi-jenkinsfile ../jenkinsfile-starter/Jenkinsfile
// smi-jenkinsfile -b release/1.2.0 ../jenkinsfile-starter/Jenkinsfile
// smi-jenkinsfile -b hotfix/NPE -e MASTER_TO_LIVE=SKIP ../jenkinsfile-starter/Jenkinsfile

/*
 * A minimal Jenkins declarative pipeline runner: it executes a Jenkinsfile on the
 * local machine, without Jenkins.
 *
 * How the DSL works - this is all there is to it:
 *
 *   pipeline { stages { stage('Build') { steps { echo 'hi' } } } }
 *
 * is plain Groovy: a method call `pipeline(Closure)` whose closure contains a call
 * `stages(Closure)` and so on. The closures are not executed where they are written -
 * they are handed over, and the runner decides *who* answers the calls inside them:
 *
 *   1. the closure is cloned  (the original stays reusable)
 *   2. its delegate is set to a small "block" object that knows the directives
 *      allowed at that nesting level  (StagesBlock knows `stage`, WhenBlock knows
 *      `branch` and `expression`, ...)
 *   3. its resolveStrategy is set to DELEGATE_FIRST, so the block is asked first and
 *      everything it does not know (`echo`, `runCommand`, `env`) falls through to the
 *      Jenkinsfile script itself
 *   4. the closure is called - and every call inside it lands on the block, which just
 *      records it into the model (Pipeline / Stage)
 *
 * Steps (`echo`, `sh`, `retry`, ...) are methods of PipelineScript, the base class the
 * Jenkinsfile is compiled against - that is Jenkins' "global variables" in miniature.
 *
 * `steps { }`, `expression { }` and the `post` sections are *stored* as closures and
 * called later, when the stage actually runs, exactly like Jenkins does it.
 *
 * Only what the jenkinsfile-starter Jenkinsfile uses is implemented. Everything else
 * is reported and skipped instead of failing the build (see methodMissing).
 */

interface Name {
    String getName()
}

interface Executable {
    void execute()
}

@Command(name = "smi-jenkinsfile", description = "Run a Jenkins declarative Jenkinsfile locally")
class CliArgs {

    @Parameters(index = "0", arity = "0..1", description = "Jenkinsfile to run (default: ./Jenkinsfile)")
    File jenkinsfile = new File("Jenkinsfile")

    @Option(names = ["--branch", "-b"], description = "Value of env.BRANCH_NAME (default: master)")
    String branch = "master"

    @Option(names = ["--env", "-e"], description = "Extra environment variable, wins over the environment block: -e KEY=VALUE")
    Map<String, String> extraEnv = [:]

    @Option(names = ["--help", "-h"], usageHelp = true, description = "Show this help")
    boolean help

    CommandLine commandLine

    CliArgs parseArgs(String[] args) {
        commandLine = new CommandLine(this)
        commandLine.parseArgs(args)
        this
    }
}

/**
 * Jenkins writes a "[Pipeline] <step>" line before every step and prefixes the output of
 * parallel branches with the branch name. Same here, so the log looks familiar.
 */
class Console {
    static final ThreadLocal<String> BRANCH = new ThreadLocal<String>()

    static synchronized void out(String message) {
        def branch = BRANCH.get()
        println branch ? "[${branch}] ${message}" : message
    }

    static void step(String name) {
        out("[Pipeline] ${name}")
    }

    static void open(String name) {
        out("[Pipeline] { (${name})")
    }

    static void close() {
        out("[Pipeline] }")
    }
}

/**
 * Groovy adds sleep(long) - milliseconds - to every object, and inside a closure the
 * closure itself answers it before the delegate is ever asked, whatever the resolve
 * strategy is. So `sleep 5` written in a `steps { }` block could never reach the step.
 *
 * This customizer renames those calls to `sleepStep(5)` while the Jenkinsfile is being
 * compiled - the one moment where the name is still free - and PipelineScript.sleepStep
 * then implements Jenkins' semantics: seconds, and a line in the log.
 */
class SleepRewriter extends CompilationCustomizer {

    SleepRewriter() {
        super(CompilePhase.CANONICALIZATION)
    }

    @Override
    void call(SourceUnit source, GeneratorContext context, ClassNode classNode) {
        def transformer = new ClassCodeExpressionTransformer() {

            @Override
            protected SourceUnit getSourceUnit() {
                source
            }

            @Override
            Expression transform(Expression expression) {
                if (expression == null) {
                    return null
                }
                // transformExpression() does not step into the body of a closure, and the
                // body is exactly where the Jenkinsfile writes its steps.
                if (expression instanceof ClosureExpression) {
                    expression.code.visit(this)
                    return expression
                }
                if (expression instanceof MethodCallExpression
                    && expression.implicitThis
                    && expression.methodAsString == "sleep") {
                    def call = new MethodCallExpression(
                        expression.objectExpression, "sleepStep", transform(expression.arguments))
                    call.implicitThis = true
                    return call
                }
                expression.transformExpression(this)
            }
        }
        classNode.methods.each { transformer.visitMethod(it) }
    }
}

/** Thrown by the `error` step and by a failing `sh`: it fails the build. */
class AbortException extends RuntimeException {
    AbortException(String message) {
        super(message)
    }
}

/** The state of one build: its environment, its workspace and its result. */
class Build {
    Map<String, String> env = [:]
    Map<String, String> overrides = [:]
    File workspace
    String result = "SUCCESS"
}

/** One stage of the model. It has either `steps` or parallel `branches`, never both. */
class Stage implements Name {
    String name
    List<Closure<Boolean>> conditions = []
    Closure steps
    List<Stage> branches = []
}

/** The whole model, as collected from the Jenkinsfile before anything is executed. */
class Pipeline {
    String agent = "none"
    List<String> triggers = []
    List<String> options = []
    Map<String, String> environment = [:]
    List<Stage> stages = []
    Map<String, Closure> post = [:]
}

/**
 * Base of every DSL block: a block is the delegate of one closure of the Jenkinsfile and
 * turns the calls written inside that closure into model objects.
 */
abstract class Block {
    Build build

    /** Clone the closure, point it at the block, call it, hand the filled block back. */
    static <T extends Block> T dsl(T block, Closure body) {
        Closure copy = (Closure) body.clone()
        copy.delegate = block
        copy.resolveStrategy = Closure.DELEGATE_FIRST
        copy.call()
        block
    }

    /** `env.BRANCH_NAME` inside any block or step. */
    Map<String, String> getEnv() {
        build.env
    }
}

class PipelineBlock extends Block {
    Pipeline pipeline = new Pipeline()

    String getAny() {
        "any"
    }

    String getNone() {
        "none"
    }

    void agent(Object agent) {
        pipeline.agent = String.valueOf(agent)
    }

    void triggers(Closure body) {
        pipeline.triggers = dsl(new TriggersBlock(build: build), body).triggers
    }

    void options(Closure body) {
        pipeline.options = dsl(new OptionsBlock(build: build), body).options
    }

    void environment(Closure body) {
        pipeline.environment = dsl(new EnvironmentBlock(build: build), body).variables
    }

    void stages(Closure body) {
        pipeline.stages = dsl(new StagesBlock(build: build), body).stages
    }

    void post(Closure body) {
        pipeline.post = dsl(new PostBlock(build: build), body).sections
    }
}

/** Triggers are only reported: nothing schedules this runner. */
class TriggersBlock extends Block {
    List<String> triggers = []

    void cron(String spec) {
        triggers << "cron('${spec}')"
    }

    void pollSCM(String spec) {
        triggers << "pollSCM('${spec}')"
    }
}

/**
 * Options are only reported. methodMissing records any option that is written, whatever
 * its name is; a nested call (logRotator inside buildDiscarder) is recorded first and
 * then folded into its caller.
 */
class OptionsBlock extends Block {
    List<String> options = []

    def methodMissing(String name, Object args) {
        def values = (args as Object[]).collect { String.valueOf(it) }
        options.removeAll(values)
        def option = "${name}(${values.join(', ')})".toString()
        options << option
        option
    }
}

/**
 * `ABC = 'DEF'` is an assignment to an unknown property, so it lands in propertyMissing.
 * `GHI = "$ABC"` is resolved right here, in order, because the closure is executed
 * top to bottom - which is why the getter reads back what was already assigned.
 */
class EnvironmentBlock extends Block {
    Map<String, String> variables = [:]

    void propertyMissing(String name, Object value) {
        variables[name] = String.valueOf(value)
    }

    def propertyMissing(String name) {
        variables.containsKey(name) ? variables[name] : build.env[name]
    }
}

/** Used for both `stages { }` and `parallel { }`: both contain nothing but stages. */
class StagesBlock extends Block {
    List<Stage> stages = []

    void stage(String name, Closure body) {
        stages << dsl(new StageBlock(build: build, stage: new Stage(name: name)), body).stage
    }
}

class StageBlock extends Block {
    Stage stage

    void steps(Closure body) {
        stage.steps = body
    }

    void when(Closure body) {
        stage.conditions = dsl(new WhenBlock(build: build), body).conditions
    }

    void parallel(Closure body) {
        stage.branches = dsl(new StagesBlock(build: build), body).stages
    }

    void agent(Object agent) {
    }
}

/** Every condition of a `when` block must hold for the stage to run. */
class WhenBlock extends Block {
    List<Closure<Boolean>> conditions = []

    void branch(String pattern) {
        def regex = pattern.split("\\*", -1).collect { java.util.regex.Pattern.quote(it) }.join(".*")
        conditions << { build.env.BRANCH_NAME ==~ regex }
    }

    void expression(Closure<Boolean> condition) {
        conditions << condition
    }
}

class PostBlock extends Block {
    Map<String, Closure> sections = [:]

    void always(Closure body) {
        sections.always = body
    }

    void success(Closure body) {
        sections.success = body
    }

    void failure(Closure body) {
        sections.failure = body
    }
}

/** Walks the collected model and calls the closures that were stored while collecting it. */
class Executor implements Executable {
    Build build
    Pipeline pipeline
    PipelineScript script

    @Override
    void execute() {
        Console.out("Running on ${build.env.NODE_NAME} in ${build.workspace}")
        Console.out("agent ${pipeline.agent}")
        pipeline.triggers.each { Console.out("trigger ${it}") }
        pipeline.options.each { Console.out("option ${it}") }
        try {
            pipeline.stages.each { executeStage(it) }
        } catch (Throwable throwable) {
            build.result = "FAILURE"
            Console.out("ERROR: ${throwable.message}")
        }
        executePost()
        Console.out("Finished: ${build.result}")
    }

    private void executeStage(Stage stage) {
        if (!stage.conditions.every { script.callBody(it) }) {
            Console.out("Stage \"${stage.name}\" skipped due to when conditional")
            return
        }
        Console.step("stage")
        Console.open(stage.name)
        try {
            if (stage.branches) {
                executeBranches(stage)
            } else if (stage.steps) {
                script.callBody(stage.steps)
            }
        } finally {
            Console.close()
        }
    }

    /** Real threads, one per branch; the first failure fails the whole stage. */
    private void executeBranches(Stage stage) {
        Console.step("parallel")
        def failures = Collections.synchronizedList(new ArrayList<Throwable>())
        stage.branches.collect { branch ->
            Thread.start {
                Console.BRANCH.set(branch.name)
                try {
                    executeStage(branch)
                } catch (Throwable throwable) {
                    failures << throwable
                } finally {
                    Console.BRANCH.remove()
                }
            }
        }*.join()
        if (failures) {
            throw failures.first()
        }
    }

    private void executePost() {
        ["always", build.result == "SUCCESS" ? "success" : "failure"].each { section ->
            def body = pipeline.post[section]
            if (!body) {
                return
            }
            Console.step("post ${section}")
            try {
                script.callBody(body)
            } catch (Throwable throwable) {
                Console.out("ERROR in post ${section}: ${throwable.message}")
            }
        }
    }
}

/**
 * The Jenkinsfile is compiled against this class, so everything declared here is
 * callable from the Jenkinsfile without an import: `pipeline` plus all the steps.
 */
abstract class PipelineScript extends Script {

    Build build

    def pipeline(Closure body) {
        def model = Block.dsl(new PipelineBlock(build: build), body).pipeline
        build.env.putAll(model.environment)
        build.env.putAll(build.overrides)
        // Now that the environment is known, publish it so that "$JOB_NAME" and "${GHI}"
        // written directly in the Jenkinsfile resolve, and so that env.X works.
        build.env.each { key, value -> binding.setVariable(key, value) }
        binding.setVariable("env", build.env)
        new Executor(build: build, pipeline: model, script: this).execute()
        build.result
    }

    /**
     * Every stored body - steps, script, retry, timeout, post, expression - is executed
     * with this script as its DELEGATE_FIRST delegate, so that a step call lands on the
     * script directly. Without it the call is offered to the enclosing closure first, and
     * DefaultGroovyMethods answers on behalf of any object for names like `sleep`.
     */
    Object callBody(Closure body) {
        Closure copy = (Closure) body.clone()
        copy.delegate = this
        copy.resolveStrategy = Closure.DELEGATE_FIRST
        copy.call()
    }

    void echo(Object message) {
        Console.step("echo")
        Console.out(String.valueOf(message))
    }

    boolean isUnix() {
        !System.getProperty("os.name").toLowerCase().contains("win")
    }

    void sh(String command) {
        Console.step("sh")
        shell(["sh", "-c", command], command)
    }

    void bat(String command) {
        Console.step("bat")
        shell(["cmd", "/c", command], command)
    }

    /** The build environment is passed to the process, so 'echo "${GHI}"' expands there. */
    private void shell(List<String> commandLine, String command) {
        Console.out("+ ${command}")
        def builder = new ProcessBuilder(commandLine)
        builder.directory(build.workspace)
        builder.environment().putAll(build.env)
        builder.redirectErrorStream(true)
        def process = builder.start()
        process.inputStream.newReader().eachLine { Console.out(it) }
        def exitCode = process.waitFor()
        if (exitCode != 0) {
            throw new AbortException("script returned exit code ${exitCode}")
        }
    }

    def script(Closure body) {
        Console.step("script")
        callBody(body)
    }

    boolean fileExists(String path) {
        Console.step("fileExists")
        new File(build.workspace, path).exists()
    }

    void error(String message) {
        Console.step("error")
        throw new AbortException(message)
    }

    void sleepStep(Number seconds) {
        Console.step("sleep")
        Console.out("Sleeping for ${seconds} sec")
        Thread.sleep((long) (seconds.doubleValue() * 1000L))
    }

    def retry(Map args, Closure body) {
        Console.step("retry")
        int count = args.count as int
        for (int attempt = 1; ; attempt++) {
            try {
                return callBody(body)
            } catch (Throwable throwable) {
                if (attempt >= count) {
                    throw throwable
                }
                Console.out("Retrying (${attempt}/${count - 1}): ${throwable.message}")
            }
        }
    }

    /** Simplification: the body is not interrupted, only its duration is checked afterwards. */
    def timeout(Map args, Closure body) {
        Console.step("timeout")
        long limit = (args.time as Number).longValue() * unitMillis(args.unit)
        long started = System.currentTimeMillis()
        def result = callBody(body)
        long elapsed = System.currentTimeMillis() - started
        if (elapsed > limit) {
            throw new AbortException("Timeout has been exceeded: ${elapsed} ms > ${limit} ms")
        }
        result
    }

    private static long unitMillis(Object unit) {
        switch (String.valueOf(unit ?: "MINUTES")) {
            case "SECONDS": return 1000L
            case "HOURS": return 3600000L
            default: return 60000L
        }
    }

    void emailext(Map args) {
        Console.step("emailext")
        Console.out("Sending e-mail to ${args.to ?: args.recipientProviders}")
        Console.out("  subject: ${args.subject}")
        Console.out("  body:    ${args.body}")
    }

    /** Steps this small runner does not implement are reported, not failed. */
    def methodMissing(String name, Object args) {
        Console.step(name)
        Console.out("Step '${name}' is not implemented by this runner, skipped")
        null
    }
}

static void main(String[] args) {
    final CliArgs cliArgs = new CliArgs().parseArgs(args)
    if (cliArgs.help) {
        cliArgs.commandLine.usage(System.out)
        return
    }
    final File jenkinsfile = cliArgs.jenkinsfile
    if (!jenkinsfile.isFile()) {
        println "❌ Missing Jenkinsfile: ${jenkinsfile}"
        System.exit(1)
    }
    final Build build = newBuild(jenkinsfile, cliArgs)
    final CompilerConfiguration configuration = new CompilerConfiguration()
    configuration.scriptBaseClass = PipelineScript.name
    configuration.addCompilationCustomizers(new SleepRewriter())
    final GroovyShell shell = new GroovyShell(PipelineScript.classLoader, new Binding(), configuration)
    final PipelineScript pipelineScript = (PipelineScript) shell.parse(jenkinsfile)
    pipelineScript.build = build
    pipelineScript.run()
    if (build.result != "SUCCESS") {
        System.exit(1)
    }
}

static Build newBuild(File jenkinsfile, CliArgs cliArgs) {
    final File workspace = jenkinsfile.canonicalFile.parentFile
    final Build build = new Build(workspace: workspace)
    build.env.putAll([
        NODE_NAME   : "built-in",
        WORKSPACE   : workspace.path,
        JOB_NAME    : workspace.name,
        BUILD_NUMBER: "1",
        BUILD_URL   : "http://localhost:8080/job/${workspace.name}/1/".toString(),
        BRANCH_NAME : cliArgs.branch,
        GIT_BRANCH  : "origin/${cliArgs.branch}".toString(),
        GIT_URL     : gitUrl(workspace)
    ])
    build.env.putAll(cliArgs.extraEnv)
    build.overrides.putAll(cliArgs.extraEnv)
    build
}

static String gitUrl(File workspace) {
    try {
        def process = new ProcessBuilder("git", "config", "--get", "remote.origin.url")
            .directory(workspace)
            .start()
        def url = process.inputStream.text.trim()
        process.waitFor()
        url
    } catch (Exception exception) {
        ""
    }
}
