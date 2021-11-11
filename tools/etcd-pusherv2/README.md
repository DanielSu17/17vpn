# Description

Dockerized toolkit for pushing configs to etcd cluster

# Usage

### How to build etcd-pusher tool?

    $ docker build -t 17media/pusherv2:v21.10.22 .

### How to push 17media/configs to etcd cluster v3?

    $ cd /path-to-configs
    $ docker run --rm                                                         \
        -v $(pwd):/configs:ro                                                 \
        -it 17media/pusherv2:v21.10.22                                        \
          /opt/pusher                                                         \
            -csi.config.repo.root /configs/envs/${ENVIRONMENT}                \
            -csi.config.etcd.root /configs/envs/${ENVIRONMENT}                \
            -csi.config.etcd.machines ${ENDPOINTS}

# Maintainer

- sre@17.media
