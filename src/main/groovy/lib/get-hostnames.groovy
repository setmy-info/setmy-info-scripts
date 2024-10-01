import java.net.InetAddress

def getHostnames(String address) {
    try {
        InetAddress[] addresses = InetAddress.getAllByName(address)
        addresses.each { addr ->
            println("Domain name: " + addr.getHostName())
            println("IP address: " + addr.getHostAddress())
            println("-----")
        }
    } catch (Exception e) {
        e.printStackTrace()
    }
}

if (args.length == 0) {
    println "Usage: groovy get-hostnames.groovy <domain_name/IP-address>"
} else {
    getHostnames(args[0])
}
