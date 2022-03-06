#!/bin/bash
# Configure ceph for eucalyptus use and create eucalyptus deployment
# artifacts
set -euo pipefail

EUCA_POOL_PLACEMENT_GROUPS="${EUCA_POOL_PLACEMENT_GROUPS:-100}"
EUCA_CEPH_ARTIFACTS_DIR="${EUCA_CEPH_ARTIFACTS_DIR:-euca-artifacts}"
EUCA_CEPH_MIN_CLIENT="${EUCA_CEPH_MIN_CLIENT:-}"
EUCA_CEPH_VOLUME_POOL_NAME="${EUCA_CEPH_VOLUME_POOL_NAME:-eucavolumes}"
EUCA_CEPH_SNAPSHOT_POOL_NAME="${EUCA_CEPH_SNAPSHOT_POOL_NAME:-eucasnapshots}"
EUCA_CEPHRGW_UID="${EUCA_CEPHRGW_UID:-eucas3}"

if ! ceph osd pool ls | grep -q ${EUCA_CEPH_VOLUME_POOL_NAME} ; then
    echo "Generating volume pool ${EUCA_CEPH_VOLUME_POOL_NAME}"
    ceph osd pool create ${EUCA_CEPH_VOLUME_POOL_NAME} ${EUCA_POOL_PLACEMENT_GROUPS}
    ceph osd pool application enable ${EUCA_CEPH_VOLUME_POOL_NAME} rbd 2>/dev/null || true
fi

if [ "${EUCA_CEPH_VOLUME_POOL_NAME}" != "${EUCA_CEPH_SNAPSHOT_POOL_NAME}" ] ; then
    if ! ceph osd pool ls | grep -q ${EUCA_CEPH_SNAPSHOT_POOL_NAME} ; then
        echo "Generating snapshot pool ${EUCA_CEPH_SNAPSHOT_POOL_NAME}"
        ceph osd pool create ${EUCA_CEPH_SNAPSHOT_POOL_NAME} ${EUCA_POOL_PLACEMENT_GROUPS}
        ceph osd pool application enable ${EUCA_CEPH_SNAPSHOT_POOL_NAME} rbd 2>/dev/null || true
    fi
fi

if [ -n "${EUCA_CEPH_MIN_CLIENT}" ] ; then
    ceph osd set-require-min-compat-client "${EUCA_CEPH_MIN_CLIENT}"
fi

if [ ! -e "${EUCA_CEPH_ARTIFACTS_DIR}" ] ; then
    echo "Creating eucalyptus artifacts directory"
    mkdir -p "${EUCA_CEPH_ARTIFACTS_DIR}"
fi

if ! ceph auth list 2>&1 | grep -q euca ; then
    echo "Generating S3 user for radosgw"
    ceph auth get-or-create client.eucalyptus \
      mon 'allow r' \
      osd 'allow rwx pool=rbd, allow rwx pool='${EUCA_CEPH_SNAPSHOT_POOL_NAME}', allow rwx pool='${EUCA_CEPH_VOLUME_POOL_NAME}', allow x' \
      -o "${EUCA_CEPH_ARTIFACTS_DIR}/ceph.client.eucalyptus.keyring"
fi

if ! radosgw-admin metadata list user | grep -q euca ; then
    echo "Generating radowsgw (rgw) S3 user"
    radosgw-admin user create --uid=${EUCA_CEPHRGW_UID} --display-name="Eucalyptus S3 User" \
      | egrep '(user"|access_key|secret_key)' \
      | sed --expression='1 i\{' --expression='$ a\}' \
      > "${EUCA_CEPH_ARTIFACTS_DIR}/rgw_credentials.json"
fi

if [ ! -e "${EUCA_CEPH_ARTIFACTS_DIR}/ceph.conf" ] ; then
    echo "Copying ceph.conf file"
    cp "/etc/ceph/ceph.conf" "${EUCA_CEPH_ARTIFACTS_DIR}/ceph.conf"
fi
