{
  lib,
  stdenv,
  fetchFromGitHub,
  installShellFiles,
  xcbuild,
  xxd,
  apple-sdk_12,
  darwinMinVersionHook,
  bintools-unwrapped,
  cups,
  llvmPackages_19,
  testers,
  yabai,
  nix-update-script,
}:

let
  llvmPackages = llvmPackages_19;
  # Yabai scripting addition on aarch64-darwin need [`<ptrauth.h>`][1], which is only available on [clang 19 and later][2]
  # [1]: https://clang.llvm.org/docs/PointerAuthentication.html
  # [2]: https://github.com/llvm/llvm-project/commit/0481f049c37029d829dbc0c0cc5d1ee71c6d1c9a
  stdenv' = if stdenv.hostPlatform.isAarch64 then llvmPackages.stdenv else stdenv;
in
stdenv'.mkDerivation (finalAttrs: {
  pname = "yabai";
  version = "7.1.4";

  src = fetchFromGitHub {
    owner = "koekeishiya";
    repo = "yabai";
    rev = "v${finalAttrs.version}";
    hash = "sha256-hCwI6ziUR4yuJOv4MQXh3ufbausaDrG8XfjR+jIOeC4=";
  };

  env = {
    # silence service.h error
    NIX_CFLAGS_COMPILE = "-Wno-implicit-function-declaration";
  };

  nativeBuildInputs = [
    installShellFiles
    xcbuild
    xxd
  ];

  buildInputs = [
    apple-sdk_12
    (darwinMinVersionHook "11.0")
  ];

  dontConfigure = true;
  enableParallelBuilding = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/{bin,share/icons/hicolor/scalable/apps}

    cp ./bin/yabai $out/bin/yabai
    cp ./assets/icon/icon.svg $out/share/icons/hicolor/scalable/apps/yabai.svg
    installManPage ./doc/yabai.1

    runHook postInstall
  '';

  postPatch =
    # Setup unwrapped clang to build scripting addition arm64e code
    lib.optionalString stdenv.hostPlatform.isAarch64 ''
      substituteInPlace makefile \
      --replace "-arch x86_64" "" \
      --replace 'xcrun clang $(OSAX_PATH)' 'clang -isystem $(SDKROOT)/usr/include -isystem ${llvmPackages.libclang.lib}/lib/clang/*/include -isystem ${lib.getDev cups}/include -F$(SDKROOT)/System/Library/Frameworks -L$(SDKROOT)/usr/lib $(OSAX_PATH)'
    ''
    + lib.optionalString stdenv.hostPlatform.isx86_64 ''
      substituteInPlace makefile \
      --replace "-arch arm64e" "" \
      --replace "-arch arm64" ""
    '';

  # On aarh64-darwin, only the scripting addition is arm64e, prebuild that using the unwrapped clang
  preBuild = lib.optionalString stdenv.hostPlatform.isAarch64 ''
    make ./src/osax/payload_bin.c ./src/osax/loader_bin.c "PATH=${bintools-unwrapped}/bin:${llvmPackages.clang-unwrapped}/bin:$PATH"
  '';

  passthru = {
    tests.version = testers.testVersion {
      package = yabai;
      version = "yabai-v${finalAttrs.version}";
    };

    updateScript = nix-update-script { };
  };

  meta = {
    description = "Tiling window manager for macOS based on binary space partitioning";
    longDescription = ''
      yabai is a window management utility that is designed to work as an extension to the built-in
      window manager of macOS. yabai allows you to control your windows, spaces and displays freely
      using an intuitive command line interface and optionally set user-defined keyboard shortcuts
      using skhd and other third-party software.
    '';
    homepage = "https://github.com/koekeishiya/yabai";
    changelog = "https://github.com/koekeishiya/yabai/blob/v${finalAttrs.version}/CHANGELOG.md";
    license = lib.licenses.mit;
    platforms = lib.platforms.darwin;
    mainProgram = "yabai";
    maintainers = with lib.maintainers; [
      azuwis
      cmacrae
      shardy
      khaneliman
    ];
    sourceProvenance =
      with lib.sourceTypes;
      lib.optionals stdenv.hostPlatform.isx86_64 [ fromSource ]
      ++ lib.optionals stdenv.hostPlatform.isAarch64 [ binaryNativeCode ];
  };
})
