## Purpose

Spec for the corp-tls-trust capability: ensuring corp HTTPS services under
`*.tcsbank.ru` and `*.t-tech.team` are reachable from `fedorivns-mbp` with
TLS certificate verification enabled, by adding the Tinkoff LBaaS Kubernetes CA
to the macOS System keychain.

## Requirements

### Requirement: Corp HTTPS validates without disabling verification

Corp HTTPS services under `*.tcsbank.ru` and `*.t-tech.team` SHALL be
reachable from `fedorivns-mbp` with TLS certificate verification **enabled**.
The setup MUST NOT rely on disabling verification (`curl --insecure`, browser
exceptions) for normal use.

#### Scenario: Corp host loads with verification on

- **WHEN** the bridge and router are up and `curl https://wiki.tcsbank.ru` or
  `curl https://copilot.t-tech.team` is run **without** `--insecure`
- **THEN** the request succeeds with no certificate error

### Requirement: Tinkoff LBaaS Kubernetes CA is trusted on the Mac

The Tinkoff **LBaaS Kubernetes CA** SHALL be added to the macOS System
keychain as a trusted root so all tools trust it without per-tool
configuration. Some corp services under `*.t-tech.team` serve certificates
signed by this internal CA (`CN=LBaaS Kubernetes CA; O=Tinkoff Bank;
OU=k8s-admins`), which the Mac's default trust store does not include —
causing verification failures until it is trusted.

#### Scenario: CA is added to the System keychain

- **WHEN** `security find-trusted-certificate` or Keychain Access is used to
  inspect the Mac's trust store
- **THEN** the Tinkoff LBaaS Kubernetes CA is present and marked trusted

#### Scenario: Affected corp services validate

- **WHEN** `curl https://copilot.t-tech.team` is run without `--insecure` or
  `--cacert`
- **THEN** the connection succeeds with no certificate error

### Requirement: LBaaS CA is sourced from the corp laptop

The LBaaS Kubernetes CA certificate SHALL be obtained from the corp laptop's
keychain — the machine that already trusts it — rather than downloaded from an
untrusted source.

#### Scenario: CA is exported from the corp machine

- **WHEN** the LBaaS CA is needed for the Mac
- **THEN** it is exported via `security find-certificate -c "LBaaS Kubernetes
  CA" -p /Library/Keychains/System.keychain` on the corp laptop
