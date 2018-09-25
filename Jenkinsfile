pipeline {
  agent any
  
  stages {
    stage('Test') {
      triggers { pollSCM('H/3 * * * *') }
      steps {
        sh '''rm -rf build/reports
        eval "$(rbenv init -)"
        bundle install
        scripts/carthage_bootstrap
        bundle exec fastlane verify_pull_request
        '''
        junit '**/build/reports/*.junit'
      }
    }
  }
}