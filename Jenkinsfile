#!/usr/bin/env groovy

pipeline {
    agent {
        label 'slave-group-normal'
    }

    options {
        timeout(time: 1, unit: 'HOURS')
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build') {
            steps {
                sh "cekit build docker"
            }
        }
    }

    post {
        failure {
            echo "post build status: failure"
            emailext to: '${DEFAULT_RECIPIENTS}', subject: '${DEFAULT_SUBJECT}', body: '${DEFAULT_CONTENT}'
        }

        success {
            echo "post build status: success"
            emailext to: '${DEFAULT_RECIPIENTS}', subject: '${DEFAULT_SUBJECT}', body: '${DEFAULT_CONTENT}'
        }

        cleanup {
            sh 'git clean -fdx || echo "git clean failed, exit code $?"'
            sh 'docker container prune -f'
            sh 'docker rmi $(docker images -f "dangling=true" -q) || true'
        }
    }
}
