#!/usr/bin/env bash

test_container() {
    TAG=$1
    podman run --detach --env TRAVIS --env TRAVIS_BRANCH --env DISPLAY --env RESOLUTION="1024x768" --volume /tmp/.X11-unix:/tmp/.X11-unix test-xfce-ubuntu:$TAG /usr/bin/dbus-run-session /usr/bin/xfce4-session > .podman_ID
    sleep 10 # give xfce some time to start

    podman exec $(cat .podman_ID) bash -c "cat ~/version_info.txt"

    podman exec --detach $(cat .podman_ID) /usr/bin/dbus-run-session /usr/local/bin/ldtp || podman logs $(cat .podman_ID)
    sleep 10 # give ldtp some time to start

    podman exec $(cat .podman_ID) bash -c "/container_scripts/full_test_video.sh" || podman logs $(cat .podman_ID)

    podman exec $(cat .podman_ID) bash -c "echo \"${clientsecrets}\" |base64 -d > /container_scripts/client_secrets.json"
    podman exec $(cat .podman_ID) bash -c "echo \"${uploadvideooauth2}\" |base64 -d > /container_scripts/upload-video.py-oauth2.json "
    podman exec $(cat .podman_ID) bash -c "/container_scripts/upload-video-travis.sh"  || podman logs $(cat .podman_ID)

    podman exec $(cat .podman_ID) bash -c "ls -la /data"
    podman exec $(cat .podman_ID) bash -c "ls -la /container_scripts"

    podman exec $(cat .podman_ID) bash -c "cat ~/version_info.txt"
    podman exec $(cat .podman_ID) bash -c "ls -la /tmp/*.log"
    podman exec $(cat .podman_ID) bash -c "cat /tmp/*.log"

    podman exec $(cat .podman_ID) bash -c "apt-cache policy libgtk-3-0"
}

test_container devel

