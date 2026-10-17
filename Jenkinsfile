pipeline {
    agent any

    triggers {
        pollSCM('H/2 * * * *')
    }

    options {
        timestamps()
        timeout(time: 25, unit: 'MINUTES')
        disableConcurrentBuilds()
        skipDefaultCheckout(true)
    }

    environment {
        SONAR_HOST_URL = 'http://127.0.0.1:9000'
        SONAR_SCANNER = '/opt/sonar-scanner/bin/sonar-scanner'
    }

    stages {
        stage('Checkout') {
            steps {
                deleteDir()
                checkout scm
            }
        }

        stage('Build') {
            steps {
                sh '''
                    python3 --version
                    python3 -m venv .venv
                    .venv/bin/python -m pip install --upgrade pip
                    .venv/bin/pip install -r requirements-dev.txt
                '''
            }
        }

        
        stage('Test') {
            steps {
                sh '''
                    mkdir -p reports
        
                    echo "Current directory:"
                    pwd
        
                    echo "Checking app.py:"
                    ls -l app.py
        
                    echo "Running tests:"
                    PYTHONPATH="$WORKSPACE" .venv/bin/pytest \
                      --junitxml=reports/junit.xml \
                      --cov=app \
                      --cov-report=term-missing \
                      --cov-report=xml:coverage.xml \
                      --cov-fail-under=90
                '''
            }
        }


        stage('Code Inspection') {
            steps {
                withCredentials([
                    string(credentialsId: 'sonar-token', variable: 'SONAR_TOKEN')
                ]) {
                    sh '''
                        "$SONAR_SCANNER" \
                          -Dsonar.host.url="$SONAR_HOST_URL" \
                          -Dsonar.token="$SONAR_TOKEN" \
                          -Dsonar.qualitygate.wait=true \
                          -Dsonar.qualitygate.timeout=300
                    '''
                }
            }
        }

        stage('Deploy') {
            steps {
                sh 'bash scripts/deploy.sh "$BUILD_NUMBER"'
            }
        }
    }

    post {
        always {
            junit allowEmptyResults: true, testResults: 'reports/junit.xml'
            archiveArtifacts allowEmptyArchive: true, artifacts: 'coverage.xml,reports/**'
        }
        success {
            echo 'CI/CD pipeline completed successfully.'
        }
        failure {
            echo 'Pipeline failed. Later stages, including deployment, were not completed.'
        }
    }
}

