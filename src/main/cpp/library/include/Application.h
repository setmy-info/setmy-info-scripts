#ifndef SET_MY_INFO_APPLICATION_H
#define	SET_MY_INFO_APPLICATION_H

#include <string>
#include <vector>
#include <map>

namespace SetMyInfo {

    class Application {
    public:

        std::string commandName;
        std::vector<std::string> parameters;

        Application();
        Application(const Application& orig);
        virtual ~Application();

        int Args(int argc, char *argv[], char *env[]);
        virtual int Main();

    private:

    };
}
#endif // SET_MY_INFO_APPLICATION_H
