pipeline {
  agent any
  
  stages {
    stage('Test') {
      steps {
        sh '''rm -rf build/reports
        scripts/setup_rbenv_and_ruby
        scripts/carthage_bootstrap
        bundle exec fastlane verify_pull_request
        '''
        junit '**/build/reports/*.junit'
      }
    }
  }
}