pipeline {
  agent any
  
  triggers { 
    pollSCM('H/3 * * * *') 
  }
  stages {
    stage('Test') {
      steps {
        try {
          sh '''rm -rf build/reports
          eval "$(rbenv init -)"
          bundle install
          scripts/carthage_bootstrap
          bundle exec fastlane verify_pull_request
          '''
        } finally {
          junit '**/build/reports/*.junit'
        }
      }
    }
  }
}