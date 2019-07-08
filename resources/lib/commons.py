import subprocess
import os
from sqlite3.dbapi2 import paramstyle


def get_value(command_name):
    return exec_sub([command_name])


def exec_sub(params):
    print("execSub: " + str(params));
#    procString = ""
#    for param in params:
#        procString += param
    proc_string = ' '.join(params)
    result = subprocess.Popen(proc_string, shell=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    stdout, stderr = result.communicate()
    return stdout.decode('utf-8')


def get_environment(name):
    return os.environ.get(name)
