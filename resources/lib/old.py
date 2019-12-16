

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
    # TODO : one by one add these
    # postPatchChangeProject(project)
    # copyOnPlace(project)
    # os.chdir(locations.currentDir)


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

