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

  buildInputs = [
    chmlib
    libzip
    libsForQt5.qtwebengine
  ];

  nativeBuildInputs = [
    libsForQt5.qmake
    libsForQt5.wrapQtAppsHook
  ];

  postInstall = ''
    install -Dm755 bin/kchmviewer -t $out/bin
    install -Dm644 packages/kchmviewer.png -t $out/share/pixmaps
    install -Dm644 packages/kchmviewer.desktop -t $out/share/applications
  '';

  meta = with lib; {
    description = "CHM (Winhelp) files viewer";
    mainProgram = "kchmviewer";
    homepage = "http://www.ulduzsoft.com/linux/kchmviewer/";
    license = licenses.gpl3Plus;
    maintainers = with maintainers; [ sikmir ];
    platforms = platforms.linux;
  };
}
