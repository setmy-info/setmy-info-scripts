import static java.lang.Math.toDegrees

static void main(String[] args) {
    if (args.length == 0) {
        println "Provide radians"
        return
    }
    print toDegrees(args[0].toDouble())
}
