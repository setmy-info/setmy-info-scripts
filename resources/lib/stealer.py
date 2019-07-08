import os
import glob
from os import listdir
from os.path import isfile, join

from commons import getEnvironment
from commons import execSub

'''
Development:
    ./configure && make && make package && sudo rpm -e setmy-info-scripts && sudo rpm -i setmy-info-scripts-0.13.0.noarch.rpm
    cd test && smi-stealer && cd ..
    rm -R ./test/.stealer/copy
    rm -Rf ./test/.stealer/clone
'''


class Locations:

    def __init__(self):
        self.currentDir = getEnvironment("CUR_DIR")
        self.stealerDir = self.currentDir + "/.stealer"
        self.reposDir = self.stealerDir + "/repos"
        self.projectNames = [f for f in listdir(self.reposDir) if isfile(join(self.reposDir, f))]
        self.patchDir = self.stealerDir + "/patch"
        self.cloneDir = self.stealerDir + "/clone"
        self.copyDir = self.stealerDir + "/copy"


class Project:

    def __init__(self):
        self.name = None
        ''' Repo props '''
        self.repoType = None
        self.repoUrl = None
        self.repoBranch = None
        self.repoFolders = None
        ''' Other props '''
        self.cleanedDestination = None


locations = Locations()


def steal():
    print("Start borrowing: " + str(locations.projectNames))
    create_projects()


def create_projects():
    for projectName in locations.projectNames:
        print("# BEGIN")
        create_project(projectName)
        print("# END")


def create_project(project_name):
    print("Creating:" + project_name)
    variable_values = read_variable_values(locations.reposDir + "/" + project_name)
    print("Vars:" + str(variable_values))
    project = Project()
    project.name = project_name
    project.repoType = variable_values['REPO_TYPE'][0]
    project.repoUrl = variable_values['REPO_URL'][0]
    project.repoBranch = variable_values['REPO_BRANCH'][0]
    project.repoFolders = variable_values['REPO_FOLDERS']
    project.cleanedDestination = get_ceaned_destination_dir(project)
    clone_destination = clone_project(project)
    checkout_project(project, clone_destination)
    copy_and_change_project(project, clone_destination)


def clone_project(project):
    clone_destination = get_clone_destination_dir(project)
    if not os.path.exists(clone_destination):
        result = execSub([project.repoType, 'clone', project.repoUrl, clone_destination])
        print(result)
    return clone_destination


def checkout_project(project, clone_destination):
    os.chdir(clone_destination)
    sub_command = None
    if project.repoType is 'git':
        sub_command = 'checkout'
    if project.repoType is 'git':
        sub_command = 'update'
    result = execSub([project.repoType, sub_command, project.repoBranch])
    print(result)
    os.chdir(locations.currentDir)


def copy_and_change_project(project, clone_destination):
    if not os.path.exists(project.cleanedDestination):
        os.makedirs(project.cleanedDestination)
    if project.repoFolders is not None:
        if len(project.repoFolders) > 0:
            for repoFolder in project.repoFolders:
                sourceDir = clone_destination + "/" + repoFolder
                destinationDir = project.cleanedDestination + "/" + repoFolder
                try:
                    os.makedirs(destinationDir)
                except OSError as e:
                    print('Directory not created. Error: %s' % e)
                do_copy(sourceDir, destinationDir)
        else:
            do_copy(clone_destination, project.cleanedDestination)


def read_variable_values(file_name):
    constants = {}
    file = open(file_name, "r")
    lines = file.readlines()
    for line in lines:
        name, val = line.split('=')
        val = val.replace('\"', '').replace('\n', '').split(' ')
        val = [i for i in val if i != '']
        constants[name] = val
    return constants


def get_ceaned_destination_dir(project):
    return locations.copyDir + "/" + project.name + "/" + project.repoBranch


def get_clone_destination_dir(project):
    return locations.cloneDir + "/" + project.name


def do_copy(sourceDir, destinationDir):
    cmd = ["cp", "-R", sourceDir + "/*", destinationDir + "/"]
    exec_cmd(cmd)


def exec_cmd(cmd):
    print(str(cmd))
    result = execSub(cmd)
    print(result)
