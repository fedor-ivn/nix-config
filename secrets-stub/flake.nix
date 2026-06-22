{
  description = "Bootstrap stub for nix-secrets — empty defaults, no SSH required";

  outputs = _: {
    values = {
      syncthingDevices = {
        fedorivns-iphone = "";
        fedorivns-mbp = "";
      };
      knownNetworkServices = [];
      clamorPaths = {};
      homebrewCasks = [];
      corpTunnelUser = "";
    };
  };
}
