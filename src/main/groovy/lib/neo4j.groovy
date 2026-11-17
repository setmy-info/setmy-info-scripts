#!/usr/bin/env groovy

// Copyright (C) 2026 Imre Tabur <imre.tabur@mail.ee>

@Grab(group = 'org.neo4j', module = 'neo4j', version = '2026.10.2')
@Grab(group = 'info.picocli', module = 'picocli', version = '4.7.7')

import org.neo4j.dbms.api.DatabaseManagementService
import org.neo4j.dbms.api.DatabaseManagementServiceBuilder
import org.neo4j.graphdb.GraphDatabaseService
import picocli.CommandLine
import picocli.CommandLine.Command
import picocli.CommandLine.Option
import picocli.CommandLine.Parameters

import java.nio.file.Files
import java.nio.file.Path
import java.util.concurrent.Callable

import static org.neo4j.configuration.GraphDatabaseSettings.DEFAULT_DATABASE_NAME

class Neo4jHome {
    static <T> T withDatabase(Path home, Closure<T> work) {
        DatabaseManagementService service = new DatabaseManagementServiceBuilder(home).build()
        try {
            return work(service.database(DEFAULT_DATABASE_NAME))
        } finally {
            service.shutdown()
        }
    }

    static boolean isDatabase(Path home) {
        Files.isDirectory(home.resolve('data').resolve('databases').resolve(DEFAULT_DATABASE_NAME))
    }

    static String quote(String value) {
        "'" + value.replace("'", "'\\''") + "'"
    }
}

@Command(name = 'smi-neo4j-create-db', mixinStandardHelpOptions = true,
        description = 'Create an empty embedded Neo4j Community database and print its SMI_ variables.')
class CreateCommand implements Callable<Integer> {
    @Parameters(index = '0', paramLabel = 'NAME', description = 'Database directory name.')
    String name

    @Option(names = ['-d', '--dir'], paramLabel = 'DIR', defaultValue = '${env:SMI_DB_DIR:-.}',
            description = 'Parent directory, default SMI_DB_DIR or the current directory.')
    Path dir

    Integer call() {
        if (!(name ==~ /[a-z][a-z0-9_]*/)) {
            System.err.println("ERROR: Invalid database name: ${name}")
            return 1
        }
        Path home = dir.toAbsolutePath().normalize().resolve(name)
        if (Files.exists(home)) {
            System.err.println("ERROR: Database exists: ${home}")
            return 1
        }
        Files.createDirectories(home)
        Neo4jHome.withDatabase(home) { GraphDatabaseService db ->
            db.executeTransactionally('RETURN 1')
        }
        println "export SMI_DB_TYPE=${Neo4jHome.quote('neo4j')}"
        println "export SMI_DB_NAME=${Neo4jHome.quote(name)}"
        println "export SMI_NEO4J_HOME=${Neo4jHome.quote(home.toString())}"
        return 0
    }
}

@Command(name = 'smi-neo4j-query', mixinStandardHelpOptions = true,
        description = 'Run Cypher against an embedded Neo4j database: the statement given, or a script from standard input.')
class QueryCommand implements Callable<Integer> {
    @Option(names = ['-H', '--home'], paramLabel = 'DIR', defaultValue = '${env:SMI_NEO4J_HOME}',
            description = 'Database directory, default SMI_NEO4J_HOME.')
    Path home

    @Option(names = ['-p', '--param'], paramLabel = 'NAME=VALUE',
            description = 'Query parameter, used as \$NAME in Cypher, given as a string.')
    Map<String, String> params = [:]

    @Parameters(paramLabel = 'CYPHER', arity = '0..*', description = 'The statement; without it the statements are read from standard input, each ended with ;.')
    List<String> cypher = []

    Integer call() {
        if (home == null) {
            System.err.println('ERROR: Set SMI_NEO4J_HOME or --home.')
            return 1
        }
        home = home.toAbsolutePath().normalize()
        if (!Neo4jHome.isDatabase(home)) {
            System.err.println("ERROR: Not a Neo4j database: ${home}")
            return 1
        }
        String text = cypher ? cypher.join(' ') : System.in.text.readLines().findAll { !it.trim().startsWith('//') }.join('\n')
        List<String> statements = text.split(/;\s*(\r?\n|$)/).toList()*.trim().findAll()*.replaceAll(/;$/, '')
        if (!statements) {
            System.err.println('ERROR: No Cypher statement given.')
            return 1
        }
        Neo4jHome.withDatabase(home) { GraphDatabaseService db ->
            statements.each { String statement ->
                println statement
                print db.executeTransactionally(statement, params as Map<String, Object>, { result -> result.resultAsString() })
            }
        }
        return 0
    }
}

if (!args || !(args[0] in ['create', 'query'])) {
    System.err.println('Usage: neo4j.groovy create|query [OPTIONS]')
    System.exit(1)
}
def command = args[0] == 'create' ? new CreateCommand() : new QueryCommand()
def commandLine = new CommandLine(command)
commandLine.setExecutionExceptionHandler({ Exception e, CommandLine cl, CommandLine.ParseResult parseResult ->
    System.err.println("ERROR: ${e.message}")
    return 1
} as CommandLine.IExecutionExceptionHandler)
System.exit(commandLine.execute(args.drop(1) as String[]))
