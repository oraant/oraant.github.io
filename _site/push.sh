#!/bin/bash
git add -A && read -p "commit message: " msg && git commit -m "$msg" && git push
