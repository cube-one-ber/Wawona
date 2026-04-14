{
  lib,
  stdenv,
  fetchFromGitHub,
  swift,
  swiftpm ? null,
  git,
  makeWrapper,
  gradle,
  jdk17 ? null,
  openjdk ? null,
  cacert,
  curl,
  libxml2,
  libarchive ? null,
  zlib-ng-compat ? null,
}:

let
  version = "1.8.6";
  skipSubmodule = fetchFromGitHub {
    owner = "skiptools";
    repo = "skip";
    rev = version;
    sha256 = "sha256-tCgoiYW6l6aUSapXYZDoLrDnbruD3WHb8a9Yk46MacU=";
  };
  javaRuntime = if jdk17 != null then jdk17 else openjdk;
  runtimePath =
    if stdenv.isDarwin then
      "/usr/bin:${lib.makeBinPath [ gradle git javaRuntime ]}"
    else
      lib.makeBinPath ([ swift gradle git javaRuntime ] ++ lib.optionals (swiftpm != null) [ swiftpm ]);
in
stdenv.mkDerivation rec {
  pname = "skip";
  inherit version;

  # Darwin fixup hooks invoke GNU find -printf / cut -z (not in BSD userland).
  dontFixup = stdenv.isDarwin;

  src = fetchFromGitHub {
    owner = "skiptools";
    repo = "skipstone";
    rev = version;
    sha256 = "sha256-bq3Uk30DQ2ErtF/4PYSTAjIuIQ2gm+kG/pyKKr5W/sQ=";
  };

  # Linux: Nix Swift + SwiftPM. Darwin: SkipRunner must link the *same* Swift as Xcode's swiftc
  # (used during `skip export`), or dyld loads Nix + Apple libswift_* and manifest compile fails.
  nativeBuildInputs =
    [ cacert makeWrapper ]
    ++ lib.optionals stdenv.isLinux ([ swift ] ++ lib.optionals (swiftpm != null) [ swiftpm ]);

  buildInputs =
    [
      gradle
      javaRuntime
      curl
      libxml2
    ]
    ++ lib.optionals stdenv.isLinux [
      libarchive
      zlib-ng-compat
    ];

  postPatch = ''
    rm -rf skip
    cp -R ${skipSubmodule} skip
    chmod -R u+w skip
  '';

  SSL_CERT_FILE = "${cacert}/etc/ssl/certs/ca-bundle.crt";
  NIX_SSL_CERT_FILE = "${cacert}/etc/ssl/certs/ca-bundle.crt";

  buildPhase = ''
    ${lib.optionalString stdenv.isDarwin ''
    # Before any hook: SwiftPM otherwise uses /var/empty (non-writable) for caches.
    export HOME="$TMPDIR"
    # Darwin stdenv often sets DEVELOPER_DIR to nixpkgs apple-sdk (no Swift); use real Xcode.
    case "''${DEVELOPER_DIR:-}" in
      ""|/nix/store/*) export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer ;;
    esac
    _swift_tc="''${DEVELOPER_DIR}/Toolchains/XcodeDefault.xctoolchain/usr/bin"
    if [ ! -x "$_swift_tc/swift" ]; then
      echo "error: skip on Darwin must be built with Xcode Swift (expected $_swift_tc/swift)." >&2
      echo "Install Xcode or set DEVELOPER_DIR; if the Nix sandbox blocks /Applications, use:" >&2
      echo "  nix build --option sandbox relaxed .#skip" >&2
      exit 1
    fi
    export PATH="${lib.makeBinPath [ git curl javaRuntime ]}:$_swift_tc:/usr/bin:/bin"
    export SDKROOT="$(PATH="$_swift_tc:/usr/bin:/bin" DEVELOPER_DIR="$DEVELOPER_DIR" xcrun --sdk macosx --show-sdk-path 2>/dev/null || true)"
    ''}
    runHook preBuild
    swift build \
      ${lib.optionalString stdenv.isDarwin "--disable-sandbox"} \
      ${lib.optionalString stdenv.isLinux "--static-swift-stdlib -Xswiftc -use-ld=ld"} \
      --configuration release \
      --product SkipRunner
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p "$out/bin"
    # Darwin: coreutils `install` has mis-resolved destinations in some stdenvs; cp is reliable.
    cp -p .build/release/SkipRunner "$out/bin/skip"
    chmod 755 "$out/bin/skip"
    ${if stdenv.isDarwin then ''
    wrapProgram "$out/bin/skip" \
      --prefix PATH : "${runtimePath}" \
      --run 'unset DYLD_FALLBACK_LIBRARY_PATH DYLD_LIBRARY_PATH DYLD_INSERT_LIBRARIES DYLD_FRAMEWORK_PATH'
    '' else ''
    wrapProgram "$out/bin/skip" \
      --prefix PATH : "${runtimePath}"
    ''}
    runHook postInstall
  '';

  meta = with lib; {
    description = "Tool for building Swift apps for Android";
    homepage = "https://skip.dev";
    license = licenses.agpl3Only;
    mainProgram = "skip";
    platforms = platforms.unix;
  };
}
