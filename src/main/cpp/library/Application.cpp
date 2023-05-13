#include "Application.h"
#include "Version.h"

#include <cmath>
#include <cstdio>
#include <cstdlib>

#include <iostream>
#include <thread>

#include <unistd.h>

void workerFunc();

namespace SetMyInfo {

    Application::Application() {
        // Ready for write.
    }

    Application::Application(const Application& orig) {
        // Ready for write.
    }

    Application::~Application() {
        // Ready for write.
    }

    int Application::Args(int argc, char *argv[], char *env[]) {
        this->commandName = argv[0];
        for (int i = 1; i < argc; i++) {
            std::string tmp = argv[i];
            this->parameters.push_back(tmp);
        }
        if (argc < 2) {
            fprintf(stdout, "%s Version %d.%d.%d\n",
                    argv[0],
                    PROJECT_MODULE_VERSION_MAJOR,
                    PROJECT_MODULE_VERSION_MINOR,
                    PROJECT_MODULE_VERSION_PATCH);
            fprintf(stdout, "Usage: %s number\n", argv[0]);
            return 1;
        }
        double inputValue = atof(argv[1]);
        double outputValue = sqrt(inputValue);
        fprintf(stdout, "The square root of %g is %g\n", inputValue, outputValue);
        return this->Main();
    }

    int Application::Main() {
        std::cout << "main: startup" << std::endl;
        std::thread workerThread(workerFunc);
        std::cout << "main: waiting for thread" << std::endl;
        workerThread.join();
        std::cout << "main: done" << std::endl;
        return 0;
    }
}

void workerFunc() {
std::cout << "Worker: running" << std::endl;
    // Pretending to do something useful...
    sleep(3);
    std::cout << "Worker: finished" << std::endl;    
}
