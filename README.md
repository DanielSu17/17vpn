# configs
repository of configure files for 17 apps

## git hook

### install pre-commit

```
make install 
```

Current `pre-commit` is not compatible with Python3, so make sure Python2 is used. And there will be three Python packages installed by this command. Make a virtual environment before installing if you do not want them be installed in your global environment. If you can't install `ruamel.yaml`, run `pip install --upgrade setuptools --user python` to upgrade setuptools

You can check the config syntax manually:

```
./circle/syntax_checker.py
```

## Add new configs

When you add new configs, remember to add them to stag and prod folder even in developmemt.

## Update i18n files

### install requirement
```
cd tools;pip install -r pip.require;cd -
```

### Pull i18n translations from lokalise

```
cd tools; ./update_i18n.py [-h] {dev,sta,prod,all}; cd -
```

## Using KMS encryption/decryption

### install macgyver
```
go get -u github.com/17media/macgyver
```
There're details for how to use macgyver in the [README.md](https://github.com/17media/macgyver).

### [gcloud](https://cloud.google.com/sdk/gcloud/?hl=zh-TW) login
```
gcloud auth application-default login
```

### ensure you have KMS permission to encrypt/decrypt data
If you see the following error when executing macgyver, it means you don't have permission to use KMS.

```
Error 403: Permission 'cloudkms.cryptoKeyVersions.useToEncrypt' denied for resource
'projects/media17-stag/locations/global/keyRings/app/cryptoKeys/runtime'
```

[Apply for KMS permission for config encryption depends on environments](https://github.com/17media/infrastructure/issues/new/choose).  
`staging`: `projects/media17-stag/locations/global/keyRings/app/cryptoKeys/runtime`  
`production`: `projects/media17-prod/locations/global/keyRings/app/cryptoKeys/runtime`

### encrypt the data
Replace the value of `--flags` in the following command.
In this case, `bar` and `hihihi` will be encrypted in the format `<SECRET_TAG>.*</SECRET_TAG>`.
```
macgyver encrypt \
          --cryptoProvider=gcp \
          --GCPprojectID="media17-prod" \
          --GCPlocationID="global" \
          --GCPkeyRingID="app" \
          --GCPcryptoKeyID="runtime" \
          --flags="-foo=bar -other=hihihi"
```
The output would be
```
-foo=<SECRET_TAG>CiQAOHuFgPTq3XpMbxBPkw30Y/GC9xyLA9ekNDNbPL2HeBrS0mgSKwCdNR9AESxrBf/yEJHPd2DXFcPcueM6kfopCsnY8gPzSztRyheqYYE4np4=</SECRET_TAG> -other=<SECRET_TAG>CiQAOHuFgOcOFMouDu6pfZmdBDK+AHwKI6pOPzBBRPbz2Qmxp40SLwCdNR9APyF4WGPu1XuVpb/IEWCnAh5xj180VvK5nOEUPtXxgjAix3gVEiEBaLPZ</SECRET_TAG>
```
This process requires encrypting permission of gcp's kms keys. Ask #sre for more information.

### import kms service in your config's Check
There're examples in `stores/gift/factory/slot/impl.go` and `stores/pay/verifier/gmo/gmo.go`
for how to use kms decryption in your config.

### fill it into config files
Make sure the service running your config is on the version which is able to do kms decryption. 
Then you can modify your config file as following.
```
config:
  foo: <SECRET_TAG>CiQAm......Tjfc2UaY=</SECRET_TAG>
  other: "<SECRET_TAG>CiPmA......JkcID</SECRET_TAG>"
```
After kms.DecryptAll() in config.Check(), the file blob will be transformed as following.
```
config:
  foo: bar
  other: "hihihi"
```


## Push Configs via Jenkins

1. Login to Jenkins Master - https://jenkins-gogo.17app.co/

2. Find the Job named: `17media-config-gcp`

3. Hit the button `Build with Parameters` on the left hand side panel

4. Fill-in the field: `REVISION` with commit hash

5. Hit the button `Build` on the middle of the page

6. Done, verify the result by log output

## Push Configs from Local Machine

1. make sure you are connected to **PRITUNL-PROD** or **PRITUNL-STAG**
2. pull the latest `etcd-pusher` from DockerHub

```
$ docker pull 17media/pusher:v19.4.25
```

3. Get etcd endpoints prepared

```
$ gcloud --project [media17-prod|media17-stag] compute instances list --filter='(name ~ etcd*)'

NAME    ZONE        EXTERNAL_IP  STATUS
etcd-1  us-west1-a  1.1.1.87     RUNNING
etcd-2  us-west1-b  1.1.1.88     RUNNING
etcd-3  us-west1-c  1.1.1.89     RUNNING
```

4. Push configs to etcd cluster

```
$ export ENDPOINTS='http://1.1.1.87:2379,http://1.1.1.88:2379,http://1.1.1.89:2379' # the endpoints should be exactly the same as the output of `step 3`

$ cd /path/to/configs
$ git checkout master
$ git pull origin master # or rebase

$ ./circle/syntax_checker.py

$ git add ...
$ git commit ...
$ git push origin master

$ docker run --rm                   \
    -e ENVIRONMENT='sta'            \
    -e APPLICATION='17app'          \
    -e ENDPOINTS=${ENDPOINTS}       \
    -v $(pwd):/configs:ro           \
    -t 17media/pusher:v19.4.25
```

all the steps above could be found in the following script:
- https://github.com/17media/configs/blob/master/push_to_etcd.sh

5. Pitfalls

!!! **BEWARE** !!! after your commit push to GitHub, it will trigger CircleCI for the syntax check automatically,
once the syntax check is done, it will next trigger Jenkins for `configs` deployment automatically.

so, it is important to stop/prevent CircleCI/Jenkins from push `configs` again,
you push the `configs` locally, multiple times, or it might have been reverted after Jenkins push.
