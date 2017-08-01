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
