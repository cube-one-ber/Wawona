{
  lib,
  pkgs,
  buildPackages,
  common,
  buildModule,
}:

let
  fetchSource = common.fetchSource;
  androidToolchain = import ../../toolchains/android.nix { inherit lib pkgs; };
  # SwiftShader source - fetch from GitHub
  # Using same source structure as nixpkgs
  # SwiftShader uses git tags for versions
  src = pkgs.fetchFromGitHub {
    owner = "google";
    repo = "swiftshader";
    rev = "3d536c0fc62b1cdea0f78c3c38d79be559855b88"; # Latest commit from nixpkgs
    # We don't use fetchSubmodules or leaveDotGit because llvm-project and the full git
    # history cause "No space left on device" in the Nix sandbox.
  };

  # Manually fetch required submodules to avoid huge git clones
  glslangSrc = pkgs.fetchFromGitHub {
    owner = "KhronosGroup";
    repo = "glslang";
    rev = "12713f021ad5ac39c44569c733606ef664fd60a5"; # from SwiftShader/third_party/glslang
    hash = "sha256-4+FvF7IEY3M4IqXb6A5oXUfV+vP6uN94P5P01A6QvJc=";
  };
  googletestSrc = pkgs.fetchFromGitHub {
    owner = "google";
    repo = "googletest";
    rev = "b796f7d44681514f58a683a3a718a76043d81b83"; # from SwiftShader/third_party/googletest
    hash = "sha256-J0/w7Vv1v0w/jHn7q/lM6pY1p4Q6Z5X049n/qN5Xy4A=";
  };
  marlSrc = pkgs.fetchFromGitHub {
    owner = "google";
    repo = "marl";
    rev = "eb0d0354148e67823e25fed63ef5cc4f4eb04cca"; # from SwiftShader/third_party/marl
    hash = "sha256-V/Ue8n/0D/K97D+s1WbB/yB93Q2Y7n60w27E2O3m7wI=";
  };
  spirvHeadersSrc = pkgs.fetchFromGitHub {
    owner = "KhronosGroup";
    repo = "SPIRV-Headers";
    rev = "557d071b782b7fe23fcc5c1aa7eebbcad778ffec"; # from SwiftShader/third_party/SPIRV-Headers
    hash = "sha256-23Vp+pYQ4c68Bf2pPqZ1M6+084xM75H4hA5uS2S1KMI=";
  };
  spirvToolsSrc = pkgs.fetchFromGitHub {
    owner = "KhronosGroup";
    repo = "SPIRV-Tools";
    rev = "2205566f108f90dd0f13f17c2fbee59be1f6ce6a"; # from SwiftShader/third_party/SPIRV-Tools
    hash = "sha256-gRz/wX0L5O5B9Q+b5l5gZp4T4OQx32x70Z6q6wV482I=";
  };
in
pkgs.stdenv.mkDerivation {
  name = "swiftshader-android";
  inherit src;
  patches = [ ];
  postPatch = ''
    # Fix CMake version requirements in submodules
    # marl's CMakeLists.txt requires CMake 3.5, update to work with current CMake
    if [ -f third_party/marl/CMakeLists.txt ]; then
      sed -i.bak 's/cmake_minimum_required(VERSION [0-9.]*)/cmake_minimum_required(VERSION 3.5)/' third_party/marl/CMakeLists.txt || true
    fi
    # Fix googletest CMake version requirement
    if [ -f third_party/googletest/CMakeLists.txt ]; then
      sed -i.bak 's/cmake_minimum_required(VERSION [0-9.]*)/cmake_minimum_required(VERSION 3.5)/' third_party/googletest/CMakeLists.txt || true
    fi

    # Disable tests and samples - we're building Vulkan ICD only
    # Tests require googletest/glslang but we can skip them for Vulkan ICD build
    if [ -f CMakeLists.txt ]; then
      # Comment out add_subdirectory calls for tests and samples
      # We keep googletest/glslang submodules but disable tests that use them
      sed -i.bak '/^[[:space:]]*if.*SWIFTSHADER_BUILD_TESTS/,/^[[:space:]]*endif/s/^/# DISABLED: Tests disabled /' CMakeLists.txt || true
      sed -i.bak '/add_subdirectory(tests/s/^/# DISABLED: Tests disabled /' CMakeLists.txt || true
      sed -i.bak '/add_subdirectory(samples/s/^/# DISABLED: Samples disabled /' CMakeLists.txt || true
    fi
  '';
  nativeBuildInputs = with buildPackages; [
    cmake
    pkg-config
    ninja
    python3
    git
    cacert
  ];
  buildInputs = [ ];
  preConfigure = ''
    # Use Android NDK's built-in CMake toolchain file (matches upstream SwiftShader build)
    # This is the standard way to cross-compile for Android with CMake
    ANDROID_TOOLCHAIN_FILE="${androidToolchain.androidndkRoot}/build/cmake/android.toolchain.cmake"
    if [ ! -f "$ANDROID_TOOLCHAIN_FILE" ]; then
      echo "Error: Android NDK toolchain file not found at $ANDROID_TOOLCHAIN_FILE"
      echo "NDK root: ${androidToolchain.androidndkRoot}"
      exit 1
    fi
    export ANDROID_TOOLCHAIN_FILE

    # Copy manually fetched submodules into place
    rm -rf third_party/glslang third_party/googletest third_party/marl third_party/SPIRV-Headers third_party/SPIRV-Tools
    cp -r ${glslangSrc} third_party/glslang
    cp -r ${googletestSrc} third_party/googletest
    cp -r ${marlSrc} third_party/marl
    cp -r ${spirvHeadersSrc} third_party/SPIRV-Headers
    cp -r ${spirvToolsSrc} third_party/SPIRV-Tools
    chmod -R u+w third_party/glslang third_party/googletest third_party/marl third_party/SPIRV-Headers third_party/SPIRV-Tools
  '';
  configurePhase = ''
    runHook preConfigure
    # SwiftShader requires out-of-source build (matches upstream)
    mkdir -p build
    cd build

    # Use NDK's built-in toolchain file (standard approach, matches upstream)
    cmakeFlagsArray+=("-DCMAKE_TOOLCHAIN_FILE=$ANDROID_TOOLCHAIN_FILE")
    # Android-specific CMake flags (matches upstream SwiftShader Android build)
    ANDROID_API_LEVEL="30"  # From android-toolchain.nix androidApiLevel
    cmakeFlagsArray+=("-DCMAKE_BUILD_TYPE=Release")
    cmakeFlagsArray+=("-DANDROID_ABI=arm64-v8a")
    cmakeFlagsArray+=("-DANDROID_PLATFORM=android-$ANDROID_API_LEVEL")
    cmakeFlagsArray+=("-DANDROID_STL=c++_static")

    # SwiftShader build options - build Vulkan ICD only (for waypipe-rs)
    # These match upstream SwiftShader CMake options
    cmakeFlagsArray+=("-DSWIFTSHADER_BUILD_VULKAN=ON")
    cmakeFlagsArray+=("-DSWIFTSHADER_BUILD_EGL=OFF")
    cmakeFlagsArray+=("-DSWIFTSHADER_BUILD_GLES_CM=OFF")
    cmakeFlagsArray+=("-DSWIFTSHADER_BUILD_SAMPLES=OFF")
    cmakeFlagsArray+=("-DSWIFTSHADER_BUILD_TESTS=OFF")
    cmakeFlagsArray+=("-DSWIFTSHADER_BUILD_PVR=OFF")
    # Disable Subzero (x86-only, not needed for ARM Android)
    cmakeFlagsArray+=("-DSWIFTSHADER_BUILD_SUBZERO=OFF")
    # Fix CMake version requirement for marl submodule
    cmakeFlagsArray+=("-DCMAKE_POLICY_VERSION_MINIMUM=3.5")
    cmake .. -GNinja
    runHook postConfigure
  '';
  cmakeFlags = [ ];
  # Build in the build/ subdirectory
  # configurePhase cd's into build/, so buildPhase runs from there
  buildPhase = ''
    runHook preBuild
    # We should be in build/ directory from configurePhase
    # But buildPhase might reset to source root, so check and cd if needed
    if [ ! -f build.ninja ] && [ -d build ]; then
      cd build
    fi
    if [ ! -f build.ninja ]; then
      echo "Error: build.ninja not found. Current dir: $(pwd)"
      ls -la
      exit 1
    fi
    cmake --build . --parallel $NIX_BUILD_CORES
    runHook postBuild
  '';
  # Install from build directory
  installPhase = ''
    runHook preInstall
    # Ensure we're in the build directory
    if [ ! -f build.ninja ] && [ -d build ]; then
      cd build
    fi
    if [ ! -f build.ninja ]; then
      echo "Error: build.ninja not found. Current dir: $(pwd)"
      ls -la
      exit 1
    fi
    # Install using CMake
    cmake --install . --prefix $out

    # SwiftShader may not install libvk_swiftshader.so by default, so copy it manually
    # Check if it exists in the build directory
    if [ -f libvk_swiftshader.so ]; then
      mkdir -p $out/lib
      cp libvk_swiftshader.so $out/lib/
      echo "✓ Copied libvk_swiftshader.so to $out/lib/"
    elif [ -f src/Vulkan/libvk_swiftshader.so ]; then
      mkdir -p $out/lib
      cp src/Vulkan/libvk_swiftshader.so $out/lib/
      echo "✓ Copied libvk_swiftshader.so from src/Vulkan/"
    else
      echo "Warning: libvk_swiftshader.so not found in build directory"
      find . -name "libvk_swiftshader.so" -type f || echo "No libvk_swiftshader.so found"
    fi

    # Copy ICD JSON manifest if it exists
    if [ -f vk_swiftshader_icd.json ]; then
      mkdir -p $out/lib/vulkan/icd.d
      cp vk_swiftshader_icd.json $out/lib/vulkan/icd.d/
      echo "✓ Copied ICD manifest"
    fi

    runHook postInstall
  '';
  # SwiftShader produces a Vulkan ICD library (libvk_swiftshader.so)
  # For Android Vulkan loader discovery, we need:
  # 1. The ICD library (libvk_swiftshader.so)
  # 2. The ICD JSON manifest file (vk_swiftshader_icd.json)
  # These are used by waypipe-rs and Wawona Compositor for Vulkan support
  postInstall = ''
    echo "=== Installing SwiftShader Vulkan ICD for Android ==="

    # SwiftShader installs libvk_swiftshader.so to lib/
    # Verify the library exists
    if [ -f "$out/lib/libvk_swiftshader.so" ]; then
      echo "✓ Found libvk_swiftshader.so"
      # Verify it's an Android arm64 library
      file "$out/lib/libvk_swiftshader.so" || true
    else
      echo "Warning: libvk_swiftshader.so not found in $out/lib/"
      ls -la "$out/lib/" || true
    fi

    # Copy ICD JSON manifest if it exists (SwiftShader may generate this)
    if [ -f "$out/share/vulkan/icd.d/vk_swiftshader_icd.json" ]; then
      mkdir -p $out/lib/vulkan/icd.d
      cp "$out/share/vulkan/icd.d/vk_swiftshader_icd.json" "$out/lib/vulkan/icd.d/" || true
    fi

    # Copy any Vulkan layers if built
    if [ -d "$out/lib/libVkLayer"* ]; then
      mkdir -p $out/lib/vulkan
      cp -r "$out/lib"/libVkLayer*.so "$out/lib/vulkan/" 2>/dev/null || true
    fi

    echo "SwiftShader Vulkan ICD installation complete"
    echo "Library location: $out/lib/libvk_swiftshader.so"
  '';
}
