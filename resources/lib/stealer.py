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
        ''' Repo props '''
        self.repoType = None
        self.repoUrl = None
        self.repoBranch = None
        self.repoFolders = None
        ''' Other Protps '''
        self.cleanedDestination = None


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
    project.cleanedDestination = getCleanedDestinationDir(project)
    cloneProject(project)
    checkoutProject(project)
    copyProject(project)
    changeProject(project)


def cloneProject(project):
    cloneDestination = getCloneDestinationDir(project)
    if (not os.path.exists(cloneDestination)):
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
    '''project.cleanedDestination = getCleanedDestinationDir(project)'''
    if not os.path.exists(project.cleanedDestination):
        os.makedirs(project.cleanedDestination)
    if (project.repoFolders is not None):
        if (len(project.repoFolders) > 0):
            for repoFolder in project.repoFolders:
                sourceDir = cloneDestination + "/" + repoFolder
                destinationDir = project.cleanedDestination + "/" + repoFolder
                try:
                    os.makedirs(destinationDir)
                except OSError as e:
                    print('Directory not created. Error: %s' % e)
                doCopy(sourceDir, destinationDir)
        else:
            doCopy(cloneDestination, project.cleanedDestination)


def getCloneDestinationDir(project):
    return locations.cloneDir + "/" + project.name


def getCleanedDestinationDir(project):
    return locations.copyDir + "/" + project.name + "/" + project.repoBranch


def doCopy(sourceDir, destinationDir):
    cmd = ["cp", "-R", sourceDir + "/*", destinationDir + "/"]
    execCmd(cmd)


def changeProject(project):
    print('------------changeProject--------------')
    if project.repoFolders is None or len(project.repoFolders) == 0:
        for repoFolder in project.repoFolders:
            destinationDir = project.cleanedDestination + "/" + repoFolder
            doChanges(project, destinationDir)
    else:
        doChanges(project, project.cleanedDestination + "/")


def doChanges(project, destinationDir):
    ''' TODO '''
    print('------------doChanges--------------')
    os.chdir(destinationDir)
    postCopyProjectChange(project)
    patchProject(project)
    postPatchChangeProject(project)
    copyOnPlace(project)
    os.chdir(locations.currentDir)


def postCopyProjectChange(project):
    ''' TODO '''
    print('------------postCopyProjectChange--------------')
    postCopyFileNames = getPostCopyFiles(project)
    for postCopyFileName in postCopyFileNames:
        shellInclude(postCopyFileName)


def shellInclude(shellIncludeFileName):
    ''' TODO : test it '''
    print('------------shellInclude--------------')
    cmd = ["smi-stealer-shell", shellIncludeFileName]
    execCmd(cmd)


def patchProject(project):
    ''' TODO : test it '''
    print('------------patchProject--------------')
    patchFileNames = getPatchFiles(project)
    for patchFileName in patchFileNames:
        cmd = ["patch", "-f", "-s", "-p1", "<", patchFileName]
        execCmd(cmd)


def getPatchFiles(project):
    print('------------getPatchFiles--------------')
    list = getSortedFilesListByPattern(getProjectPatchSuffix(project) + ".patch")
    print(str(list))
    return list


def getPostCopyFiles(project):
    print('------------getPostCopyFiles--------------')
    list = getSortedFilesListByPattern(getProjectPatchSuffix(project) + ".post.copy")
    print(str(list))
    return list


def getChangeFiles(project):
    print('------------getChangeFiles--------------')
    list = getSortedFilesListByPattern(getProjectPatchSuffix(project) + ".change")
    print(str(list))
    return list


def getProjectPatchSuffix(project):
    suffix = locations.patchDir + "/*" + project.name
    print("getProjectPatchSuffix suffix: " + suffix)
    return suffix


def getSortedFilesListByPattern(pattern):
    print('------------getSortedFilesListByPattern--------------')
    print('pattern: ' + pattern)
    fileNames = glob.glob(pattern)
    print('File names 1: ' + str(fileNames))
    fileNames.sort()
    print('File names 2: ' + str(fileNames))
    return fileNames


def postPatchChangeProject(project):
    ''' TODO : test it '''
    print('------------postPatchChangeProject--------------')
    changeFiles = getChangeFiles(project)
    for changeFile in changeFiles:
        shellInclude(changeFile)


def copyOnPlace(project):
    ''' TODO : test it '''
    print('------------copyOnPlace--------------')
    copyProjectRepoFolders(project)
    copyProjectRepoFolders2(project)


def copyProjectRepoFolders(project):
    print('------------copyProjectRepoFolders--------------')
    if (project.repoFolders is not None):
        if len(project.repoFolders) > 0:
            for repoFolder in project.repoFolders:
                copyProjectRepoFolder(repoFolder)


def copyProjectRepoFolders2(project):
    print('------------copyProjectRepoFolders2--------------')
    if project.repoFolders is None or len(project.repoFolders) == 0:
        copyProjectFullRepo()


def copyProjectRepoFolder(repoFolder):
    print('------------copyProjectRepoFolder--------------')
    cmd = ["cp", "-R", "./" + repoFolder + "/*", locations.currentDir]
    execCmd(cmd)


def copyProjectFullRepo():
    print('------------copyProjectFullRepo--------------')
    cmd = ["cp", "-R", "./*", locations.currentDir]
    execCmd(cmd)


def execCmd(cmd):
    print(str(cmd))
    result = execSub(cmd)
    print(result)
