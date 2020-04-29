#!/bin/bash
set -e

# Create symlink between bsdtar and tar to enable `oc copy`
ln -s $(command -v bsdtar) /usr/bin/tar
