# Owncast on Railway

[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/deploy/owncast-template)


Your own live streaming server — RTMP ingest from OBS, HLS playback in any browser, built-in chat. One service, one volume, no external database.

Deployed from the official image [`owncast/owncast:0.3.0`](https://hub.docker.com/r/owncast/owncast) (pinned).

## First run — REQUIRED (2 minutes)

The server ships with well-known defaults. **Before you stream publicly, change both:**

1. Open `https://<your-railway-domain>/admin`
2. Sign in with username `admin`, password `abc123`
3. **Change the admin password** (top of Server Setup)
4. **Change the stream key** (Server Setup → Stream Keys) — the default is `abc123` and everyone knows it
5. Save. Both are stored in the database on your persistent volume, so they survive restarts.

## OBS setup

| OBS field | Value |
|---|---|
| Server | `rtmp://<tcp-proxy-host>:<tcp-proxy-port>/live` |
| Stream Key | your new stream key (from step 4 above) |

- The RTMP host/port is **not** your main Railway domain. Find it in Railway → your Owncast service → Settings → Networking → TCP Proxy (looks like `xyz.proxy.rlwy.net:12345`).
- Recommended OBS output: x264, 1500–2500 kbps, keyframe interval 2 s.
- Viewers watch at `https://<your-railway-domain>/` — no software needed (HLS).

## What runs where

| Port | Protocol | Use |
|---|---|---|
| 8080 (HTTP domain) | HLS + web | Player, admin panel, chat, API |
| 1935 (TCP proxy) | RTMP | Ingest from OBS / ffmpeg |

| Volume path | Contents |
|---|---|
| `/app/data` | SQLite database (all config, stream key, admin password), HLS segments, recordings, logs, backups |

## Chat moderation

Admin → Chat: ban/timeout users, purge messages, set chat-only mode while offline, require an access code, or disable anonymous chat entirely (Chat → "Set enabled" per user; Moderation page for live controls).

## Cost honesty

Baseline: service usage (~$5–10/mo at low traffic; Owncast idles light but ffmpeg transcodes while live). **The variable is viewer bandwidth: Railway bills egress at ~$0.05/GB.** A 720p stream at ~2.5 Mbps is ≈ 1.1 GB per viewer-hour — a 2-hour stream with 10 concurrent viewers ≈ 20 GB ≈ $1. If costs climb, lower your OBS bitrate and delete extra video variants (Admin → Video — keep 1 variant on Railway's default 1 vCPU).

## Troubleshooting

- **OBS: "Failed to connect" / RTMP timeout** — check the TCP proxy host/port in Railway (not port 1935 externally; Railway assigns a random port), and that your stream key matches Server Setup.
- **OBS: authentication error** — wrong stream key. It changed in first run; copy it fresh from Admin → Server Setup.
- **Player spins forever** — you are not live (or just went live; HLS needs a few seconds of segments). Confirm `/api/status` shows `"online": true`.
- **Dropped frames / stutter** — single vCPU transcode is saturated: lower OBS bitrate, keep 1 video variant.
- **WebRTC playback?** — not offered on Railway: HLS over HTTP is the playback path (UDP hole-punching for WebRTC isn't supported through the TCP proxy).

## Links

- Upstream: https://github.com/owncast/owncast · Docs: https://owncast.online/docs/
- This is a community deployment recipe; Owncast is (c) its authors, MIT-licensed.
