.PHONY: all clean

# TODO(ericbrown): Increment box version (only stored online) and upload

# This is really just for documentation at this point.
# Output currently goes to builds/*.box
all:
	packer build khanbuntu.pkr.hcl

# We could also remove builds directory, but builds take 15+ minutes and it
# probably isn't desired until we decide where/how to upload boxes to a place
# devs can easily retrieve.
clean:
	rm -rf packer_cache
