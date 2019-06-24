pipeline {

    agent any

    environment {
        PATH = "/opt/cmake/bin:/usr/local/bin:$PATH"
    }

    stages {
        stage('Environment') {
            steps {
                echo "PATH is: $PATH"
                sh 'cmake --version'
                sh 'make --version'
            }
        }
        stage('Clean') {
            steps {
                sh 'rm -Rf Makefile CMakeFiles build/ *.cmake CMakeCache.txt setmy-info-scripts-*.noarch.*'
            }
        }
        stage('Configure') {
            steps {
                sh './configure'
            }
        }
        stage('Build') {
            steps {
                sh 'make'
            }
        }
        stage('Package') {
            steps {
                sh 'make package'
            }
        }
        stage ('Deploy') {
            steps {
            	sh 'cp -f ./setmy-info-scripts-*.noarch.* /tank/org/has/files/www/rpms/'
            }
        }
        stage('List') {
            steps {
                sh 'ls -la'
            }
        }
    }

    post {
        success {
            emailext (
                subject: "SUCCESSFUL: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]'",
                body: """<p>SUCCESSFUL: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]':</p>
                            <p>Check console output at &QUOT;<a href='${env.BUILD_URL}'>${env.JOB_NAME} [${env.BUILD_NUMBER}]</a>&QUOT;</p>""",
                recipientProviders: [[$class: 'DevelopersRecipientProvider']]
            )
        }
        failure {
            emailext (
                subject: "FAILED: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]'",
                body: """<p>FAILED: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]':</p>
                            <p>Check console output at &QUOT;<a href='${env.BUILD_URL}'>${env.JOB_NAME} [${env.BUILD_NUMBER}]</a>&QUOT;</p>""",
                recipientProviders: [[$class: 'DevelopersRecipientProvider']]
            )
        }
    }
}
