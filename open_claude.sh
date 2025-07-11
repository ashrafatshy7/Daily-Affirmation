#!/bin/bash
# Open terminal in current directory and run claude
cd "$(dirname "$0")"
open -a Terminal .
sleep 1
osascript -e 'tell application "Terminal" to do script "claude" in front window'