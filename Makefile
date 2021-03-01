# Write makefile output to /tmp
# TODO(ebrown): Check if 'ts' is installed and pipe to it too
LOGDATE = $(shell date "+%Y-%m-%d")
MAKE_LOGFILE = /tmp/dotfiles-output.$(LOGDATE)

install:
	@echo "$(shell date): Running make install" >> $(MAKE_LOGFILE)
	./git_sync.sh 2>&1 | tee -a $(MAKE_LOGFILE)
	$(MAKE) os-install
	$(MAKE) common-install
	@echo "***  YOU MUST REBOOT **IF** this was   ***"
	@echo "***  the first time you've setup       ***"
	@echo "***  khan-dotfiles (i.e. if you are    ***"
	@echo "***  onboarding)                       ***"
	@echo "***  (Reboot is required for browser   ***"
	@echo "***  to pickup CA for khanacademy.dev) ***"
	@echo ""
	@echo "To finish your setup, head back to the"
	@echo "setup docs:"
	@echo "  https://khanacademy.atlassian.net/wiki/x/VgKiC"

os-install:
	if [ `uname -s` = Linux ]; then \
		echo "$(shell date): Running linux-setup.sh" >> $(MAKE_LOGFILE); \
		./linux-setup.sh 2>&1 | tee -a $(MAKE_LOGFILE); \
	fi
	if [ `uname -s` = Darwin ]; then \
		echo "$(shell date): Running mac-setup.sh" >> $(MAKE_LOGFILE); \
		./mac-setup.sh 2>&1 | tee -a $(MAKE_LOGFILE); \
	fi

common-install:
	@echo "$(shell date): Running setup.sh" >> $(MAKE_LOGFILE)
	./setup.sh

virtualenv:
	@echo "$(shell date): Running rebuild_virtualenv.sh" >> $(MAKE_LOGFILE)
	./bin/rebuild_virtualenv.sh 2>&1 | tee -a $(MAKE_LOGFILE)

