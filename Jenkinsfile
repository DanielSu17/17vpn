// NOTE:
//   we are now using a legacy Jenkins feature `Trigger builds remotely`
//   but is NOT supported by Jenkinsfile, need to configure it manually
//   DO remember to check if the paramter is set correctly after apply.
//
//   also, any change within the block of `properties()` might result in next
//   build failure, it's limitation of Jenkins WebUI limitation by design,
//   it's not a bug, don't report it as bug!!!


def slackWebhook = 'https://hooks.slack.com/services/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'

def etcdServiceEndpointsStag = [
    'http://35.229.178.57:2379',
    'http://35.194.226.164:2379',
    'http://35.229.192.119:2379',
]

def etcdServiceEndpointsProd= [
    'http://35.199.166.20:2379',
    'http://35.199.147.165:2379',
    'http://35.233.174.116:2379',
]

def etcdServiceEndpointsStagLit = [
    'http://35.229.240.3:2379',
    'http://35.236.170.250:2379',
    'http://104.199.253.3:2379',
]

def etcdServiceEndpointsProdLit = [
    'http://35.201.170.180:2379',
    'http://35.236.170.122:2379',
    'http://35.194.146.236:2379',
]

def etcdServiceEndpointsStagZoo = [
    'http://34.80.37.202:2379',
    'http://34.80.57.68:2379',
    'http://34.80.57.203:2379',
]

def etcdServiceEndpointsProdZoo = [
    'http://34.80.37.202:2379',
    'http://34.80.57.68:2379',
    'http://34.80.57.203:2379',
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
            defaultValue: slackWebhook,
            description: 'Slack Webhook for Notification',
            name: 'SLACK_URL',
            trim: true
        ),
        string(
            defaultValue: etcdServiceEndpointsStag.join(','),
            description: 'ETCD Service Endpoints List for the 17App Service (Staging)',
            name: 'ENSEMBLEIPS_STA',
            trim: true
        ),
        string(
            defaultValue: etcdServiceEndpointsProd.join(','),
            description: 'ETCD Service Endpoints List for the 17App Service (Production)',
            name: 'ENSEMBLEIPS_PROD',
            trim: true
        ),
        string(
            defaultValue: etcdServiceEndpointsStagLit.join(','),
            description: 'ETCD Service Endpoints List for the Lit Service (Staging)',
            name: 'ENSEMBLEIPS_LIT_STA',
            trim: true
        ),
        string(
            defaultValue: etcdServiceEndpointsProdLit.join(','),
            description: 'ETCD Service Endpoints List for the Lit Service (Production)',
            name: 'ENSEMBLEIPS_LIT_PROD',
            trim: true
        ),
        string(
            defaultValue: etcdServiceEndpointsStagZoo.join(','),
            description: 'ETCD Service Endpoints List for the Zoo Service (Staging)',
            name: 'ENSEMBLEIPS_ZOO_STA',
            trim: true
        ),
        string(
            defaultValue: etcdServiceEndpointsProdZoo.join(','),
            description: 'ETCD Service Endpoints List for the Zoo Service (Production)',
            name: 'ENSEMBLEIPS_ZOO_PROD',
            trim: true
        ),
        booleanParam(
            defaultValue: false,
            description: 'Refresh pushToEtcd-linux?',
            name: 'REFRESH_EXECUTABLE_BINARY'
        )]
    )
])


node { timestamps { ansiColor('xterm') {
  stage('Input Validation') {
    // cleanup before start
    cleanWs(deleteDirs: true,
            notFailBuild: true,
            patterns: [[
                pattern: 'pushToEtcd-linux',
                type: 'EXCLUDE'
            ]]
    )

    // basic validation for the input values
    if (params.REVISION.length() <= 0) {
        error('invalid revision input')
    }

    if (params.SLACK_URL.length() <= 0) {
        error('invalid slack webhook')
    }

    if (params.ENSEMBLEIPS_STA.length() <= 0) {
        error('invalid etcd cluster endpoints input (17app stag)')
    }

    if (params.ENSEMBLEIPS_PROD.length() <= 0) {
        error('invalid etcd cluster endpoints input (17app prod)')
    }

    if (params.ENSEMBLEIPS_LIT_STA.length() <= 0) {
        error('invalid etcd cluster endpoints input (lit stag)')
    }

    if (params.ENSEMBLEIPS_LIT_PROD.length() <= 0) {
        error('invalid etcd cluster endpoints input (lit prod)')
    }

    if (params.ENSEMBLEIPS_ZOO_STA.length() <= 0) {
        error('invalid etcd cluster endpoints input (zoo stag)')
    }

    if (params.ENSEMBLEIPS_ZOO_PROD.length() <= 0) {
        error('invalid etcd cluster endpoints input (zoo prod)')
    }
  } // end of stage

  stage('Setup Environment') {
    // if `pushToEtcd-linux` not exist, or explicitly download enabled
    // download latest `pushToEtcd-linux` executable binary from AWS S3
    // source code of the `pushToEtcd-linux` could be found under the following path
    // - https://github.com/17media/api/blob/master/infra/deploy/configs/pushToEtcd.go
    if ((! fileExists("pushToEtcd-linux") || params.REFRESH_EXECUTABLE_BINARY)) {
      sh("wget --quiet https://s3-us-west-2.amazonaws.com/17scripts/configs_push_to_etcd/pushToEtcd-linux -O ./pushToEtcd-linux")
    } else {
      echo("[skip download]")
    }

    sh('mkdir -p configs')
    dir('configs') {
      git url: 'git@github.com:17media/configs.git',
          credentialsId: '3dc01492-01f6-4be5-8073-8de5f458ed1e',
          branch: 'master'

      sh("cp ../pushToEtcd-linux .")
      sh("chmod +x ./pushToEtcd-linux")
      sh("./pushToEtcd-linux --version")
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
        // force exit if job execution time over 300 seconds
        timeout(time: 300, unit: 'SECONDS') {
          sh("./pushToEtcd-linux --commit_id \"" + params.REVISION + "\"")
        } // end of timeout
      }
    } // end of dir
  } // end of stage
} /* end of ansiColor */ } /* end of timestamps */ } /* end of node */
