#!/bin/bash

# "-e" stop on the first failure
# "-u" prevent using an undefined variable
# "-o pipefail" force pipelines to fail on the first non-zero status code
set -euo pipefail

readonly ARGS=$*
FONT_TTFS=()
FONT_VFBS=()
FONT_UFO=()

for style in "Regular" "Italic" "Bold" "BoldIta"; do
  FONT_TTFS+=("../fonts/ttf/B612MonoLigaNerdFont-$style.ttf")
  FONT_TTFS+=("../fonts/otf/B612MonoLigaNerdFont-$style.otf")
  FONT_UFO+=("../sources/ufo/B612MonoLigaNerdFont-$style.ufo")
done

# Check pre-reqs (gftools and silfont)
if ! command -v gftools &>/dev/null; then
  warn "gftools is not installed. Please install it from pip (pip install gftools)"
  exit 1
fi
if ! command -v psfnormalize &>/dev/null; then
  warn "psfnormalize is not installed. Please install it from pip (pip install silfont)"
  exit 1
fi

# -----------------------------------------------------------------------------
# ---- UTILS ------------------------------------------------------------------
# -----------------------------------------------------------------------------
log() {
  message=$1
  shift
  color=$1
  shift
  nc="\033[0m\n"
  printf "${color}[DEPLOY] $message$nc"
}

info() {
  message=$1
  shift
  green="\033[0;32m"
  log "$message" "$green"
}

warn() {
  message=$1
  shift
  red="\033[0;31m"
  log "$message" "$red"
}

# -----------------------------------------------------------------------------
# ---- MAIN -------------------------------------------------------------------
# -----------------------------------------------------------------------------

main() {
  info "Fix font digital signature (DSIG) / Fix font GASP and PREP table"

  for ttf in ${FONT_TTFS[*]}; do
    echo $ttf
    # gftools fix-dsig --autofix $ttf
    mv $ttf $ttf-orig
    gftools fix-nonhinting $ttf-orig $ttf
  done

  info "Export vfb as UFO and normalize UFO"

  for ufo in ${FONT_UFO[*]}; do
    echo $ufo
    psfnormalize $ufo
  done

  # Remove temp files
  for ttf in ${FONT_TTFS[*]}; do
    rm $ttf-orig
    rm $ttf--backup-fonttools-prep-gasporig
    rm
  done

  # for vfb in ${FONT_VFBS[*]}; do
  #   ufo=${vfb//vfb/ufo}
  #   echo $ufo
  #   # vfb2ufo -fo $vfb $ufo
  #   psfnormalize $ufo
  # done

  info "Finished building B612 font"
  exit 0
}

main
