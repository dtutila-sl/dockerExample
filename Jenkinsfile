#!groovy
import groovy.json.JsonSlurperClassic

pipeline {
    agent {                                                             
        label 'localAgent'
    }
    environment {
        SF_USERNAME_DEV = 'jenkins1@silverlinecrm.com.zendev'
        PRIVATE_KEY = credentials('SERVER_KEY_ID')
        CLIENT_ID_DEV = credentials('SF_CLIENT_ID_SRC')
        SF_LOGIN_DEV = 'https://login.salesforce.com'
        SF_DEV_PSW = credentials('SF_LOGIN_SRC_PSW')
        TEST_LEVEL = 'RunLocalTests'
        PACKAGE_NAME = '0Ho8c0000004CILCA2'
        PACKAGE_VERSION = '0.0.0'
    }
    options {
        disableConcurrentBuilds()
        buildDiscarder(logRotator(numToKeepStr: '5'))
        skipDefaultCheckout()
        timeout(time: 120, unit: 'MINUTES')
    }
    stages {                                                           
        stage('Print Environment') {
            steps {
              
                 echo "Checking environment"
                 sh """
                 whoami
                 pwd
                 uname -a
                 ls
                 sfdx version
                 """
            }
        }
        stage('checkout source') {
             steps {
            checkout scm
             sh 'tree'
             }
        }   
        stage('Authorize DevHub') {
           
            steps {
                sh 'sfdx auth:jwt:grant -u ${SF_USERNAME_DEV} -f ${PRIVATE_KEY} -i ${CLIENT_ID_DEV} -r https://login.salesforce.com -a HubOrg'
                sh 'sfdx force:org:display -u ${SF_USERNAME_DEV}'
                echo "Checking out repository..."
                checkout scm
               
                echo "done! ..."
             
            }
        }

        stage('Create Test Scratch Org') {
             steps {
            sh  "sfdx force:org:create --targetdevhubusername HubOrg --setdefaultusername --definitionfile config/project-scratch-def.json --setalias ciorg --wait 10 --durationdays 1"
            sh "sfdx force:org:display --targetusername ciorg"
             }
        }

        stage('Push To Test Scratch Org') {
             steps {
                sh "sfdx force:source:push --targetusername ciorg"
             }
                
        }

        stage('Run Tests In Test Scratch Org') {
             steps {
                sh  "sfdx force:apex:test:run --targetusername ciorg --wait 10 --resultformat tap --codecoverage --testlevel ${TEST_LEVEL}"
             }
              
            }


            

            // -------------------------------------------------------------------------
            // Delete test scratch org.
            // -------------------------------------------------------------------------

            stage('Delete Test Scratch Org') {
                 steps {
                sh "sfdx force:org:delete --targetusername ciorg --noprompt"
                 }
    
            }


            // -------------------------------------------------------------------------
            // Create package version.
            // -------------------------------------------------------------------------

            stage('Create Package Version') {
               steps {
                   script {
                    output = sh returnStdout: true, script: "sfdx force:package:version:create --package ${PACKAGE_NAME} --installationkeybypass --wait 10 --json --targetdevhubusername HubOrg"
               

                // Wait 5 minutes for package replication.
                sleep 300

                def jsonSlurper = new JsonSlurperClassic()
                def response = jsonSlurper.parseText(output)

                PACKAGE_VERSION = response.result.SubscriberPackageVersionId

                response = null

                echo ${PACKAGE_VERSION}
}
               }
            }


            // -------------------------------------------------------------------------
            // Create new scratch org to install package to.
            // -------------------------------------------------------------------------

            stage('Create Package Install Scratch Org') {
                 steps {
                    sh "sfdx force:org:create --targetdevhubusername HubOrg --setdefaultusername --definitionfile config/project-scratch-def.json --setalias installorg --wait 10 --durationdays 1"
                 }
    
            }


            // -------------------------------------------------------------------------
            // Display install scratch org info.
            // -------------------------------------------------------------------------

            stage('Display Install Scratch Org') {
                 steps {
                sh  "sfdx force:org:display --targetusername installorg"
                 }
             
            }


            // -------------------------------------------------------------------------
            // Install package in scratch org.
            // -------------------------------------------------------------------------

            stage('Install Package In Scratch Org') {
                 steps {
               sh "sfdx force:package:install --package ${PACKAGE_VERSION} --targetusername installorg --wait 10"
                 }
               
            }


            // -------------------------------------------------------------------------
            // Run unit tests in package install scratch org.
            // -------------------------------------------------------------------------

            stage('Run Tests In Package Install Scratch Org') {
                 steps {
                sh  "sfdx force:apex:test:run --targetusername installorg --resultformat tap --codecoverage --testlevel ${TEST_LEVEL} --wait 10"
                 }
            
            }


            // -------------------------------------------------------------------------
            // Delete package install scratch org.
            // -------------------------------------------------------------------------

            stage('Delete Package Install Scratch Org') {
                 steps {
                sh "sfdx force:org:delete --targetusername installorg --noprompt"
                 }
               
            }
       
    }
    post {
        always {
            echo 'cleaning up the workspace after build.....'
            deleteDir()
            sh 'echo "###DONE!!"'
            
        }
      
    }
}
