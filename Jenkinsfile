pipeline {
  agent any
  
  triggers { 
    pollSCM('H/3 * * * *') 
  }
  stages {
    stage('Test') {
      steps {
        sh '''rm -rf build/reports
        eval "$(rbenv init -)"
        bundle install
        bundle exec fastlane verify_pull_request
        '''
      }
      post {
        always {
          junit '**/build/reports/*.junit'
        }
      }
    }
  }
}