SHELL := /bin/bash

all: link

link:
	./symlink.sh

# TODO(david): Automate other dev setup operations (install autojump, ack,
#     pip install -r requirements.txt, etc.)
