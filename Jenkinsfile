#!/usr/bin/env groovy

void saveDockerImage(String image, String tag, String tarName) {
    sh "docker save ${image}:${tag} | gzip > ${tarName}-${tag}.tar.gz"
    sh "docker rmi ${image}:${tag}"
}

pipeline {
    agent {
        label 'slave-group-graalvm'
    }

    options {
        timeout(time: 1, unit: 'HOURS')
    }

    stages {

        stage('Prepare') {
            steps {
                script {
                    IMAGE_TAG = env.BRANCH_NAME.startsWith('PR-') ? "PR-${pullRequest.number}" : "latest"
                }
            }
        }

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build') {
            steps {
                script {
                    ['server-native', 'server-openjdk'].each { descriptor ->
                        sh "cekit -v --descriptor ${descriptor}.yaml build --overrides '{'version': '${IMAGE_TAG}'}' docker"
                    }
                }
            }
        }
    }

    post {
        failure {
            echo 'post build status: failure'
        }

        success {
            script {
                saveDockerImage 'infinispan/server', IMAGE_TAG, 'server-openjdk'
                saveDockerImage 'infinispan/server-native', IMAGE_TAG, 'server-native'
                archiveArtifacts allowEmptyArchive: true, artifacts: '*tar.gz'
                echo 'post build status: success'
            }
        }

        cleanup {
            sh 'git clean -fdx || echo "git clean failed, exit code $?"'
            sh 'docker container prune -f'
            sh 'docker rmi $(docker images -f "dangling=true" -q) || true'
        }
    }
}
