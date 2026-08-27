# Monitoring plan — `fedorivns-homelab`

Alerting-first monitoring. No dashboards, no metrics browsing, no log
aggregation. The success criterion is: **when something breaks, my phone buzzes;
when nothing is broken, nothing arrives.**

Everything verified against the pinned nixpkgs (`26.11`) unless marked
`VERIFY AT DEPLOY`.

---

## 1. Scope

### Failure modes covered

| Failure mode | Mechanism |
| --- | --- |
| systemd unit dies (`sing-box`, `syncthing`) | `node_exporter` `systemd` collector → rule |
| Disk filling | `node_exporter` filesystem collector → `predict_linear` rule |
| SMART failure | `smartctl_exporter` → rule |
| Host unreachable / whole stack dead | `vector(1)` rule → healthchecks.io dead-man's switch |
| Telegram delivery broken | `alertmanager_notifications_failed_total` → email |

### Explicitly out of scope

- **Grafana.** Practitioner consensus is that dashboards go unread and alerting
  is what matters. `services.grafana` is fully declarative (provisioning) and
  can be bolted on later without touching anything below.
- **`blackbox_exporter`.** No probe targets decided yet. On a single host it
  cannot meaningfully watch itself — that is healthchecks.io's job. Add it only
  once there are outward (ISP/DNS/TLS expiry) or sideways (thinkpad/mbp over
  Tailscale) targets. `enableConfigCheck` defaults to `true`, so probe config
  gets build-validated whenever it is added.
- **WireGuard / tunnel probing.** Deferred deliberately.
- **Log aggregation** (Loki, VictoriaLogs, Vector). `journald` is already capped
  at 200 MB in `modules/nixos/server/default.nix`.
- **VictoriaMetrics.** Evaluated and rejected: it does not evaluate alert rules

---

## 2. Architecture

```
node_exporter ─┐
               ├─→ Prometheus ──(rules, promtool-validated)──→ Alertmanager ─┬─→ Telegram   (primary)
smartctl_exp. ─┘        │                                                     ├─→ email      (reserve)
                        └── vector(1) ──────────────────────────────────────→ └─→ webhook → healthchecks.io
```

Four systemd units. Telegram and email are **native Alertmanager integrations**
— no extra daemon.

| # | Component | systemd unit | Version | Build-validated |
| --- | --- | --- | --- | --- |
| 1 | Prometheus (store + rule evaluation) | `prometheus` | 3.13.2 | ✅ config **and** rules |
| 2 | node_exporter | `prometheus-node-exporter` | 1.12.1 | n/a |
| 3 | smartctl_exporter | `prometheus-smartctl-exporter` | 0.14.0 | n/a |
| 4 | Alertmanager (route/group/dedup) | `alertmanager` | 0.33.1 | ✅ `checkConfig` |
| — | Telegram delivery | *native* | — | — |
| — | Email delivery | *native* | — | — |
| — | healthchecks.io | *off-box* | — | — |

---

## 3. Prerequisites (manual, before first activation)

1. **Telegram bot** — create via `@BotFather`, note the token. Send the bot a
   message, then get the numeric `chat_id`
   (`https://api.telegram.org/bot<TOKEN>/getUpdates`).
2. **Gmail app password** — requires 2FA on the account. The regular account
   password will not work as an SMTP credential.
3. **healthchecks.io** — free account, create one check, set its period to ~15m
   with a ~5m grace, note the ping URL. Default notification channel is email,
   which is deliberate (see §6).
4. **Add secrets** — `sops secrets.yaml`:

| Key | Consumed by |
| --- | --- |
| `telegram/alerts-bot-token` | `bot_token_file` |
| `telegram/alerts-chat-id` | `chat_id_file` |
| `email/smtp-app-password` | `auth_password_file` |
| `healthchecks/ping-url` | dead-man's-switch webhook receiver |

All four are flat single-line values — same shape as the existing
`wireguard/*` entries. No multi-line YAML anywhere.

---

## 4. Commit 1 — hoist the sops bootstrap

**Why:** `modules/nixos/sing-box.nix` currently owns the NixOS sops bootstrap.
A second secret-consuming module would have to redeclare it. Identical
definitions *do* merge (`types.path` uses `mergeEqualOption`, which only throws
on differing values), so it would work — but it is fragile by accident rather
than by design, and the age-key rationale comment ends up in the wrong file.

**New file `modules/nixos/sops.nix`** — move out of `sing-box.nix`:

- `imports = [ inputs.sops-nix.nixosModules.sops ]`
- `sops.defaultSopsFile = ../../secrets.yaml`
- `sops.age.keyFile` — computed from `lib.head config.managedUsers`
- `sops.age.sshKeyPaths = [ ]`
- Carry the existing explanatory comment across verbatim.

**Wiring:** both `sing-box.nix` and `monitoring.nix` do `imports = [ ./sops.nix ];`.
NixOS deduplicates modules by file path, so importing it twice is safe.

> Deliberately **not** placed in `modules/nixos/common/` — that is shared with
> `fedorivns-thinkpad`, which would then require the age key to be present.

`sing-box.nix` keeps its own `sops.secrets` block for the `wireguard/*` entries.
No behaviour change; verify with a no-op rebuild before continuing.

---

## 5. Commit 2 — `modules/nixos/monitoring.nix`

Follows the `sing-box.nix` shape exactly: single file, `options.monitoring.enable`,
`config = lib.mkIf cfg.enable`, sops wiring inline.

```
imports = [ ./sops.nix ];
options.monitoring.enable = lib.mkEnableOption "...";
config = lib.mkIf cfg.enable { ... };
```

### 5.1 Exporters

- `services.prometheus.exporters.node`
  - **`enabledCollectors = [ "systemd" ]`** — ⚠️ the `systemd` collector is
    listed under *"Disabled by default"* in node_exporter v1.12.1's README.
    Without this, unit death is not detected at all. Easiest thing to get wrong.
  - filesystem collector is on by default — covers disk fill.
  - `listenAddress = "127.0.0.1"`, `openFirewall` left `false`.
- `services.prometheus.exporters.smartctl`
  - `devices = [ ]` autodiscovers.
  - Module already ships `CAP_SYS_RAWIO` / `CAP_SYS_ADMIN`, `DeviceAllow` for
    `block-sd` + `char-nvme`, and the `disk` supplementary group. Nothing else
    to configure.

### 5.2 Prometheus

- `retentionTime` — set explicitly (default 15d). Laptop disk; keep modest.
- `globalConfig.scrape_interval` — 30s is plenty for one host.
- `scrapeConfigs` — node, smartctl, prometheus itself, **and Alertmanager**
  (required for the notification-failure rule in §5.4).
- `alertmanagers` — point at `127.0.0.1:9093`.
- `rules` — see §5.4. `checkConfig` defaults to `true`, so `promtool check config`
  *and* `check rules` run inside the derivation: **bad PromQL fails `nix build`**.

### 5.3 Alertmanager

- `configuration` = route tree + receivers. Contains **no secrets** — all
  credentials are file references.
- Receivers:
  - `telegram` — `telegram_configs` with `bot_token_file` + `chat_id_file`
    (both verified present in v0.33.1 `config/notifiers.go:207`).
  - `email` — `email_configs` with `smarthost: smtp.gmail.com:587`,
    `auth_username` = the Gmail address, `auth_password_file`,
    `require_tls` at default. `from` must match `auth_username` (Gmail rewrites
    mismatched senders). `auth_password_file` verified at `notifiers.go:217`.
  - `healthchecks` — `webhook_configs` pointing at the ping URL.
- Route tree — see §6.

### 5.4 Alert rules

Severity label drives routing. `for:` durations chosen so a laptop reboot does
not page.

| Rule | Expression (sketch) | `for` | Severity |
| --- | --- | --- | --- |
| `SystemdUnitFailed` | `node_systemd_unit_state{state="failed"} == 1` | 2m | critical |
| `DiskWillFillSoon` | `predict_linear(node_filesystem_avail_bytes{fstype!~"tmpfs\|ramfs"}[6h], 4*24*3600) < 0` | 1h | critical |
| `DiskAlmostFull` | `node_filesystem_avail_bytes / node_filesystem_size_bytes < 0.10` | 15m | warning |
| `SmartFailing` | `smartctl_device_smart_status == 0` | 5m | critical |
| `TargetDown` | `up == 0` | 5m | warning |
| `AlertmanagerNotificationsFailing` | `rate(alertmanager_notifications_failed_total[10m]) > 0` | 5m | **meta** |
| `DeadMansSwitch` | `vector(1)` | — | **deadman** |

> `VERIFY AT DEPLOY` — exact metric names for the systemd collector
> (`node_systemd_unit_state`) and smartctl exporter
> (`smartctl_device_smart_status`) could not be confirmed locally, since the
> exporters are `x86_64-linux` binaries and this work was done on darwin.
> Confirm with `curl -s localhost:9100/metrics | grep systemd` and
> `curl -s localhost:9633/metrics | grep smart` on first deploy, and fix the
> expressions before relying on them. `promtool` validates *syntax*, not that a
> metric exists.

`alertmanager_notifications_failed_total` **is** verified — namespace
`alertmanager`, labelled by `integration` and `reason`
(`notify/metrics.go:50`, v0.33.1).

### 5.5 Host wiring

`configurations/nixos/fedorivns-homelab/default.nix` — two lines:

```nix
imports = [ ... flake.inputs.self.nixosModules.monitoring ];
monitoring.enable = true;
```

---

## 6. Notification routing

⚠️ **Alertmanager has no receiver failover.** Verified: zero matches for
`fallback|failover|escalat` in `notify/notify.go` (v0.33.1). If Telegram
delivery fails, it retries Telegram — it never falls through to email. A
"reserve channel" must therefore be built from the **route tree**, using
`continue` (`config.go:887`), not from failover.

```
route:
  receiver: telegram
  group_by: [alertname]
  routes:
    - matchers: [ 'severity = deadman' ]
      receiver: healthchecks
      repeat_interval: 5m        # must be well under the check's period

    - matchers: [ 'alertname = AlertmanagerNotificationsFailing' ]
      receiver: email            # no continue — Telegram is the broken thing

    - matchers: [ 'severity = critical' ]
      receiver: email
      continue: true             # ...and also fall through to Telegram
```

**Design rationale:** email stays quiet by default so it remains a channel worth
reading. Duplicating *every* alert to both channels destroys that property.
Email therefore carries only (a) the meta-alert Telegram structurally cannot
deliver, and (b) `critical` alerts you must not miss.

**SMTP choice:** Gmail directly, **not** own mail infrastructure. Relaying
alerts through a self-hosted mail server reintroduces the circularity the whole
design avoids. (Checked: no mail server on this host — only Thunderbird client
config in home-manager.)

**Layering — what each layer catches:**

| Layer | Catches | Blind to |
| --- | --- | --- |
| Telegram | everything, normally | Telegram blocked/throttled/token revoked |
| Email | Telegram broken; critical alerts | host has no internet at all |
| healthchecks.io | Prometheus/Alertmanager dead, box off, no internet | — |

healthchecks.io notifies by email by default, so email is already the outermost
layer. Using it as the reserve means one delivery mechanism to keep working
rather than two.

---

## 7. Verification

1. `git add` new files — **untracked files are invisible to Nix** (per
   `openspec/config.yaml`). Easy to lose an hour to this.
2. `just check` → `nix flake check`. A malformed rule should fail here, not at
   runtime. Deliberately break one rule once to confirm the check is live.
3. `just a homelab`.
4. `systemctl status prometheus prometheus-node-exporter
   prometheus-smartctl-exporter alertmanager`.
5. Confirm metric names (§5.4 `VERIFY AT DEPLOY`).
6. `curl -s localhost:9090/api/v1/rules | jq` — all rules loaded, none erroring.
7. **Test unit-failure detection end to end** — add a throwaway
   `always-fails.service` (`ExecStart = /bin/false`), start it, confirm a
   Telegram message arrives, then remove it. This is the single most valuable
   test; the Discourse threads recommend exactly this.
8. **Test the reserve path** — temporarily point `bot_token_file` at a bogus
   token, confirm `AlertmanagerNotificationsFailing` fires and arrives *by
   email*, then revert.
9. Confirm healthchecks.io shows a green check and stops complaining.
10. Stop Prometheus for longer than the healthchecks period; confirm the
    dead-man's switch alerts. Restart.

---

## 8. Deferred

- `blackbox_exporter` once probe targets exist.
- Tunnel / WireGuard reachability alerting. No documented prior art found —
  handshake-age metrics false-positive on idle tunnels.
- Grafana, if metrics ever need browsing rather than alerting.
- Scraping `fedorivns-thinkpad` / `fedorivns-mbp` over Tailscale.
- Revisit VictoriaMetrics only if retention/cardinality becomes real; migration
  is cheap because it speaks Prometheus (Alertmanager, exporters and most rules
  carry over).

---

## 9. Verified reference

- **nixpkgs pin:** `26.11`.
- **node_exporter `systemd` collector is disabled by default** — v1.12.1 README,
  "Disabled by default" section.
- **`services.prometheus.checkConfig`** runs `promtool check config` *and*
  `check rules` in the derivation (`prometheus/default.nix:13-88`).
- **Alertmanager file-based secrets:** `bot_token_file`, `chat_id_file`,
  `auth_password_file`, `auth_secret_file` — all present in v0.33.1
  `config/notifiers.go`.
- **No receiver failover** in Alertmanager; `continue: true` on a route is the
  only multi-receiver mechanism.
- **smartctl exporter privileges** are handled by the module — caps,
  `DeviceAllow`, `disk` group.
- **`services.smartd` was not chosen**: its only notification targets are
  mail/wall/X11/systembus — no webhook — so SMART is routed through Prometheus
  instead, keeping one alerting path.

*Optional:* this can be converted into a tracked openspec change
(`proposal.md` / `design.md` / `tasks.md`) with `/opsx:propose` if you want it
in `openspec/changes/` rather than as a loose root-level file.
