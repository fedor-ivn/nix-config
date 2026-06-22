## Purpose

Spec for the corp-proxy-bridge capability: a two-hop SSH tunnel that exposes a
SOCKS5 endpoint on `fedorivns-mbp` whose traffic egresses from the corp laptop's
network. The corp laptop initiates the outbound SSH connection so no inbound TCP
to the corp laptop is required.

## Requirements

### Requirement: Outbound-initiated SOCKS bridge

The bridge SHALL be established by an **outbound** connection initiated from
the corp laptop to `fedorivns-mbp`. The setup MUST NOT depend on any inbound
connection to the corp laptop, because the corp endpoint agents drop
unsolicited inbound TCP.

#### Scenario: Inbound to corp laptop is not required

- **WHEN** the bridge is established and serving traffic
- **THEN** no step in the path required a TCP connection to be accepted *by*
  the corp laptop (only the corp laptop's outbound connection to the Mac)

#### Scenario: Bridge survives the corp inbound block

- **WHEN** the corp endpoint agents are active and dropping inbound TCP
- **THEN** the SOCKS bridge is still established and usable

### Requirement: Local SOCKS endpoint on the Mac

The bridge SHALL expose a SOCKS5 listener at `127.0.0.1:1080` on
`fedorivns-mbp`. Connections made through it SHALL originate from the corp
laptop's network stack (the corp egress).

#### Scenario: SOCKS endpoint is reachable locally

- **WHEN** the bridge is up and a client on the Mac runs `nc -vz 127.0.0.1
  1080`
- **THEN** the connection succeeds

#### Scenario: Traffic egresses via the corp laptop

- **WHEN** a request to a corp-internal host is sent through
  `socks5://127.0.0.1:1080` (e.g. `curl --socks5-hostname 127.0.0.1:1080
  https://wiki.tcsbank.ru`)
- **THEN** the corp-internal host responds, proving the exit is the corp
  laptop's network

### Requirement: Stock SSH only on the corp side

The corp-side half of the bridge SHALL use only software already present on
the corp laptop: the standard `ssh` client and the built-in macOS sshd
(Remote Login). It MUST NOT require installing third-party software (no
`autossh`, no SOCKS daemon, no VPN client) on the corp laptop.

#### Scenario: No extra corp-side software

- **WHEN** the bridge is established
- **THEN** it uses only the system `ssh` binary and the built-in sshd, and no
  third-party daemon or package is installed on the corp laptop

### Requirement: Mac accepts the corp laptop's dial-in

`fedorivns-mbp` SHALL run `openssh` so the corp laptop can establish the
outbound reverse-forward connection to it over the LAN.

#### Scenario: Mac sshd is listening

- **WHEN** `fedorivns-mbp` is activated with this change
- **THEN** an SSH daemon is listening and reachable from the corp laptop on
  the local network

### Requirement: Two-hop topology so SOCKS egresses from the corp laptop

The bridge SHALL use two stock-`ssh` sessions (per design Decision 2): the
corp laptop reverse-forwards its own sshd to the Mac (`-R 2222:localhost:22`),
and the Mac dials back through that forward with `ssh -D 127.0.0.1:1080 -p
2222` so that the SOCKS proxy's outbound connections originate on the corp
laptop. A single corp-side `ssh -D … -R` (one-hop) MUST NOT be used: `ssh -D`
egresses from the SSH server, which in a corp→Mac dial is the Mac, so its
SOCKS would exit via the Mac and never reach corp-internal hosts.

#### Scenario: Egress is the corp network, not the Mac

- **WHEN** a request is sent through `socks5://127.0.0.1:1080` to an
  egress-reflecting service (e.g. `curl --socks5-hostname 127.0.0.1:1080
  https://ifconfig.me`)
- **THEN** the observed source address is the corp egress, **not** the Mac's
  WireGuard/ISP address

#### Scenario: Corp-internal host completes TLS

- **WHEN** `curl https://wiki.tcsbank.ru` is routed through the bridge
- **THEN** the TLS handshake completes (no `SSL_ERROR_SYSCALL` from the
  connection exiting on a network that cannot reach the corp host)

### Requirement: Mac-side consumer is a persistent loopback service

The Mac-side dial-back (`-D 127.0.0.1:1080 -p 2222 …`) SHALL run as a
nix-managed launchd service on the Mac using **stock `ssh`** with launchd
`KeepAlive` + `RunAtLoad` (no autossh): `KeepAlive` relaunches `ssh` when it
exits and `ServerAlive` makes it exit on a dead link, so launchd is the
supervisor. Because it connects only to loopback (`localhost:2222`), it MUST be
allowed to retry continuously without the beacon concern that constrains the
corp side; it re-establishes automatically once the corp laptop has dialed in.

#### Scenario: Consumer recovers when the corp dial appears

- **WHEN** the corp laptop's reverse forward (re)appears on `127.0.0.1:2222`
- **THEN** the Mac-side consumer connects and restores `127.0.0.1:1080`
  without manual intervention

### Requirement: Corp laptop runs its own sshd for the dial-back

The corp laptop SHALL run the built-in macOS sshd (Remote Login) and
authorize the Mac's public key, so the Mac-side consumer can authenticate to
it over the reverse-forwarded port. This connection arrives via the corp
laptop's loopback (through the tunnel), so it is not subject to the corp
agents' inbound-TCP drop.

#### Scenario: Dial-back authenticates over the tunnel

- **WHEN** the Mac-side consumer connects to `127.0.0.1:2222`
- **THEN** it authenticates to the corp laptop's sshd with the Mac's key and
  the session is established

### Requirement: Corp dial is an on-demand self-healing command, not a registered service

The corp-side `ssh` dial SHALL be run on demand as a bare command (a script or
shell alias), not registered as a launchd LaunchAgent/Daemon. While running it
SHALL auto-reconnect so a brief drop (e.g. a momentary Mac sleep) heals without
manual action, using stock `ssh` with **capped exponential backoff and jitter**
rather than a tight fixed interval. A failed attempt MUST fail fast (bounded
`ConnectTimeout`) before backing off. Reconnection after an established session
drops SHALL reset to the minimum backoff; repeated quick failures SHALL grow
the delay up to the cap.

#### Scenario: No dial when the command is not running

- **WHEN** the user has not started (or has stopped) the corp-side command
- **THEN** the corp laptop makes no outbound SSH attempts to the Mac, and no
  launchd job would start one

#### Scenario: No persistent launchd registration on the corp laptop

- **WHEN** the corp laptop is inspected for installed agents/daemons
- **THEN** no LaunchAgent or LaunchDaemon for the tunnel is registered; the
  dial exists only as a runnable command that leaves no service behind

#### Scenario: Brief drop self-heals promptly

- **WHEN** an established bridge drops because the Mac slept momentarily and
  the Mac becomes reachable again
- **THEN** the running command reconnects at the minimum backoff without the
  user re-running it

#### Scenario: Long absence backs off instead of beaconing

- **WHEN** the Mac stays unreachable (off-LAN) while the command keeps running
- **THEN** each attempt fails fast and the retry delay grows (with jitter) up
  to the cap, rather than retrying at a tight fixed interval
