import os
import shutil
from os import listdir
from os.path import isfile, join

from commons import getValue
from commons import getEnvironment
from commons import execSub


class Locations():
    
    def __init__(self):
        self.currentDir = getEnvironment("CUR_DIR")
        self.stealerDir = self.currentDir + "/.stealer"
        self.reposDir = self.stealerDir + "/repos"
        self.projectNames = [f for f in listdir(self.reposDir) if isfile(join(self.reposDir, f))]
        self.patchDir = self.stealerDir + "/patch"
        self.cloneDir = self.stealerDir + "/clone"
        self.copyDir = self.stealerDir + "/copy"


class Project():

    def __init__(self):
        self.name = None
        self.repoType = None
        self.repoUrl = None
        self.repoBranch = None
        self.repoFolders = None


locations = Locations()


def readVariableValues(fileName):
    constants = {}
    file = open(fileName, "r")
    lines = file.readlines()
    for line in lines:
        name, val = line.split('=')
        val = val.replace('\"', '').replace('\n', '').split(' ')
        val = [i for i in val if i != '']
        constants[name] = val
    return constants


def steal():
    print("Start borrowing: " + str(locations.projectNames))
    createProjects()


def createProjects():
    for projectName in locations.projectNames:
        print("=========== BEGIN ==========")
        createProject(projectName)
        print("===========  END  ==========")


def createProject(projectName):
    print("Creating:" + projectName)
    variableValues = readVariableValues(locations.reposDir + "/" + projectName)
    print("Vars:" + str(variableValues))
    project = Project()
    project.name = projectName
    project.repoType = variableValues['REPO_TYPE'][0]
    project.repoUrl = variableValues['REPO_URL'][0]
    project.repoBranch = variableValues['REPO_BRANCH'][0]
    project.repoFolders = variableValues['REPO_FOLDERS']
    cloneProject(project)
    checkoutProject(project)
    copyProject(project)


def cloneProject(project):
    cloneDestination = getCloneDestinationDir(project)
    if(not os.path.exists(cloneDestination)):
        result = execSub([project.repoType, 'clone', project.repoUrl, cloneDestination])
        print(result)


def checkoutProject(project):
    cloneDestination = getCloneDestinationDir(project)
    os.chdir(cloneDestination)
    result = execSub([project.repoType, 'checkout', project.repoBranch])
    print(result)
    os.chdir(locations.currentDir)


def copyProject(project):
    cloneDestination = getCloneDestinationDir(project)
    cleanedDestination = getCleanedDestinationDir(project)
    if not os.path.exists(cleanedDestination):
        os.makedirs(cleanedDestination)
    if(project.repoFolders is not None):
        if(len(project.repoFolders) > 0):
            for repoFolder in project.repoFolders:
                sourceDir = cloneDestination + "/" + repoFolder
                destinationDir = cleanedDestination + "/" + repoFolder
                doCopy(sourceDir, destinationDir)
        else:
            doCopy(cloneDestination, cleanedDestination)


def getCloneDestinationDir(project):
    return locations.cloneDir + "/" + project.name


def getCleanedDestinationDir(project):
    return locations.copyDir + "/" + project.name + "/" + project.repoBranch


def doCopy(sourceDir, destinatoinDir):
    try:
        os.makedirs(destinatoinDir)
    except OSError as e:
        print('Directory not created. Error: %s' % e)

    cmd = ["cp", "-R", sourceDir + "/*", destinatoinDir + "/"]
    print(str(cmd));
    result = execSub(cmd)
    print(result)

