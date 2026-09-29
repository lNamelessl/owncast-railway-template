# Owncast on Railway — Your Own Live Streaming Server

[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/deploy/owncast-template-final)

Self-hosted live streaming in one click: push a stream from OBS (or any RTMP encoder), viewers watch in any browser over HLS, and chat is built in. Deployed from the official [`owncast/owncast:0.3.0`](https://hub.docker.com/r/owncast/owncast) image — one service, one persistent volume, no external database.

**Zero prompts at deploy time** — nothing to fill in. The one service, its volume, the public HTTP domain and the RTMP TCP proxy are all provisioned automatically.

## First run — REQUIRED (2 minutes)

The server boots with well-known defaults. Before you go live publicly:

1. Open `https://your-server.up.railway.app/admin`
2. Sign in with username `admin`, password `abc123`
3. **Change the admin password** (Server Setup)
4. **Change the stream key** (Server Setup → Stream Keys) — the default `abc123` is public knowledge
5. Save — both live in the SQLite database on your volume, so they survive restarts

## OBS setup

| OBS field | Value |
|---|---|
| Server | `rtmp://your-tcp-proxy.proxy.rlwy.net:PORT/live` |
| Stream Key | your new stream key |

Find the RTMP host/port under your service's Settings → Networking → TCP Proxy (e.g. `xyz.proxy.rlwy.net:12345`). Viewers watch at `https://your-server.up.railway.app/`.

## What you get

| Component | Detail |
|---|---|
| `owncast` service | Official image `owncast/owncast:0.3.0` (pinned), ffmpeg bundled, ~1 GB RAM |
| HTTP port 8080 | Web player, `/admin` panel, chat, HLS playback (`/hls/stream.m3u8`) |
| TCP proxy 1935 | RTMP ingest from OBS / ffmpeg (external port assigned by Railway) |
| Volume `/app/data` | SQLite database (all config, keys, settings), recordings, logs, backups |
| Health check | service self-reports via `GET /api/status`; Railway restart policy ON_FAILURE |

# Deploy and Host

## About Hosting

This template provisions a single Railway service running the official Owncast Docker image (pinned to `0.3.0`) with a 5 GB volume mounted at `/app/data`, a Railway-generated public domain routed to the web/HLS port 8080, and a public TCP proxy routed to the RTMP ingest port 1935. Owncast is a single Go binary with SQLite storage — all configuration (stream key, admin password, appearance, integrations) is stored in the database on the volume, so every setting survives restarts and redeploys. The deploy form asks for nothing: the one variable the template sets (`RAILWAY_RUN_UID=0`) ships pre-configured so the container can write to its volume. After deploy, the only required steps are in the Owncast admin: change the default admin password (`admin`/`abc123`) and change the default stream key (`abc123`) — both under Server Setup at `/admin`.

## Why Deploy

Hosting Owncast on Railway gives you a URL-based streaming server without renting a VPS or opening firewall ports: RTMP ingest works through Railway's TCP proxy and HLS playback is served over HTTPS through the standard public domain — no UDP required. Scaling up is one click, usage is billed per second (a mostly-idle server costs pennies while you are not streaming), and the volume keeps your configuration, recordings, and logs across restarts. Compared to running the Docker image manually, this template already wires the two things that usually trip people up on Railway: volume permissions for the non-root image (`RAILWAY_RUN_UID=0`) and the TCP proxy for RTMP. For liveness, the service exposes `GET /api/status` (returns `"online"`, version, viewer counts) and Railway's ON_FAILURE restart policy recovers crashed containers automatically.

## Common Use Cases

- Personal live streaming to an audience with real-time chat (OBS → Owncast → viewers' browsers)
- Community or event streams with moderation: bans, timeouts, established-user mode, chat-only-when-offline
- Private streams: disable the discovery directory, require an access code, or turn off anonymous chat
- Church services, classrooms, game nights, and creator streams where you want to own the pipeline and the player, without platform ads or algorithms

## Dependencies for

### Deployment Dependencies

None external. Owncast is a single self-contained binary: ffmpeg is bundled inside the official image, storage is SQLite on the attached volume, and there is no separate database, cache, or object storage service. The template provisions exactly one service plus one volume; the only variable, `RAILWAY_RUN_UID=0`, is pre-set so the image's non-root filesystem user can write to `/app/data`.

## Cost honesty

Baseline service usage is modest (~$5–10/mo range while idle). The variable is **viewer bandwidth: Railway bills egress at ~$0.05/GB**. A 720p stream at ~2.5 Mbps is roughly 1.1 GB per viewer-hour — a 2-hour stream with 10 concurrent viewers ≈ 20 GB ≈ $1. Lower your OBS bitrate and keep one video variant (Admin → Video) if costs matter.

## Troubleshooting

- **OBS "Failed to connect"** — use the TCP proxy host/port, not your main domain, and check the key matches Server Setup.
- **"Authentication error" in OBS** — wrong stream key; copy it fresh from Admin → Server Setup.
- **Player spins forever** — you are offline (or HLS needs a few seconds of segments). `/api/status` should show `"online": true` while streaming.
- **Dropped frames** — one vCPU is saturated: lower bitrate, keep 1 video variant.
- **WebRTC?** — not on Railway; playback is HLS over HTTPS (the TCP proxy cannot carry UDP).

## Links

- Upstream: https://github.com/owncast/owncast · Docs: https://owncast.online/docs/
- Template source repo: https://github.com/lNamelessl/owncast-railway-template
