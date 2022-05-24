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
                    ['server-native', 'server-openjdk', 'cli'].each { name ->
                        sh "cekit -v --descriptor ${name}.yaml --target target-${name} build --overrides '{'version': '${IMAGE_TAG}'}' --dry-run docker"
                        sh "docker run --rm --privileged multiarch/qemu-user-static --reset -p yes"
                        sh "docker buildx use multiarch"
                        sh "docker buildx build --platform linux/amd64,linux/arm64 target-${name}/image"
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
                saveDockerImage 'infinispan/cli', IMAGE_TAG, 'cli'
                archiveArtifacts allowEmptyArchive: true, artifacts: '*tar.gz'
                echo 'post build status: success'
            }
        }

        cleanup {
            sh 'git clean -fdx || echo "git clean failed, exit code $?"'
            sh 'docker container prune -f'
            sh 'docker rmi $(docker images -f "dangling=true" -q) || true'
            sh "docker rm infinispan/server:$IMAGE_TAG || true"
            sh "docker rm infinispan/server-native:$IMAGE_TAG || true"
            sh "docker rm infinispan/cli:$IMAGE_TAG || true"
        }
    }
}
