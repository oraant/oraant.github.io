#!/bin/bash
git add -A
read -p "commit message: " msg
echo "$msg"
git commit -m "$msg"
git push
