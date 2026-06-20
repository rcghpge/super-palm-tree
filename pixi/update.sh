#!/usr/bin/env bash
# Update Local Pixi Environment
# This Bash script updates your local Pixi computing environment

set -eu

pixi self-update
pixi update && pixi upgrade
