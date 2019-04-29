#!/bin/sh

yes yes | /opt/pusher                                                \
  -csi.config.repo.root /configs/envs/${ENVIRONMENT}/${APPLICATION}  \
  -csi.config.etcd.root /configs/envs/${ENVIRONMENT}/${APPLICATION}  \
  -csi.config.etcd.machines ${ENDPOINTS}
