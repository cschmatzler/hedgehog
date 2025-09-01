{
  pkgs,
  lib,
  ...
}: {
  packages =
    [
      pkgs.git
    ]
    ++ lib.optionals pkgs.stdenv.isLinux [pkgs.inotify-tools];

  languages.elixir.enable = true;
  languages.elixir.package = pkgs.beam28Packages.elixir_1_19;
}
