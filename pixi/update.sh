#!/usr/bin/env bash
# Update Local Pixi Environment
# This Bash script updates your local Pixi computing environment

set -eu

pixi update && pixi upgrade
