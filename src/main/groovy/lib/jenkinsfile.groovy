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

    /** Width of the banner lines, so that every "Begin of" marker lines up. */
    static final int WIDTH = 110

    static synchronized void out(String message) {
        def branch = BRANCH.get()
        println branch ? "[${branch}] ${message}" : message
    }

    static void step(String name) {
        out("[Pipeline] ${name}")
    }

    /**
     * The marker that says where execution is and whether the stage ran:
     *
     *   ------------------- Begin of 'Build' DO -------------------
     *   ------------------- Begin of 'Tag' SKIP -------------------
     *
     * Nested (parallel) stages are indented, so the tree is visible in the log.
     */
    static void stage(String position, String name, String decision, int depth) {
        fill("-", "${position} of '${name}' ${decision}", "  " * depth)
    }

    /** A heavier banner, used for the pipeline itself and for the closing summary. */
    static void banner(String title) {
        fill("=", title, "")
    }

    private static void fill(String character, String title, String indent) {
        def label = " ${title} "
        def width = Math.max(0, WIDTH - indent.length() - label.length())
        def left = Math.max(3, (int) (width / 2))
        def right = Math.max(3, width - left)
        out(indent + (character * left) + label + (character * right))
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

/**
 * SMI_JENKINSFILE_DEPLOY switches the steps of the Publish and Deploy stages on.
 * true, yes, on or 1 runs them; anything else, including unset, does not. Off by default,
 * because this runner executes `sh` for real.
 */
class Deployment {
    static final String VARIABLE = "SMI_JENKINSFILE_DEPLOY"
    static final List<String> STAGES = ["publish", "deploy"]

    private static final List<String> ON = ["true", "yes", "on", "1"]

    static boolean enabled(Build build) {
        String value = build.env[VARIABLE]
        value != null && ON.contains(value.trim().toLowerCase())
    }

    static boolean blocks(Build build, String stageName) {
        !enabled(build) && STAGES.contains(String.valueOf(stageName).trim().toLowerCase())
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
    /** The running Jenkinsfile, so that a nested `when` block can evaluate its conditions. */
    PipelineScript script
}

/** One stage of the model. It has either `steps` or parallel `branches`, never both. */
class Stage implements Name {
    /** What the runner decided to do with a stage; also what the closing summary prints. */
    static final String DO = "DO"
    static final String SKIP = "SKIP"
    static final String NOT_RUN = "NOT RUN"
    /** Ran, but a `when` directive this runner does not understand was ignored to get there. */
    static final String DO_UNSURE = "DO (?)"
    /** Its `when` said run, but SMI_JENKINSFILE_DEPLOY is off. See Deployment. */
    static final String BLOCKED = "BLOCKED"

    String name
    List<Closure<Boolean>> conditions = []
    /** Names of `when` directives this runner does not implement; empty means the decision is exact. */
    List<String> unsupported = []
    Closure steps
    /** Nested stages: at the same time when `parallel` is set, one after another otherwise. */
    List<Stage> children = []
    boolean parallel
    Map<String, String> environment = [:]
    Map<String, Closure> post = [:]
    /** Filled in while the stage is executed, so the summary can be printed in declaration order. */
    String decision = NOT_RUN
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

    /** `failFast true` and anything else written beside the stages, reported not leaked. */
    def methodMissing(String name, Object args) {
        Console.out("WARNING: '${name}' is not implemented by this runner and was ignored")
        null
    }
}

class StageBlock extends Block {
    Stage stage

    void steps(Closure body) {
        stage.steps = body
    }

    void when(Closure body) {
        def block = (WhenBlock) dsl(new WhenBlock(build: build), body)
        stage.conditions = block.conditions
        stage.unsupported = block.unsupported
    }

    /** `parallel { }` - the nested stages run at the same time. */
    void parallel(Closure body) {
        stage.children = dsl(new StagesBlock(build: build), body).stages
        stage.parallel = true
    }

    /** `stages { }` inside a stage - the nested stages run one after another. */
    void stages(Closure body) {
        stage.children = dsl(new StagesBlock(build: build), body).stages
        stage.parallel = false
    }

    /**
     * A stage level `environment` and `post` have to be caught here. Without these two methods
     * the call is not answered by this block, so Groovy walks the owner chain of the closure up
     * to PipelineBlock - which does have both - and the stage's block silently becomes the
     * *pipeline's* environment or post section instead. It then runs at the wrong level, and
     * looks like it worked.
     */
    void environment(Closure body) {
        stage.environment = dsl(new EnvironmentBlock(build: build), body).variables
    }

    void post(Closure body) {
        stage.post = dsl(new PostBlock(build: build), body).sections
    }

    void agent(Object agent) {
    }

    /** Same reason: an unimplemented directive is reported here instead of leaking upwards. */
    def methodMissing(String name, Object args) {
        Console.out("WARNING: stage directive '${name}' is not implemented by this runner and was ignored")
        null
    }
}

/**
 * Every condition of a `when` block must hold for the stage to run - `when` ANDs its
 * directives, and `anyOf` / `allOf` / `not` nest another `when` block inside one condition.
 *
 * A directive this runner does not know must never be silently dropped: an empty condition
 * list passes, so dropping one turns a stage that should be skipped into a stage that runs.
 * Unknown directives are recorded as `unsupported` instead, and the stage is reported with a
 * decision of "DO (?)" so the summary cannot quietly lie about what was executed.
 */
class WhenBlock extends Block {
    List<Closure<Boolean>> conditions = []
    List<String> unsupported = []

    /**
     * `branch 'release/*'` and `branch pattern: 'release.*', comparator: 'REGEXP'`.
     *
     * The default comparator is GLOB, and its `*` does NOT cross a `/`: `release*` does not match
     * `release/1.2.0`, while `release/*` and `release**` do. This is easy to get wrong, because a
     * pattern like `devel*` keeps working - `develop` has no separator in it - and only the
     * branch names that do have one fall through to SKIP. Treating `*` as `.*` here would make
     * this runner more permissive than Jenkins and it would report DO for a stage that Jenkins
     * skips, which is the one thing it must never do.
     */
    void branch(String pattern) {
        branch(pattern: pattern)
    }

    void branch(Map args) {
        String pattern = String.valueOf(args.pattern ?: args.name)
        String regex
        switch (String.valueOf(args.comparator ?: "GLOB").toUpperCase()) {
            case "REGEXP":
                regex = pattern
                break
            case "EQUALS":
                regex = java.util.regex.Pattern.quote(pattern)
                break
            default:
                regex = globToRegex(pattern)
        }
        conditions << { build.env.BRANCH_NAME ==~ regex }
    }

    private static String globToRegex(String pattern) {
        StringBuilder regex = new StringBuilder()
        for (int index = 0; index < pattern.length(); index++) {
            String character = pattern.charAt(index) as String
            if (character == "*") {
                if (index + 1 < pattern.length() && (pattern.charAt(index + 1) as String) == "*") {
                    regex.append(".*")          // ** crosses the / separators
                    index++
                } else {
                    regex.append("[^/]*")       // * stays inside one path segment
                }
            } else if (character == "?") {
                regex.append("[^/]")
            } else {
                regex.append(java.util.regex.Pattern.quote(character))
            }
        }
        regex.toString()
    }

    void expression(Closure<Boolean> condition) {
        conditions << condition
    }

    /** `environment name: 'DEPLOY_TO', value: 'production'` */
    void environment(Map args) {
        conditions << { build.env[String.valueOf(args.name)] == String.valueOf(args.value) }
    }

    void anyOf(Closure body) {
        def nested = nest(body)
        conditions << { nested.conditions.any { build.script.callBody(it) } }
    }

    void allOf(Closure body) {
        def nested = nest(body)
        conditions << { nested.conditions.every { build.script.callBody(it) } }
    }

    void not(Closure body) {
        def nested = nest(body)
        conditions << { !nested.conditions.every { build.script.callBody(it) } }
    }

    /** A nested block shares this block's list of unsupported directives, so nothing is lost. */
    private WhenBlock nest(Closure body) {
        def nested = (WhenBlock) dsl(new WhenBlock(build: build), body)
        unsupported.addAll(nested.unsupported)
        nested.unsupported = unsupported
        nested
    }

    def methodMissing(String name, Object args) {
        unsupported << name
        null
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
        Console.banner("Begin of pipeline on branch '${build.env.BRANCH_NAME}'")
        Console.out("Running on ${build.env.NODE_NAME} in ${build.workspace}")
        Console.out("agent ${pipeline.agent}")
        pipeline.triggers.each { Console.out("trigger ${it}") }
        pipeline.options.each { Console.out("option ${it}") }
        Console.out("${Deployment.VARIABLE}=${Deployment.enabled(build) ? 'on' : 'off'}")
        try {
            pipeline.stages.each { executeStage(it, 0) }
        } catch (Throwable throwable) {
            build.result = "FAILURE"
            Console.out("ERROR: ${throwable.message}")
        }
        executePost()
        printSummary()
        Console.banner("End of pipeline: ${build.result}")
    }

    /**
     * The `when` conditions decide DO or SKIP, and that decision is printed before anything
     * else happens in the stage - so the log says where execution is and what it did there,
     * for a skipped stage just as much as for one that ran.
     */
    private void executeStage(Stage stage, int depth) {
        executeStage(stage, depth, false)
    }

    /** `blocked` stops the steps from running; the when conditions are still evaluated. */
    private void executeStage(Stage stage, int depth, boolean blockedByParent) {
        boolean blocked = blockedByParent || Deployment.blocks(build, stage.name)
        stage.decision = stage.conditions.every { script.callBody(it) } ? Stage.DO : Stage.SKIP
        // `when` ANDs its directives, so an ignored one can only ever have turned DO into SKIP.
        // A SKIP is therefore still exact; only a DO has to admit that it might be wrong.
        if (stage.unsupported && stage.decision == Stage.DO) {
            stage.decision = Stage.DO_UNSURE
        }
        // A SKIP stays a SKIP: the stage would not have run anyway.
        if (blocked && stage.decision != Stage.SKIP) {
            stage.decision = Stage.BLOCKED
        }
        Console.stage("Begin", stage.name, stage.decision, depth)
        try {
            if (stage.unsupported) {
                Console.out("${'  ' * depth}  WARNING: when ${stage.unsupported.join(', ')}"
                    + " is not implemented by this runner and was ignored")
            }
            if (stage.decision == Stage.SKIP) {
                Console.out("${'  ' * depth}  skipped by the when conditional of the stage")
                return
            }
            executeBody(stage, depth, blocked)
        } finally {
            Console.stage("End", stage.name, stage.decision, depth)
        }
    }

    /** The stage really runs: its own environment applies, and its own post sections follow it. */
    private void executeBody(Stage stage, int depth, boolean blocked) {
        Map<String, String> restore = applyEnvironment(stage)
        Throwable failure = null
        try {
            if (stage.children && stage.parallel) {
                executeBranches(stage, depth, blocked)
            } else if (stage.children) {
                stage.children.each { executeStage(it, depth + 1, blocked) }
            } else if (stage.steps && blocked) {
                Console.out("${'  ' * depth}  steps not executed, ${Deployment.VARIABLE} is off")
            } else if (stage.steps) {
                script.callBody(stage.steps)
            }
        } catch (Throwable throwable) {
            failure = throwable
            throw throwable
        } finally {
            executeSections(stage.post, failure == null, "stage post", depth)
            restoreEnvironment(restore)
        }
    }

    /**
     * Jenkins scopes a stage level environment to that stage, so the previous values are put back
     * when it ends. There is one environment map per build here and parallel branches share it,
     * so a stage environment inside a parallel branch is not isolated from its siblings.
     */
    private Map<String, String> applyEnvironment(Stage stage) {
        Map<String, String> previous = [:]
        stage.environment.each { key, value ->
            previous[key] = build.env[key]
            build.env[key] = value
        }
        previous
    }

    private void restoreEnvironment(Map<String, String> previous) {
        previous.each { key, value ->
            value == null ? build.env.remove(key) : build.env.put(key, value)
        }
    }

    /** Real threads, one per branch; the first failure fails the whole stage. */
    private void executeBranches(Stage stage, int depth, boolean blocked) {
        Console.step("parallel")
        def failures = Collections.synchronizedList(new ArrayList<Throwable>())
        stage.children.collect { branch ->
            Thread.start {
                Console.BRANCH.set(branch.name)
                try {
                    executeStage(branch, depth + 1, blocked)
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

    /**
     * Parallel branches finish in whatever order the threads happen to end, so the summary is
     * printed by walking the model instead of by recording as it goes: it always comes out in
     * the order the Jenkinsfile declares the stages.
     */
    private void printSummary() {
        Console.banner("Stage summary for branch '${build.env.BRANCH_NAME}'")
        pipeline.stages.each { summarise(it, 0) }
    }

    private void summarise(Stage stage, int depth) {
        Console.out(String.format("  %-8s %s%s", stage.decision, "    " * depth, stage.name))
        stage.children.each { summarise(it, depth + 1) }
    }

    private void executePost() {
        executeSections(pipeline.post, build.result == "SUCCESS", "post", 0)
    }

    /**
     * `always` plus exactly one of `success` / `failure`, for a stage and for the pipeline alike.
     *
     * A step that fails inside a post section fails the build, exactly as it does in Jenkins -
     * otherwise a broken notification or cleanup would be reported as a green build and this
     * runner would exit 0. It is not rethrown: this runs from a finally block, where throwing
     * would swallow the failure that brought us here. Remaining stages therefore still run,
     * which Jenkins would not do.
     */
    private void executeSections(Map<String, Closure> sections, boolean success, String label, int depth) {
        ["always", success ? "success" : "failure"].each { section ->
            def body = sections[section]
            if (!body) {
                return
            }
            Console.out("${'  ' * depth}[Pipeline] ${label} ${section}")
            try {
                script.callBody(body)
            } catch (Throwable throwable) {
                build.result = "FAILURE"
                Console.out("ERROR in ${label} ${section}: ${throwable.message}")
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
        build.env.each { key, value ->
            if (key ==~ /[A-Za-z_][A-Za-z0-9_]*/) {
                binding.setVariable(key, value)
            }
        }
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
        // -x echoes every expanded command, -e stops at the first failing line of a
        // multi line script. That is how Jenkins runs a sh step.
        shell(["sh", "-xe", "-c", command])
    }

    void bat(String command) {
        Console.step("bat")
        Console.out("+ ${command}")
        shell(["cmd", "/c", command])
    }

    /** The build environment is passed to the process, so 'echo "${GHI}"' expands there. */
    private void shell(List<String> commandLine) {
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

    /**
     * Mail is emulated, never sent: this runner opens no SMTP connection anywhere, so a
     * Jenkinsfile can be exercised over and over without mailing the team on every run.
     * `emailext` comes from the Email Extension plugin, `mail` is the built in Jenkins step;
     * both are printed the same way.
     */
    void emailext(Map args) {
        mailStep("emailext", args)
    }

    void mail(Map args) {
        mailStep("mail", args)
    }

    private static void mailStep(String step, Map args) {
        Console.step(step)
        Console.out("E-mail is NOT sent, only printed:")
        Console.out("  to:      ${args.to ?: args.recipientProviders ?: '(not set)'}")
        if (args.cc) {
            Console.out("  cc:      ${args.cc}")
        }
        if (args.replyTo) {
            Console.out("  replyTo: ${args.replyTo}")
        }
        Console.out("  subject: ${args.subject}")
        Console.out("  body:    ${args.body}")
    }

    /**
     * Steps this small runner does not implement are reported, not failed.
     *
     * A step that takes a closure is a *wrapper* - `dir`, `withEnv`, `withCredentials`,
     * `timestamps`, `catchError`, `lock`, `ws` - and the real build steps are written inside it.
     * Reporting such a step and returning would throw that whole body away: `dir('sub') { sh
     * 'make' }` would run nothing at all and the build would still be reported as SUCCESS. The
     * body is therefore executed as it stands, without whatever the wrapper would have set up
     * around it - so `dir` does not change directory and `withEnv` does not add its variables.
     */
    def methodMissing(String name, Object args) {
        Console.step(name)
        def body = (args as Object[]).find { it instanceof Closure }
        if (body) {
            Console.out("Step '${name}' is not implemented by this runner;"
                + " its body is executed without the wrapper")
            return callBody((Closure) body)
        }
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
    build.script = pipelineScript
    pipelineScript.run()
    if (build.result != "SUCCESS") {
        System.exit(1)
    }
}

static Build newBuild(File jenkinsfile, CliArgs cliArgs) {
    final File workspace = jenkinsfile.canonicalFile.parentFile
    final Build build = new Build(workspace: workspace)
    // The environment of this machine comes first: a Jenkinsfile that writes
    // PATH = "/opt/setmy.info/bin:$PATH" must find the real PATH there, exactly as it
    // does on a Jenkins agent. Without it $PATH resolves to null and the PATH is lost.
    build.env.putAll(System.getenv())
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
