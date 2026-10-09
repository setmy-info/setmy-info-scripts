def runCommand(String command) {
    if (isUnix()) {
        sh command
    } else {
        bat command
    }
}

pipeline {
    agent any
    triggers {
        pollSCM('H/5 * * * *')
    }
    options {
        buildDiscarder(
            logRotator(
                numToKeepStr: '20',
                artifactNumToKeepStr: '10'
            )
        )
        quietPeriod(15)
        disableConcurrentBuilds(abortPrevious: true)
    }

    environment {
        MASTER_TO_LIVE = 'DEPLOY'

        RELEASE_TO_PRELIVE = 'DEPLOY'
        HOTFIX_TO_PRELIVE = 'DEPLOY'

        DEVELOPMENT_TO_TEST = 'DEPLOY'
        RELEASE_TO_TEST = 'DEPLOY'
        HOTFIX_TO_TEST = 'DEPLOY'

        DEVELOPMENT_TO_DEV = 'DEPLOY'
    }

    stages {
        stage('Inspection') {
            parallel {
                stage('Pre-build') {
                    steps {
                        echo "Jenkins node: ${env.NODE_NAME}"
                        echo "Operating system: ${isUnix() ? 'Unix/Linux' : 'Windows'}"
                        echo "PATH is: $PATH"
                        runCommand 'cmake --version'
                        runCommand 'make --version'
                    }
                }
                stage('Build tools') {
                    steps {
                        echo 'Build tools installation and preparation (setup, config)'
                    }
                }
            }
        }

        stage('Preparation') {
            parallel {
                stage('Install') {
                    steps {
                        echo 'Preparing the software to be built. Installation commands go here.'
                        runCommand './configure release'
                    }
                }
            }
        }

        stage('Build') {
            steps {
                echo 'Cleaning command, because in some cases shared directories can have previous build garbage'
                runCommand 'make clean'
                runCommand 'make all test package'
            }
        }

        stage('Publish') {
            parallel {
                stage('Release') {
                    when {
                        branch 'master'
                        // changeset "**/file/to/be/changed"
                    }
                    steps {
                        echo 'Put here software release steps'
                   }
                }
                stage('Snapshot') {
                    when {
                        branch pattern: 'devel.*', comparator: 'REGEXP'
                    }
                    steps {
                        echo 'Put here software snapshot publishing steps'
                    }
                }
                stage('Release reports') {
                    when {
                        branch 'master'
                    }
                    steps {
                        echo 'Put here reports publishing steps'
                    }
                }
                stage('Snapshot reports') {
                    when {
                        branch pattern: 'devel.*', comparator: 'REGEXP'
                    }
                    steps {
                        echo 'Put here reports publishing steps'
                    }
                }
            }
        }
        stage('Deploy') {
            parallel {
                stage('dev') {
                    when {
                        environment name: 'DEVELOPMENT_TO_DEV', value: 'DEPLOY'
                        branch pattern: 'devel.*', comparator: 'REGEXP'
                    }
                    steps {
                        echo 'No DEV machine: this Jenkins node is the TEST machine itself, and the test stage deploys to it'
                    }
                }
                stage('test') {
                    when {
                        anyOf {
                            allOf {
                                environment name: 'DEVELOPMENT_TO_TEST', value: 'DEPLOY'
                                branch pattern: 'devel.*', comparator: 'REGEXP'
                            }
                            allOf {
                                environment name: 'RELEASE_TO_TEST', value: 'DEPLOY'
                                branch pattern: 'release.*', comparator: 'REGEXP'
                            }
                            allOf {
                                environment name: 'HOTFIX_TO_TEST', value: 'DEPLOY'
                                branch pattern: 'hotfix.*', comparator: 'REGEXP'
                            }
                        }
                    }
                    steps {
                        echo 'Uploading the RPM to TEST and handing it to the deployment service there, which installs it'
                        // No server belongs in this repository: the values come from the job
                        // configuration of this pipeline, which maps its own variables onto the
                        // ones src/main/sh/build/deploy.sh reads.
                        runCommand 'SMI_DEPLOY_HOSTS="${SMI_DEPLOY_TEST_HOSTS}" make deploy'
                        // The installed version is deliberately not read back: the deployment
                        // service installs in parallel with this build and a query would race
                        // it. journalctl -u setmy-info-deploy.service on the machine says what
                        // happened.
                    }
                }
                stage('prelive') {
                    when {
                        anyOf {
                            allOf {
                                environment name: 'RELEASE_TO_PRELIVE', value: 'DEPLOY'
                                branch pattern: 'release.*', comparator: 'REGEXP'
                            }
                            allOf {
                                environment name: 'HOTFIX_TO_PRELIVE', value: 'DEPLOY'
                                branch pattern: 'hotfix.*', comparator: 'REGEXP'
                            }
                        }
                    }
                    steps {
                        echo 'No PRELIVE machine'
                    }
                }
                stage('live') {
                    when {
                        environment name: 'MASTER_TO_LIVE', value: 'DEPLOY'
                        branch 'master'
                    }
                    steps {
                        echo 'Uploading the RPM to LIVE and handing it to the deployment service there, which installs it'
                        // The same package belongs on every machine of the environment, so the
                        // variable of the job configuration holds them all: one more machine is
                        // one more word in it, "host" or "host:port", and nothing changes here.
                        runCommand 'SMI_DEPLOY_HOSTS="${SMI_DEPLOY_LIVE_HOSTS}" make deploy'
                    }
                }
            }
        }
        /*
        Stage to make SCM tag. As all results are succeeded then tag reflects FULL build success.
        */
        stage('Tag') {
            when {
                environment name: 'MASTER_TO_LIVE', value: 'DEPLOY'
                branch 'master'
            }
            steps {
                runCommand "SCRIPTS_VERSION=\$(sed -n 's/^SCRIPTS_VERSION=\\([0-9.]*\\)\$/\\1/p' README.md) && smi-new-tag \${SCRIPTS_VERSION}"
            }
        }
    }

    post {
        always {
            // junit '**/target/*-reports/*.xml'
            // 9 EXAMPLE : just placeholder for actions after any build.
            runCommand 'echo "Always"'
        }

        success {
            emailext (
                subject: "Jenkins job: $JOB_NAME, build: $BUILD_NUMBER type: SUCCESSFUL",
                body: "Job: $JOB_NAME, build: $BUILD_NUMBER, url: ${env.BUILD_URL}, git: ${env.GIT_URL}, branch: ${env.GIT_BRANCH} SUCCESSFUL post step",
                recipientProviders: [[$class: 'DevelopersRecipientProvider']]
            )
        }

        failure {
            emailext (
                subject: "Jenkins job: $JOB_NAME, build: $BUILD_NUMBER type: FAILED",
                body: "Job: $JOB_NAME, build: $BUILD_NUMBER, url: ${env.BUILD_URL}, git: ${env.GIT_URL}, branch: ${env.GIT_BRANCH}  FAILED post step",
                recipientProviders: [[$class: 'DevelopersRecipientProvider']]
            )
        }
    }
}

