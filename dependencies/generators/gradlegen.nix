{ pkgs, stdenv, lib, wawonaAndroidProject ? null, wawonaSrc ? null, wawonaVersion ? "v1.0", iconAssets ? "AUTO" }:

let
  # Resolve icon assets:
  # 1. If explicitly null, use null (breaks recursion)
  # 2. If explicitly provided (not "AUTO"), use that derivation
  # 3. If "AUTO", try to resolve locally from wawonaSrc
  androidIconAssets = 
    if iconAssets == null then null
    else if iconAssets != "AUTO" then iconAssets
    else if wawonaSrc != null && builtins.pathExists ./android-icon-assets.nix then
      import ./android-icon-assets.nix { inherit pkgs lib wawonaSrc; }
    else
      null;

  # Script to generate Android Studio project in _GEN-android/ (gitignored).
  # When wawonaAndroidProject is available (pre-built Android project with jniLibs),
  # copies the full project. Otherwise falls back to gradle files + sources only.
  projectPath = if wawonaAndroidProject != null then toString wawonaAndroidProject else "";
  outDir = "_GEN-android";
  generateScript = pkgs.writeShellScriptBin "gradlegen" ''
    set -e
    OUT="${outDir}"
    RUN_SKIP_EXPORT=0
    while [ "$#" -gt 0 ]; do
      case "$1" in
        --run-skip-export) RUN_SKIP_EXPORT=1; shift ;;
        *) break ;;
      esac
    done

    # Clean previous run (handles read-only Nix store copies)
    if [ -d "$OUT" ]; then
      chmod -R u+w "$OUT" 2>/dev/null || true
      rm -rf "$OUT"
    fi
    mkdir -p "$OUT"

    if [ -n "${projectPath}" ] && [ -d "${projectPath}" ]; then
      echo "Copying full Android project (backend + native libs) to $OUT/..."
      cp -r ${projectPath}/* "$OUT/"
      chmod -R u+w "$OUT" 2>/dev/null || true
    else
      if [ -n "${toString wawonaSrc}" ] && [ -d "${toString wawonaSrc}/android" ]; then
        echo "Copying repository Android project to $OUT/..."
        cp -r ${toString wawonaSrc}/android/* "$OUT/"
        chmod -R u+w "$OUT" 2>/dev/null || true
        ${if androidIconAssets != null then ''
          if [ -d "${androidIconAssets}/res" ]; then
            mkdir -p "$OUT/app/src/main/res"
            cp -r ${androidIconAssets}/res/* "$OUT/app/src/main/res/"
            chmod -R u+w "$OUT/app/src/main/res" 2>/dev/null || true
            echo "Merged Wawona launcher icon assets"
          fi
        '' else ""}
      else
        echo "ERROR: Could not locate android project sources under wawonaSrc."
        exit 1
      fi
    fi

    # Trim generated project bloat for Android Studio import.
    find "$OUT" -type d \( \
      -name ".gradle" -o -name ".kotlin" -o -name ".idea" -o -name ".cxx" -o -name "build" \
    \) -prune -exec rm -rf {} + 2>/dev/null || true
    rm -f "$OUT/local.properties" 2>/dev/null || true

    # Normalize Skip artifacts to <projectRoot>/Skip for IDE builds.
    if [ -d "$OUT/android/Skip" ] && [ ! -d "$OUT/Skip" ]; then
      mv "$OUT/android/Skip" "$OUT/Skip"
    elif [ -d "$OUT/android/Skip" ] && [ -d "$OUT/Skip" ]; then
      cp -R "$OUT/android/Skip/." "$OUT/Skip/" 2>/dev/null || true
      rm -rf "$OUT/android/Skip"
    fi

    # If caller runs from repo root and already has fresh Skip artifacts, copy them.
    if [ ! -d "$OUT/Skip" ] && [ -d "./android/Skip" ]; then
      mkdir -p "$OUT/Skip"
      cp -R ./android/Skip/. "$OUT/Skip/" 2>/dev/null || true
    fi

    if [ "$RUN_SKIP_EXPORT" -eq 1 ]; then
      if [ ! -f "./Package.swift" ]; then
        echo "ERROR: --run-skip-export requires running gradlegen from repo root (Package.swift missing)." >&2
        exit 1
      fi
      if ! command -v skip >/dev/null 2>&1; then
        echo "ERROR: skip CLI not found; install Skip or run without --run-skip-export." >&2
        exit 1
      fi
      echo "Running skip export into $OUT/Skip ..."
      mkdir -p "$OUT/Skip"
      skip export --project . -d "$OUT/Skip" --verbose
    fi

    if [ ! -d "$OUT/Skip" ]; then
      echo "NOTE: Skip artifacts were not found in generated project."
      echo "      Run: cd \"$(pwd)\" && nix run .#gradlegen -- --run-skip-export"
    fi

    echo ""
    echo "Project ready at $OUT/"
    echo "Open $OUT/ in Android Studio and select device/emulator."
  '';

in {
  inherit generateScript;
}
