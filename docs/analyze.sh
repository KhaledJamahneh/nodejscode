#!/bin/bash
# Workaround for Dart VM GC segfault in Dart 3.11.0
export DART_VM_OPTIONS="--no-concurrent-mark --no-concurrent-sweep"

case "$1" in
  analyze)
    flutter analyze "${@:2}"
    ;;
  gen-l10n)
    flutter gen-l10n "${@:2}"
    ;;
  build)
    flutter pub run build_runner build --delete-conflicting-outputs "${@:2}"
    ;;
  *)
    flutter analyze "$@"
    ;;
esac
