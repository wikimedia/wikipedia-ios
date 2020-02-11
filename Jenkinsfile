def IS_BETA = false

pipeline {
  agent any
  
  triggers { 
    pollSCM('H/3 * * * *') 
  }
  stages {
    stage('Test') {
      steps {
        sh '''rm -rf build/reports
        export LANG=en_US.UTF-8
        export LANGUAGE=en_US.UTF-8
        export LC_ALL=en_US.UTF-8
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