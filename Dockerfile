# Owncast on Railway: official image, pinned version.
# CMD appends to the image ENTRYPOINT (/app/owncast).
# -webserverip=[::] makes Owncast listen on all interfaces (dual-stack):
# Railway's healthcheck probes over IPv6 private networking, and Owncast's
# default bind of 0.0.0.0 (IPv4-only) would fail the probe.
FROM owncast/owncast:0.3.0
CMD ["-webserverip=[::]"]
