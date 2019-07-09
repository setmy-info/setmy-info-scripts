import os
import glob
from os import listdir
from os.path import isfile, join

from commons import get_environment
from commons import exec_sub

'''
Development:
    ./configure && make && make package && sudo rpm -e setmy-info-scripts && sudo rpm -i setmy-info-scripts-0.13.0.noarch.rpm
    cd test && smi-stealer && cd ..
    rm -R ./test/.stealer/copy
    rm -Rf ./test/.stealer/clone
'''


class Locations:

    def __init__(self):
        self.current_dir = get_environment("CUR_DIR")
        self.stealer_dir = self.current_dir + "/.stealer"
        self.repos_dir = self.stealer_dir + "/repos"
        self.project_names = [f for f in listdir(self.repos_dir) if isfile(join(self.repos_dir, f))]
        self.patch_dir = self.stealer_dir + "/patch"
        self.clone_dir = self.stealer_dir + "/clone"
        self.copy_dir = self.stealer_dir + "/copy"


class Project:

    def __init__(self):
        self.name = None
        ''' Repo props '''
        self.repo_type = None
        self.repo_url = None
        self.repo_branch = None
        self.repo_folders = None
        ''' Other props '''
        self.cleaned_destination = None


locations = Locations()


def steal():
    print("Start borrowing: " + str(locations.project_names))
    create_projects()


def create_projects():
    for projectName in locations.project_names:
        print("# BEGIN")
        create_project(projectName)
        print("# END")


def create_project(project_name):
    print("Creating:" + project_name)
    variable_values = read_variable_values(locations.repos_dir + "/" + project_name)
    print("Vars:" + str(variable_values))
    project = Project()
    project.name = project_name
    project.repo_type = variable_values['REPO_TYPE'][0]
    project.repo_url = variable_values['REPO_URL'][0]
    project.repo_branch = variable_values['REPO_BRANCH'][0]
    project.repo_folders = variable_values['REPO_FOLDERS']
    project.cleaned_destination = get_cleaned_destination_dir(project)
    clone_destination = clone_project(project)
    checkout_project(project, clone_destination)
    copy_and_change_project(project, clone_destination)


def clone_project(project):
    clone_destination = get_clone_destination_dir(project)
    if not os.path.exists(clone_destination):
        result = exec_sub([project.repo_type, 'clone', project.repo_url, clone_destination])
        print(result)
    return clone_destination


def checkout_project(project, clone_destination):
    os.chdir(clone_destination)
    sub_command = None
    if project.repo_type == 'git':
        sub_command = 'checkout'
    if project.repo_type == 'hg':
        sub_command = 'update'
    result = exec_sub([project.repo_type, sub_command, project.repo_branch])
    print(result)
    os.chdir(locations.current_dir)


def copy_and_change_project(project, clone_destination):
    if not os.path.exists(project.cleaned_destination):
        os.makedirs(project.cleaned_destination)
    if project.repo_folders is not None:
        if len(project.repo_folders) > 0:
            for repo_folder in project.repo_folders:
                source_dir = clone_destination + "/" + repo_folder
                destination_dir = project.cleaned_destination + "/" + repo_folder
                try:
                    os.makedirs(destination_dir)
                except OSError as e:
                    print('Directory not created. Error: %s' % e)
                do_copy(source_dir, destination_dir)
        else:
            do_copy(clone_destination, project.cleaned_destination)


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


def get_cleaned_destination_dir(project):
    return locations.copy_dir + "/" + project.name + "/" + project.repo_branch


def get_clone_destination_dir(project):
    return locations.clone_dir + "/" + project.name


def do_copy(source_dir, destination_dir):
    cmd = ["cp", "-R", source_dir + "/*", destination_dir + "/"]
    exec_cmd(cmd)


def exec_cmd(cmd):
    print(str(cmd))
    result = exec_sub(cmd)
    print(result)
