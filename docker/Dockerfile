FROM ubuntu:24.04
ENV DEBIAN_FRONTEND=noninteractive TZ=Asia/Jakarta LANG=C.UTF-8

# Core cluster stack + tooling (includes pacemaker-cli-utils as requested)
RUN apt-get update \
 && apt-get install -y --no-install-recommends software-properties-common gnupg ca-certificates curl \
 && add-apt-repository -y universe \
 && apt-get update \
 && apt-get install -y --no-install-recommends \
      pacemaker corosync pcs pacemaker-cli-utils \
      resource-agents-base resource-agents-extra \
      drbd-utils iproute2 iputils-ping iputils-arping net-tools dnsutils \
      openssl supervisor procps vim less kmod e2fsprogs lsof jq postgresql-client \
 && rm -rf /var/lib/apt/lists/*

# Minimal users & move runtime to /home/cluster (keep pacemaker state default)
RUN groupadd -r haclient 2>/dev/null || true \
 && id -u hacluster >/dev/null 2>&1 || useradd -r -s /usr/sbin/nologin hacluster \
 && mkdir -p /home/cluster/pcsd \
              /home/cluster/log/pcsd \
              /home/cluster/log/supervisor \
              /home/cluster/supervisor/conf.d

# Redirect pcsd default paths via symlink; keep /var/lib/pacemaker default
RUN mkdir -p /var/lib /var/log \
 && rm -rf /var/lib/pcsd /var/log/pcsd \
 && ln -s /home/cluster/pcsd /var/lib/pcsd \
 && ln -s /home/cluster/log/pcsd /var/log/pcsd

# Default supervisor config (can be overridden by bind-mount from host)
RUN printf "%s\n" \
"[unix_http_server]" \
"file=/var/run/supervisor.sock" \
"chmod=0700" \
"[supervisord]" \
"nodaemon=true" \
"logfile=/home/cluster/log/supervisor/supervisord.log" \
"pidfile=/home/cluster/supervisord.pid" \
"childlogdir=/home/cluster/log/supervisor" \
"[rpcinterface:supervisor]" \
"supervisor.rpcinterface_factory=supervisor.rpcinterface:make_main_rpcinterface" \
"[supervisorctl]" \
"serverurl=unix:///var/run/supervisor.sock" \
"[include]" \
"files=/home/cluster/supervisor/conf.d/*.conf" \
> /etc/supervisor/supervisord.conf

# Default programs (can be overridden by host file)
RUN printf "%s\n" \
"[program:pcsd]" \
"command=/usr/sbin/pcsd" \
"autorestart=true" \
"priority=10" \
"stderr_logfile=/home/cluster/log/pcsd/pcsd.err.log" \
"stdout_logfile=/home/cluster/log/pcsd/pcsd.out.log" \
"" \
"[program:corosync]" \
"command=/usr/sbin/corosync -f" \
"autorestart=true" \
"priority=20" \
"stderr_logfile=/home/cluster/log/corosync.err.log" \
"stdout_logfile=/home/cluster/log/corosync.out.log" \
"" \
"[program:pacemaker]" \
"command=/usr/sbin/pacemakerd -f" \
"autorestart=true" \
"priority=30" \
"stderr_logfile=/home/cluster/log/pacemaker.err.log" \
"stdout_logfile=/home/cluster/log/pacemaker.out.log" \
> /home/cluster/supervisor/conf.d/pacemaker.conf

HEALTHCHECK --interval=10s --timeout=3s --retries=15 \
  CMD corosync-cmapctl totem.nodeid >/dev/null 2>&1 || exit 1

ENTRYPOINT ["/usr/bin/supervisord","-c","/etc/supervisor/supervisord.conf"]
