pipeline {
    agent any

    environment {
        DOTNET_PATH = 'C:\\Program Files\\dotnet'
        DOCKER_PATH = 'C:\\Program Files\\Docker\\Docker\\resources\\bin'
        TERRAFORM_PATH = 'C:\\Program Files\\terraform_1.11.4_windows_amd64'
        AZURE_CLI_PATH = 'C:\\Program Files\\Microsoft SDKs\\Azure\\CLI2\\wbin'
        
        PATH = "${DOTNET_PATH};${DOCKER_PATH};${TERRAFORM_PATH};${AZURE_CLI_PATH};${PATH}"
        
        ACR_NAME = 'acr150425assignment'
        AZURE_CREDENTIALS_ID = 'service-principal-kubernetes'
        ACR_LOGIN_SERVER = "${ACR_NAME}.azurecr.io"
        IMAGE_NAME = 'api-kubernetes150425'
        IMAGE_TAG = 'latest'
        RESOURCE_GROUP = 'rg-aks-assignment'
        AKS_CLUSTER = 'aks150425assignment'
        TF_WORKING_DIR = 'terraform'
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/Atishay-Jain01/Terraform-Jenkins-Docker-DotNet.git'
            }
        }

        stage('Build .NET App') {
            steps {
                bat 'dotnet publish DotNetWebAPI\\DotNetWebAPI.csproj -c Release -o out'
            }
        }

        stage('Build Docker Image') {
            steps {
                bat "docker build -t %ACR_LOGIN_SERVER%/%IMAGE_NAME%:%IMAGE_TAG% -f DotNetWebAPI/Dockerfile DotNetWebAPI"
            }
        }

       stage('Terraform Init') {
            steps {
                withCredentials([azureServicePrincipal(credentialsId: AZURE_CREDENTIALS_ID)]) {
                    bat """
                    echo "Navigating to Terraform Directory: %TF_WORKING_DIR%"
                    cd %TF_WORKING_DIR%
                    echo "Initializing Terraform..."
                    terraform init
                    """
                }
            }
        }

        stage('Terraform Plan') {
            steps {
                withCredentials([azureServicePrincipal(credentialsId: AZURE_CREDENTIALS_ID)]) {
                    bat """
                    echo "Navigating to Terraform Directory: %TF_WORKING_DIR%"
                    cd %TF_WORKING_DIR%
                    terraform plan -out=tfplan
                    """
                }
            }
        }


        stage('Terraform Apply') {
    steps {
        withCredentials([azureServicePrincipal(credentialsId: AZURE_CREDENTIALS_ID)]) {
            bat """
            echo "Navigating to Terraform Directory: %TF_WORKING_DIR%"
            cd %TF_WORKING_DIR%
            echo "Applying Terraform Plan..."
            terraform apply -auto-approve tfplan
            """
        }
    }
}
        stage('Login to ACR') {
            steps {
                bat "az acr login --name %ACR_NAME%"
            }
        }

        stage('Push Docker Image to ACR') {
            steps {
                bat "docker push %ACR_LOGIN_SERVER%/%IMAGE_NAME%:%IMAGE_TAG%"
            }
        }

        stage('Get AKS Credentials') {
            steps {
                bat "az aks get-credentials --resource-group %RESOURCE_GROUP% --name %AKS_CLUSTER% --overwrite-existing"
            }
        }

        stage('Deploy to AKS') {
            steps {
                bat "kubectl apply -f WebApiJenkins/test.yaml"
            }
        }
    }

    post {
        success {
            echo 'All stages completed successfully!'
        }
        failure {
            echo 'Build failed.'
        }
    }
}
