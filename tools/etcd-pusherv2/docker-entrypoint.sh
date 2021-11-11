#!/bin/sh

yes yes | /opt/pusher                                \
  -csi.config.repo.root /configs/envs/${ENVIRONMENT} \
  -csi.config.etcd.root /configs/envs/${ENVIRONMENT} \
  -csi.config.etcd.machines ${ENDPOINTS}
