#description:    
    這是一個用來產生不同 region 的 config yaml 的 script，只要先建好一個 .yaml 檔，
    剩下來的 | env | * | region | -1 個 .yaml 檔就可以用此 script 自動建好
#usage:
    ./region_config_generator.sh fileName dirName filePath region1 region2 region3 ...
    1. fileName is the suffix of resulting file names
    2. dirName is the directory of generated files and is under envs/[env]/17app/
    3. filePath is the path of the existed file that will be copied
    4. region1 region2 ... is the regions 
#example:
    ./region_config_generator.sh hashtag.yaml hashtag envs/prod/17app/hashtag/hashtag.yaml TW JP OTHERS 
    This example will generate 8 *.yaml file
    1. envs/prod/17app/hashtag/JP_hathtag.yaml
    2. envs/prod/17app/hashtag/OTHERS_hathtag.yaml
    3. envs/sta/17app/hashtag/hathtag.yaml
    4. envs/sta/17app/hashtag/JP_hathtag.yaml
    5. envs/sta/17app/hashtag/OTHERS_hathtag.yaml
    6. envs/dev/17app/hashtag/hathtag.yaml
    7. envs/dev/17app/hashtag/JP_hathtag.yaml
    8. envs/dev/17app/hashtag/OTHERS_hathtag.yaml 
