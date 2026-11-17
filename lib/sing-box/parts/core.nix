# Pieces every sing-box profile needs, whatever its egress and whether or not it
# carries the corp bridge. See ./default.nix for how the groups compose.
{ lib, platform }:
let
  hosts = {
    darwin = {
      tunStack = "gvisor";
      tunStrictRoute = true;
      tunInterfaceName = null;
      tunRouteExcludeAddress = [ ];
    };
    nixos = {
      # `system` beats gvisor on Linux, and strict_route installs firewall rules
      # that can cut off inbound connections to a box that serves them (SSH,
      # Tailscale) — plain auto_route already keeps LAN/tailnet routes, which are
      # more specific than the tun's default route.
      tunStack = "system";
      tunStrictRoute = false;
      tunInterfaceName = "sbtun0";
      tunRouteExcludeAddress = [ "100.64.0.0/10" "fd7a:115c:a1e0::/48" ];
    };
  };

  host = hosts.${platform};
in
rec {
  log = {
    level = "info";
    timestamp = true;
  };

  # ---------------------------------------------------------------- DNS ----

  # How the host resolves anything that must not go through the tunnel (RU-inside
  # rule-set, rule-set downloads) — and, via `default_domain_resolver`, such names
  # as the `urltest` probe URL. A profile without the tunnel resolves everything
  # but its FakeIP names here.
  #
  # NOT `type = "local"`: under an auto_route tun the system resolver *is*
  # sing-box, so the query leaves the host, gets captured by the tun inbound,
  # comes back through `hijack-dns` and falls to `dns.final` = `tunnel-dns`,
  # whose detour is `proxy` — backed by a urltest that cannot pick a node until
  # it resolves its probe URL. Startup deadlock: no DNS until the proxy is ready,
  # no proxy until DNS works.
  #
  # No `detour`: a server without one dials with sing-box's default dialer, which
  # is what an option-less `direct` outbound does — hence `detour = "direct"`
  # being fatal since 1.12. DNS servers never traverse the route rules, so these
  # queries stay off the tunnel, which is the point of the name.
  #
  # DoH, not plain UDP:53: measured here, plain DNS to 1.1.1.1/8.8.8.8/77.88.8.8
  # all times out while DoH to the same address answers — egress filtering that
  # is routine on Russian ISPs. Given as an IP, so it needs no bootstrap.
  directDns = {
    tag = "direct-dns";
    type = "https";
    server = "1.1.1.1";
  };

  # ----------------------------------------------------------- inbounds ----

  # Link-local sink for the tun device itself; nothing outside the host
  # addresses it.
  tunInbound = {
    type = "tun";
    tag = "tun-in";
    address = [
      "172.19.0.1/30"
      "fdfe:dcba:9876::1/126"
    ];
    mtu = 1420;
    auto_route = true;
    strict_route = host.tunStrictRoute;
    stack = host.tunStack;
    # Only set where it means "leave this prefix alone". On Linux it is
    # load-bearing: `auto_route` is policy routing, and carving the prefixes
    # out of sing-box's own table is what lets lookups fall through to `main`,
    # where Tailscale's routes live.
    #
    # macOS (NetworkExtension) turns each prefix into a *kernel* route pinned
    # to the physical interface, at the same prefix length as Tailscale's — a
    # route fight, last writer wins, so a tunnel restart black-holes the
    # tailnet until `tailscale up` makes tailscaled the last writer again. So
    # macOS passes `[ ]` and relies on specificity: the tun's route is
    # `default`, the tailnet's is narrower and wins with nothing competing.
  } // lib.optionalAttrs (host.tunRouteExcludeAddress != [ ]) {
    route_exclude_address = host.tunRouteExcludeAddress;
  } // lib.optionalAttrs (host.tunInterfaceName != null) {
    interface_name = host.tunInterfaceName;
  };

  # ---------------------------------------------------------- outbounds ----

  # Named from profiles and from the subscription's own `proxy` selector — tags
  # resolve across the whole config, which keeps `direct` a one-click bypass in
  # the SFM dashboard.
  direct = {
    type = "direct";
    tag = "direct";
  };

  # -------------------------------------------------------- route rules ----

  # Actions, not outbound picks. Always first: a rule that selects an outbound
  # before sniffing has no domain to match on.
  prelude = [
    { action = "sniff"; }
    {
      protocol = "dns";
      action = "hijack-dns";
    }
  ];

  # A fast refusal for traffic the chosen outbound cannot carry, so the client
  # falls back instead of hanging. Both a browser symptom: "the site hangs in the
  # browser but `curl` is fine". `no_drop`: without it the method silently
  # becomes `drop` after 50 triggers in 30s, and a retrying browser blows
  # through that in seconds.
  reject = match: match // {
    action = "reject";
    no_drop = true;
  };

  # QUIC/HTTP3. Google advertises `alpn=h2,h3`, so Firefox and Chrome open
  # HTTP/3 over UDP:443, while curl has no HTTP/3 at all — which is why an
  # outbound that cannot relay it shows up in the browser only.
  quic = {
    network = "udp";
    port = [ 443 ];
  };

  # Scalars that do not depend on the egress. A profile adds `final` (and the
  # tunnel adds its rule-sets).
  routeBase = {
    auto_detect_interface = true;
    default_domain_resolver = directDns.tag;
  };

  # ------------------------------------------------------- experimental ----

  # `store_fakeip` is not implied by `enabled`, and it is shared rather than
  # corp-only because a FakeIP address outliving its mapping is the worst failure
  # this router has: the mappings are otherwise in-memory, so any restart
  # (profile reload, SFM update, laptop wake) leaves a browser holding a
  # `198.18.x.x` that now points at a *different* host — or at nothing. Both
  # cases log `missing fakeip record`.
  experimental.cache_file = {
    enabled = true;
    store_fakeip = true;
  };
}
