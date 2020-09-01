// NOTE:
//   we are now using a legacy Jenkins feature `Trigger builds remotely`
//   but is NOT supported by Jenkinsfile, need to configure it manually
//   DO remember to check if the paramter is set correctly after apply.
//
//   also, any change within the block of `properties()` might result in next
//   build failure, it's limitation of Jenkins WebUI limitation by design,
//   it's not a bug, don't report it as bug!!!

def etcdServiceEndpointsStag = [
    'http://35.229.178.57:2379',
    'http://35.194.226.164:2379',
    'http://35.229.192.119:2379',
]

def etcdServiceEndpointsProd = [
    'http://35.227.155.196:2379',
    'http://35.247.92.108:2379',
    'http://35.230.16.11:2379',
]

def etcdServiceEndpointsStagWave = [
    'http://104.155.199.157:2379',
    'http://34.80.119.114:2379',
    'http://130.211.252.145:2379',
]

def etcdServiceEndpointsProdWave = [
    'http://35.221.189.46:2379',
    'http://104.199.161.59:2379',
    'http://34.80.98.223:2379',
]


properties([
    buildDiscarder(
        logRotator(
            numToKeepStr: '30'
        )
    ),
    disableConcurrentBuilds(),
    parameters([
        string(
            defaultValue: '',
            description: 'Commit ID of the Configs Changes',
            name: 'REVISION',
            trim: true
        ),
        string(
            defaultValue: etcdServiceEndpointsStag.join(','),
            description: 'ETCD Service Endpoints List for the 17App Service (Staging)',
            name: 'ENDPOINTS_17APP_STA',
            trim: true
        ),
        string(
            defaultValue: etcdServiceEndpointsProd.join(','),
            description: 'ETCD Service Endpoints List for the 17App Service (Production)',
            name: 'ENDPOINTS_17APP_PROD',
            trim: true
        ),
        string(
            defaultValue: etcdServiceEndpointsStagWave.join(','),
            description: 'ETCD Service Endpoints List for the Wave Service (Staging)',
            name: 'ENDPOINTS_WAVE_STA',
            trim: true
        ),
        string(
            defaultValue: etcdServiceEndpointsProdWave.join(','),
            description: 'ETCD Service Endpoints List for the Wave Service (Production)',
            name: 'ENDPOINTS_WAVE_PROD',
            trim: true
        ),
        booleanParam(
            defaultValue: true,
            description: 'Enable Slack Notification?',
            name: 'SEND_SLACK'
        )]
    )
])


node('gcp') { timestamps { ansiColor('xterm') {
  stage('Input Validation') {
    // cleanup before start
    deleteDir()

    // prepare for configs repository
    sh('mkdir -p configs')
    dir('configs') {
      git url: 'git@github.com:17media/configs.git',
          credentialsId: '3dc01492-01f6-4be5-8073-8de5f458ed1e',
          branch: 'master'

      inputRevision = params.REVISION.trim()
      if (inputRevision.length() > 0) {
        // check tag existence
        chk1 = sh(returnStdout: true, script: 'git for-each-ref refs')

        // check commit existence
        chk2 = sh(returnStdout: true, script: 'git cat-file -t "' + inputRevision + '"')

        if (chk1.contains(inputRevision) || chk2.contains("commit")) {
          sh("git reset HEAD --hard")
          sh("git checkout $REVISION")
        } else {
          error "[abort] specific revision not exist?"
        }
      } else {
        echo "[skip] no REVISION input, use HEAD revision"
      }
    }
  } // end of stage

  stage('Push Changes to ETCD Clusters') {
    dir('configs') {
      // get DOCKER_USER/DOCKER_PASS from Jenkins credential provider
      withCredentials([
          usernamePassword(
              credentialsId: 'f2c9dec6-bad6-4f91-a21d-327c8c547954',
              passwordVariable: 'DOCKER_PASS',
              usernameVariable: 'DOCKER_USER'
          )
      ]) {
        def message_prefix = ''
        def getSlackUserId = "git log --format=%B -n 1 " + params.REVISION + " | awk '/slackUserID: /{print \$2}'"
        def slackUserID = sh(returnStdout: true, script: getSlackUserId)
        if (slackUserID.trim().length() > 0) {
            echo "[debug] slackUserID: " + slackUserID.trim()
            message_prefix = '<@' + slackUserID.trim() + '>\n'
        }
        def commit_msg_script = "git log --format=%B -n 1|head -n 1"
        def commit_msg = sh(returnStdout: true, script: commit_msg_script).trim()

        def githubCommitLink = 'https://github.com/17media/configs/commit/' + params.REVISION
        def message_started = message_prefix + '17media/configs - Job Start\n*Title:* `' + commit_msg + '`\n*Commit:* <'     + githubCommitLink + '|' + params.REVISION + '> (<' + env.BUILD_URL + '|Jenkins>)'
        def message_failure = message_prefix + '17media/configs - Job Failed\n*Title:* `' + commit_msg + '`\n*Commit:* <'    + githubCommitLink + '|' + params.REVISION + '> (<' + env.BUILD_URL + '|Jenkins>)\n@sre @here'
        def message_success = message_prefix + '17media/configs - Job Completed\n*Title:* `' + commit_msg + '`\n*Commit:* <' + githubCommitLink + '|' + params.REVISION + '> (<' + env.BUILD_URL + '|Jenkins>)'

        // force exit if job execution time over 600 seconds
        timeout(time: 600, unit: 'SECONDS') {
          // post slack message before job start
          postNotification(message_started, 'good')

          try {
            sh("docker version")
            sh("docker login -u ${DOCKER_USER} -p ${DOCKER_PASS}")
            sh('./push_to_etcd.sh')
          } catch (e) {
            // post slack message if job failed
            postNotification(message_failure, 'danger')
            error "failed"
          }

          // post slack message after job completed
          postNotification(message_success, 'good')
        } // end of timeout
      }
    } // end of dir
  } // end of stage
} /* end of ansiColor */ } /* end of timestamps */ } /* end of node */

def postNotification(message, color) {
  if (params.SEND_SLACK) {
    slackSend(
      baseUrl: 'https://17media.slack.com/services/hooks/jenkins-ci/',
      tokenCredentialId: '883d8435-4b52-48cb-a282-c7995cb26b69',
      channel: 'CHUGHHX0S',
      failOnError: true,
      message: message,
      color: color,
    )
  }
}
