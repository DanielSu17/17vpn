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
    'http://104.199.215.240:2379',
    'http://35.185.155.122:2379',
    'http://35.234.10.65:2379',
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
            trim: false
        ),
        string(
            defaultValue: slackWebhook,
            description: 'Slack Webhook for Notification',
            name: 'SLACK_URL',
            trim: false
        ),
        string(
            defaultValue: etcdServiceEndpointsStag.join(','),
            description: 'ETCD Service Endpoints List for the 17App Service (Staging)',
            name: 'ENSEMBLEIPS_STA',
            trim: false
        ),
        string(
            defaultValue: etcdServiceEndpointsProd.join(','),
            description: 'ETCD Service Endpoints List for the 17App Service (Production)',
            name: 'ENSEMBLEIPS_PROD',
            trim: false
        ),
        string(
            defaultValue: etcdServiceEndpointsStagLit.join(','),
            description: 'ETCD Service Endpoints List for the Lit Service (Staging)',
            name: 'ENSEMBLEIPS_LIT_STA',
            trim: false
        ),
        string(
            defaultValue: etcdServiceEndpointsProdLit.join(','),
            description: 'ETCD Service Endpoints List for the Lit Service (Production)',
            name: 'ENSEMBLEIPS_LIT_PROD',
            trim: false
        )]
    )
])


node { timestamps { ansiColor('xterm') {

  stage('Get configs from git') {
    sh('mkdir -p configs')
    dir('configs') {
      // cleanup before clone
      deleteDir()

      git url: 'git@github.com:17media/configs.git',
          branch: 'master'
    } // end of dir
  } // end of stage

  stage('Get pushToEtcd-linux from S3') {
    // always pull the latest `pushToEtcd-linux` executable binary from s3
    // source code of the `pushToEtcd-linux` could be found under the following path
    // - https://github.com/17media/api/blob/master/infra/deploy/configs/pushToEtcd.go
    sh("wget --quiet https://s3-us-west-2.amazonaws.com/17scripts/configs_push_to_etcd/pushToEtcd-linux -O ./pushToEtcd-linux")
    sh("chmod +x ./pushToEtcd-linux")
    sh("cp ./pushToEtcd-linux ./configs/")

    dir('configs') {
      // get DOCKER_USER/DOCKER_PASS from Jenkins credential provider
      withCredentials([
          usernamePassword(
              credentialsId: 'f2c9dec6-bad6-4f91-a21d-327c8c547954',
              passwordVariable: 'DOCKER_PASS',
              usernameVariable: 'DOCKER_USER'
          )
      ]) {
          // basic validation for the input values
          if (params.REVISION.length() <= 0) {
              error('revision validation failed')
          }

          // check version before execute
          sh("./pushToEtcd-linux --version")

          // push to etcd with specific commit
          sh("./pushToEtcd-linux --commit_id \"" + params.REVISION + "\"")
      }
    } // end of dir
  } // end of stage
} /* end of ansiColor */ } /* end of timestamps */ } /* end of node */
