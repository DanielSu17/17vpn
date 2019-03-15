# configs
repository of configure files for 17 apps

## git hook

### install pre-commit

```
make install
```

Current `pre-commit` is not compatible with Python3, so make sure Python2 is used. And there will be three Python packages installed by this command. Make a virtual environment before installing if you do not want them be installed in your global environment.

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
