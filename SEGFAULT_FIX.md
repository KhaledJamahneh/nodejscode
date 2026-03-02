# Dart VM Segfault Workaround

This project uses Dart 3.11.0 which has a garbage collector bug causing segfaults during analysis.

## Quick Fix

Use the wrapper script for all analysis/generation commands:

```bash
./analyze.sh analyze          # Run flutter analyze
./analyze.sh gen-l10n          # Generate localizations
./analyze.sh build             # Run build_runner (if added)
```

## Manual Fix

Prefix any flutter command with the environment variable:

```bash
DART_VM_OPTIONS="--no-concurrent-mark --no-concurrent-sweep" flutter analyze
DART_VM_OPTIONS="--no-concurrent-mark --no-concurrent-sweep" flutter gen-l10n
```

## Shell Alias

An alias has been added to ~/.bashrc:

```bash
flutter-analyze  # Use instead of flutter analyze
```

## Root Cause

Dart VM concurrent garbage collector crashes in `MarkingVisitor::DrainMarkingStackWithPauseChecks`.
Disabling concurrent GC (`--no-concurrent-mark --no-concurrent-sweep`) prevents the crash.
