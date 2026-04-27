# ECS Deployment Runbook

This runbook is for the China-first backend deployment on an Alibaba Cloud or Tencent Cloud ECS/CVM instance. It avoids Docker, so it works even when the server only has Node.js, systemd, and Nginx.

## Recommended Server Shape

- Ubuntu 22.04 or 24.04 LTS
- 1 vCPU / 2 GB RAM minimum for TestFlight and early MVP
- 40 GB system disk
- Persistent backup for `/var/lib/viralforge`
- Security group inbound: `80`, `443`, and SSH from your IP only

## Server Layout

```text
/opt/viralforge/backend          app code
/etc/viralforge/backend.env      production env vars
/etc/viralforge/AuthKey_*.p8     App Store Server API private key
/var/lib/viralforge              SQLite data
```

## One-Time Server Setup

```sh
sudo useradd --system --home /opt/viralforge --shell /usr/sbin/nologin viralforge
sudo mkdir -p /opt/viralforge/backend /etc/viralforge /var/lib/viralforge
sudo chown -R viralforge:viralforge /opt/viralforge /var/lib/viralforge
sudo chmod 750 /etc/viralforge
```

Install Node.js 22 and Nginx using your cloud image's standard package flow. After Node is installed, verify:

```sh
node --version
nginx -v
```

## Upload App Files

Copy the backend folder contents to:

```text
/opt/viralforge/backend
```

Do not upload local `.env`, SQLite files, or `.p8` keys into the app folder.

## Environment

Create:

```text
/etc/viralforge/backend.env
```

Use `backend.env.example` as the template. Keep file permissions tight:

```sh
sudo chown root:viralforge /etc/viralforge/backend.env
sudo chmod 640 /etc/viralforge/backend.env
```

For the China-first release, use:

```env
AI_PROVIDER_MODE=china_live
```

## systemd

Install the service:

```sh
sudo cp viralforge-backend.service /etc/systemd/system/viralforge-backend.service
sudo systemctl daemon-reload
sudo systemctl enable viralforge-backend
sudo systemctl start viralforge-backend
```

Check:

```sh
sudo systemctl status viralforge-backend
journalctl -u viralforge-backend -f
curl http://127.0.0.1:8787/health
```

## Nginx

Install the Nginx config:

```sh
sudo cp nginx-viralforge.conf /etc/nginx/sites-available/viralforge.conf
sudo ln -s /etc/nginx/sites-available/viralforge.conf /etc/nginx/sites-enabled/viralforge.conf
sudo nginx -t
sudo systemctl reload nginx
```

Replace `api.example.com` with the real backend domain.

## HTTPS

Use the cloud provider certificate service, Certbot, or your existing certificate flow. App Store Server Notifications require a public HTTPS endpoint:

```text
https://YOUR_BACKEND_DOMAIN/api/app-store/notifications/v2
```

## Smoke Tests

```sh
curl https://YOUR_BACKEND_DOMAIN/health
curl https://YOUR_BACKEND_DOMAIN/api/providers/status
curl https://YOUR_BACKEND_DOMAIN/api/app-store/status
```

Expected first China release provider mode:

```json
{
  "mode": "china_live",
  "market": "china"
}
```

## iOS Setting

After the public HTTPS URL is ready, update the iOS backend base URL from localhost to:

```text
https://YOUR_BACKEND_DOMAIN
```

Then rebuild and submit the TestFlight build.
