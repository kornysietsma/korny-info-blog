#!/bin/bash
# Run Jekyll locally with SSL verification disabled
# This works around OpenSSL 3.x CRL checking issues with jekyll-remote-theme

echo "Starting Jekyll server on http://localhost:4000"

ruby -e "require 'openssl'; OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE; load Gem.bin_path('jekyll', 'jekyll')" -- serve
