{
  lib,
  stdenv,
  fetchFromGitHub,
  fetchpatch,
  chmlib,
  libzip,
  libsForQt5,
}:

stdenv.mkDerivation rec {
  pname = "kchmviewer";
  version = "8.0-unstable-2022-01-06";

  src = fetchFromGitHub {
    owner = "gyunaev";
    repo = pname;
    rev = "869ecdf6861dbc75db1a37de5844d3e40c2b267b";
    sha256 = "sha256-7m4cy9sJSs2dsBXUumGAu6+2PKRsulUKYQ7u7lJmqhE=";
  };

  patches = [
    # Fix build on macOS https://github.com/gyunaev/kchmviewer/pull/35
    (fetchpatch {
      url = "https://github.com/gyunaev/kchmviewer/commit/d307e4e829c5a6f57ab0040f786c3da7fd2f0a99.patch";
      sha256 = "sha256-FWYfqG8heL6AnhevueCWHQc+c6Yj4+DuIdjIwXVZ+O4=";
    })
  ];

  buildInputs = [
    chmlib
    libzip
    libsForQt5.qtwebengine
  ];

  nativeBuildInputs = [
    libsForQt5.qmake
    libsForQt5.wrapQtAppsHook
  ];

  postInstall =
    lib.optionalString stdenv.hostPlatform.isLinux ''
      install -Dm755 bin/kchmviewer -t $out/bin
      install -Dm644 packages/kchmviewer.png -t $out/share/pixmaps
      install -Dm644 packages/kchmviewer.desktop -t $out/share/applications
    ''
    + lib.optionalString stdenv.hostPlatform.isDarwin ''
      mkdir -p $out/{Applications,bin}
      cp -r bin/kchmviewer.app $out/Applications
      ln -s $out/Applications/kchmviewer.app/Contents/MacOS/kchmviewer $out/bin/kchmviewer
    '';

  meta = with lib; {
    description = "CHM (Winhelp) files viewer";
    mainProgram = "kchmviewer";
    homepage = "http://www.ulduzsoft.com/linux/kchmviewer/";
    license = licenses.gpl3Plus;
    maintainers = with maintainers; [
      azuwis
      sikmir
    ];
    platforms = platforms.unix;
  };
}
