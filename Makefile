install: os-install common-install ;

os-install:
	if [ `uname -s` = Linux ]; then ./linux-setup.sh; fi
	if [ `uname -s` = Darwin ]; then ./mac-setup.sh; fi

common-install:
	./setup.sh

# This is used to set up git hooks for folks who set up their systems
# before the 1 May 2013 release of khan-dotfiles.
# TODO(csilvers): remove after June 2013.
convert:
	cd ~/khan/devtools/khan-linter && git pull
	cd ~/khan/devtools/khan-dotfiles && git pull
	mkdir -p ~/.git_template/hooks
	ln -snf ~/khan/devtools/khan-linter/githook.py \
	    ~/.git_template/hooks/commit-msg
	ln -snf ~/khan/devtools/khan-dotfiles/.git_template/commit_template \
	    ~/.git_template/
	git config --global init.templatedir ~/.git_template
	git config --global commit.template ~/.git_template/commit_template
	cd ~/khan/webapp
	git init
	cd ~/khan/devtools/khan-linter
	git init
	cd ~/khan/devtools/khan-dotfiles
	@echo "-----"
	@echo "cd to other git repos you have and run 'git init' on them too."
	@echo "-----"
