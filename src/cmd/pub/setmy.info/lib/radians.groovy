import static java.lang.Math.toRadians

static void main(String[] args) {
    if (args.length == 0) {
        println "Provide degrees"
        return
    }
    print toRadians(args[0].toDouble())
}
