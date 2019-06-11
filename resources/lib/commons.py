import subprocess
import os
from sqlite3.dbapi2 import paramstyle


def getValue(commandName):
    return execSub([commandName])


def execSub(params):
    print("execSub: " + str(params));
#    procString = ""
#    for param in params:
#        procString += param
    procString = ' '.join(params)
    result = subprocess.Popen(procString, shell=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    stdout, stderr = result.communicate()
    return stdout.decode('utf-8')


def getEnvironment(name):
    return os.environ.get(name)
