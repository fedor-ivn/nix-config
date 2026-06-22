## 1. Secrets

- [x] 1.1 Add WireGuard `private_key` and `pre_shared_key` to `secrets.yaml` (sops)
- [x] 1.2 Confirm `fedorivns-mbp` can decrypt the new secret (age key present, `just a` evaluates)
- [x] 1.3 Remove the untracked root-level `singbox.json`; ensure no WireGuard secret remains in cleartext in the tree

## 2. SSH endpoints for the two-hop bridge

- [x] 2.1 Enable `openssh` on `fedorivns-mbp` (key-only), scoped to the LAN; set `ClientAliveInterval`/`ClientAliveCountMax` so a dead corp connection's stale `-R 2222` forward is reaped quickly (otherwise the reconnect can't rebind 2222 until TCP timeout)
- [x] 2.2 Authorize the corp laptop's key in `fedorivns-mbp` authorized keys (for session 1: corp `-R` dial-in)
- [x] 2.3 Verify from the corp laptop: `nc -vz <mac-ip> 22` succeeds
- [x] 2.4 Enable Remote Login (built-in sshd) on the corp laptop
- [x] 2.5 Authorize the Mac's key in the corp laptop's authorized keys (for session 2: Mac dial-back over the tunnel)

## 3. corp-proxy-bridge (two-hop stock `ssh`)

- [x] 3.1 Commit `scripts/corp-tunnel.sh` (corp side, on-demand, stock-ssh backoff+jitter reconnect loop: `-R 2222:localhost:22`, no launchd registration) and `modules/home/corp-tunnel.nix` (Mac side, nix-managed home-manager launchd agent: stock `ssh -D 1080 -p 2222`, `KeepAlive`+`RunAtLoad`, gated on `me.isMainMachine`)
- [x] 3.2 Copy `scripts/corp-tunnel.sh` to the corp laptop (or alias it); confirm no third-party software/daemon is installed there
- [x] 3.3 Set `corpTunnelUser` in the private `secrets` flake input, `just a`, then on the corp laptop run `./corp-tunnel.sh` and verify `nc -vz 127.0.0.1 1080` on the Mac
- [x] 3.4 Verify **corp egress** (the one-hop regression check): `curl --socks5-hostname 127.0.0.1:1080 https://ifconfig.me` returns the corp egress IP, **not** `62.84.97.10`; then `curl --socks5-hostname 127.0.0.1:1080 https://wiki.tcsbank.ru` completes the TLS handshake
- [x] 3.5 Verify reconnect: (a) brief drop — let the bridge establish, sleep the Mac ~10 s, confirm corp-tunnel.sh reconnects on its own at min backoff; (b) long absence — take the Mac off-LAN, confirm each attempt fails fast (~3 s) and the retry delay grows with jitter up to the 300 s cap (not a tight fixed interval)

## 4. split-tunnel-router module (sing-box)

- [x] 4.1 Add `sing-box` to `fedorivns-mbp` packages
- [x] 4.2 Template `singbox.json` via nix; interpolate WireGuard keys from sops into a mode-600 path outside the Nix store at activation
- [x] 4.3 Configure DNS: `tunnel-dns` (UDP via `wg`) as default + `fakeip-dns` (`198.18.0.0/15`, `fc00::/18`) for `domain_suffix [tcsbank.ru, t-tech.team]`; set `default_domain_resolver`; `independent_cache: true`
- [x] 4.4 Configure `tun` inbound (`auto_route`, `strict_route`, gvisor) and route rules in order: `sniff` action → `protocol:dns` hijack → `domain_suffix [tcsbank.ru, t-tech.team] → socks-tbank` → `ip_is_private → direct`; final `wg`
- [x] 4.5 Define outbounds: `direct`, `socks-tbank` (`127.0.0.1:1080`), and the `wg` WireGuard endpoint

## 5. corp-tls-trust (Tinkoff LBaaS Kubernetes CA)

- [x] 5.1 Export the LBaaS CA from the corp laptop: `security find-certificate -c "LBaaS Kubernetes CA" -p /Library/Keychains/System.keychain > lbaas-ca.pem`
- [x] 5.2 Add it to the Mac System keychain: `sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain lbaas-ca.pem`
- [x] 5.3 Verify: `curl https://copilot.t-tech.team` succeeds without `--insecure` or `--cacert`

## 6. Verification

- [x] 6.1 `curl https://wiki.tcsbank.ru` and `curl https://copilot.t-tech.team` (no explicit proxy) load via the bridge
- [x] 6.2 `nslookup wiki.tcsbank.ru` and `nslookup copilot.t-tech.team` return a `198.18.x.x` FakeIP
- [x] 6.3 `curl https://ifconfig.me` shows the WireGuard exit (not ISP, not corp)
- [x] 6.4 A non-corp site loads normally; a private-IP destination is routed direct
- [x] 6.5 sing-box log tags corp connections `socks-tbank` and everything else `wg`
- [x] 6.6 Confirm no cleartext WireGuard key in the repo and the rendered config is not world-readable

## 7. Resilience and docs

- [x] 7.1 Reboot/wake test: the Mac sing-box router and the launchd `corp-tunnel` agent recover without manual steps; after a brief sleep the corp-side `corp-tunnel.sh` loop and the Mac-side `KeepAlive` agent re-establish the bridge on their own (corp-side script must be re-run only after a full corp-laptop reboot, since it is not a launchd service there)
- [x] 7.2 Document the VPS-rendezvous and port-443 fallbacks (Decision 1) in the change/README
- [x] 7.3 Note the acceptable-use / DLP caveat for corp-routed traffic
