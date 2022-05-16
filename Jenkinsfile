pipeline {
    agent any
    environment{
        COMMIT_HASH = sh(returnStdout: true, script: "git rev-parse --short=8 HEAD").trim()
    }
    stages{
        stage('Terraform plan'){
            steps{
                  sh "dir"
                  sh "terraform init"
                  sh "mkdir plans"
                  sh "terraform plan -out plans/plan-${COMMIT_HASH}.tf -no-color > plans/plan-${COMMIT_HASH}.txt"

                  script{
                      env.CHECK_LINE = sh (script: "tail -n 1 plans/plan-${COMMIT_HASH}.txt", returnStdout: true).trim()
                      echo "${CHECK_LINE}"
                }
            }
        }
        stage('Terraform apply'){
            when{
                expression{env.CHECK_LINE != "and found no differences, so no changes are needed."}
            }
            steps{
                dir("terraform"){  
                    sh "terraform apply --auto-approve -no-color plans/plan-${COMMIT_HASH}.tf"
                }
            }
        }
    }
}
