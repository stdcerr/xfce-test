.PHONY: build xephyr setup exec-only all manual-session

# resolution of the test X server
# TBD: define what the minimal supported resolution is
export RESOLUTION=1024x768

# use this X display number for the tests
export DISPLAY_NUM=1

# set SCREENSHOTS to ALWAYS to get screenshots during behave tests
export SCREENSHOTS=NONE

export FFMPEG_CMD=$(shell which ffmpeg || echo NO_FFMPEG)
export FFPLAY_CMD=$(shell which ffplay || echo NO_FFPLAY)

# for experimenting you might want to start with
# make manual-session

$(info Don't forget to run make build or make pull)

all: behave-tests

check_env:
	if [ -z SRC_DIR ]; then echo "Please, set SRC_DIR where your sources are"; exit 1; fi

#use this to compile a git directory you have locally (even maybe modified)
compile-local: check_env xephyr
	-podman run --tty --interactive \
              --env DISPLAY=":$(DISPLAY_NUM)" \
              --env SCREENSHOTS=$(SCREENSHOTS) \
              --volume /tmp/.X11-unix:/tmp/.X11-unix --volume $(SRC_DIR):/data \
              stdcerr/xfce-test:latest /bin/bash

# see compile-local
# this starts as root to be able to install stuff with apt
compile-local-root: check_env xephyr
	-podman run --tty --interactive --user 0:0 \
              --name xfce-test \
              --env DISPLAY=":$(DISPLAY_NUM)" \
              --env SCREENSHOTS=$(SCREENSHOTS) \
              --volume /tmp/.X11-unix:/tmp/.X11-unix --volume $(SRC_DIR):/data \
              stdcerr/xfce-test:latest /bin/bash

test: behave-tests

#only a helper for ubuntu
setup:
	sudo apt install -y xserver-xephyr podman.io
	sudo apt install -y xvfb ffmpeg

behave-tests:  test-setup run-behave-tests test-teardown
debug:  test-setup debug-behave-tests test-teardown

xephyr:
	-killall -q Xephyr
	Xephyr :$(DISPLAY_NUM) -ac -screen $(RESOLUTION) &

pull:
	podman pull stdcerr/xfce-test

build:
	podman build --build-arg DOWNLOAD_DATE=$(shell date +%Y%m%d) --tag stdcerr/xfce-test:latest .

test-setup: xephyr
	-podman rm xfce-test
	-podman run --name xfce-test --detach \
              --env DISPLAY=":$(DISPLAY_NUM)" \
              --env LDTP_DEBUG=2 \
              --env SCREENSHOTS=$(SCREENSHOTS) \
	      --volume $(shell pwd):/data \
              --volume /tmp/.X11-unix:/tmp/.X11-unix:z \
              stdcerr/xfce-test:latest

test-teardown:
	-podman exec xfce-test xfce4-session-logout --logout
	-podman stop xfce-test
	-podman rm xfce-test
	-podman exec xfce-test-travis xfce4-session-logout --logout
	-podman stop xfce-test-travis
	-podman rm xfce-test-travis
	-killall -q Xephyr
	-sudo rm -rf /tmp/.X11-unix/X$(DISPLAY_NUM) /tmp/.X$(DISPLAY_NUM)-lock

manual-session: test-setup run-manual-session test-teardown

run-manual-session:
	-podman exec --tty --interactive xfce-test /bin/bash

run-behave-tests:
	podman exec --tty xfce-test bash -c "cd /data/behave;behave"
	podman exec --tty xfce-test bash -c "cat ~xfce-test_user/version_info.txt"

debug-behave-tests:
	podman exec --tty xfce-test bash -c "cd /data/behave;behave -D DEBUG_ON_ERROR"
	podman exec --tty xfce-test bash -c "cat ~xfce-test_user/version_info.txt"

$(FFMPEG_CMD):
	echo Please install ffmpeg
	exit 1
$(FFPLAY_CMD):
	echo Please install ffplay
	exit 1

recording-test: $(FFMPEG_CMD) $(FFPLAY_CMD)
	Xvfb :99 -ac -screen 0 800x600x24 &
	podman run --name xfce-test-travis --detach --env DISPLAY=:99.0 --volume /tmp/.X11-unix:/tmp/.X11-unix stdcerr/xfce-test:latest /usr/bin/dbus-run-session /usr/bin/ldtp
	sleep 5
	echo "Starting testframework..." > text.txt
ifdef DEBUG
	ffmpeg -y -r 30 -f x11grab -s 800x600 -i :99.0 -vf "drawtext=fontfile=Vera.ttf:textfile=text.txt:reload=1:fontcolor=white: fontsize=12: box=1: boxcolor=black@0.5:y=500" -c:v libx264 -f mpegts - 2>video_log | tee video.ts |ffplay - &
else
	ffmpeg -y -r 30 -f x11grab -s 800x600 -i :99.0 -vf "drawtext=fontfile=Vera.ttf:textfile=text.txt:reload=1:fontcolor=white: fontsize=12: box=1: boxcolor=black@0.5:y=500" -c:v libx264 -f mpegts - 2>video_log > video.ts &
endif
	sleep 5
	podman exec --detach xfce-test-travis xfce4-session
	podman cp behave xfce-test-travis:/tmp
	# we need to use the mv command to avoid ffmpeg crashes
	podman exec xfce-test-travis bash -c "cd /tmp/behave;behave -D DEBUG_ON_ERROR"|while read LINE; do echo "$$LINE" | tee -a text_all.txt; tail -n5 text_all.txt > text_cut.txt;mv text_cut.txt text.txt; done
	-kill $$(cat /tmp/.X99-lock)
	-podman stop xfce-test-travis
	-podman rm xfce-test-travis
	-killall -q ffmpeg ffplay

# internal function - call screenshots instead
do-screenshots:
	podman exec --tty xfce-test bash -c "cd /data/behave; behave -i screenshots"
	podman exec --tty xfce-test bash -c "cat ~xfce-test_user/version_info.txt"
	podman exec xfce-test xfce4-session-logout --logout

screenshots: test-setup do-screenshots test-teardown

do-language-test:
	mkdir -p lang-screenshots
	chmod a+rwx lang-screenshots
	podman exec --tty xfce-test bash -c "cd /data/lang-screenshots; /data/container_scripts/all_langs.sh"
	podman exec xfce-test xfce4-session-logout --logout

language-test: test-setup do-language-test test-teardown


