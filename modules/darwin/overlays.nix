# Shared nixpkgs overlays for all darwin hosts.
{ ... }:
{
  nixpkgs.overlays = [
    # jetbrains-mono builds from source via gftools -> nanoemoji, whose src is a
    # GitHub auto-generated tag tarball. GitHub recompressed it, changing the
    # hash; nixpkgs still pins the old one, so the fixed-output fetch fails on any
    # host that builds it fresh (no cached/substituted source). Pin the current
    # (verified-identical) source hash until nixpkgs catches up, then delete this.
    (final: prev: {
      pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
        (pyfinal: pyprev: {
          nanoemoji = pyprev.nanoemoji.overridePythonAttrs (old: {
            src = final.fetchFromGitHub {
              owner = "googlefonts";
              repo = "nanoemoji";
              rev = "refs/tags/v0.16.0";
              hash = "sha256-FysyKC01XBnRiur5RR9fcsTxQqE8x0JJHSoe3q6JtKc=";
            };
          });
        })
      ];
    })
  ];
}
