install:
	./git_sync.sh
	$(MAKE) os-install
	$(MAKE) common-install

os-install:
	if [ `uname -s` = Linux ]; then ./linux-setup.sh; fi
	if [ `uname -s` = Darwin ]; then ./mac-setup.sh; fi

common-install:
	./setup.sh

virtualenv:
	./rebuild_virtualenv.sh
