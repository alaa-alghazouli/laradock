#!/bin/bash
set -e

# Ensure required variables are set
: "${CERTBOT_CN:?CERTBOT_CN (Common Name) must be set}"
: "${CERTBOT_EMAIL:?CERTBOT_EMAIL must be set}"

echo "[INFO] USE_CLOUDFLARE_CHALLENGE is set to: ${USE_CLOUDFLARE_CHALLENGE}"

# Normalize primary domain for path usage
PRIMARY_DOMAIN=$(echo "$CERTBOT_CN" | cut -d',' -f1)

if [ "$USE_CLOUDFLARE_CHALLENGE" = "true" ]; then
    echo "[INFO] Using Cloudflare DNS challenge"

    # Prepare Cloudflare credentials
    envsubst < /root/cloudflare.ini.template > /root/.secrets/certbot/cloudflare.ini
    chmod 600 /root/.secrets/certbot/cloudflare.ini

    # Request certificate if not already present
    if [ ! -f "/etc/letsencrypt/live/${PRIMARY_DOMAIN}/fullchain.pem" ]; then
        certbot certonly \
            --dns-cloudflare \
            --dns-cloudflare-credentials /root/.secrets/certbot/cloudflare.ini \
            --dns-cloudflare-propagation-seconds 60 \
            --non-interactive \
            --agree-tos \
            $(echo "$CERTBOT_CN" | sed 's/,/ -d /g' | sed 's/^/-d /')
    fi

else
    echo "[INFO] Using Webroot HTTP challenge"

    mkdir -p /var/www/letsencrypt /var/certs

    if [ ! -f "/etc/letsencrypt/live/${PRIMARY_DOMAIN}/fullchain.pem" ]; then
        certbot certonly \
            --webroot \
            -w /var/www/letsencrypt \
            --agree-tos \
            --email "$CERTBOT_EMAIL" \
            --non-interactive \
            --text \
            --staging \
            $(echo "$CERTBOT_CN" | sed 's/,/ -d /g' | sed 's/^/-d /')
        
        /root/copy-certs.sh "$PRIMARY_DOMAIN"
    fi
fi

# Background loop for renewal
while true; do
    echo "[certbot] Running renew @ $(date)"
    
    if [ "$USE_CLOUDFLARE_CHALLENGE" = "true" ]; then
        certbot renew \
            --quiet \
            --deploy-hook "docker exec laradock-nginx-1 nginx -s reload" \
            || echo "[certbot] Renewal attempt failed"
    else
        certbot renew \
            --quiet \
            --deploy-hook "/root/copy-certs.sh ${PRIMARY_DOMAIN} && docker exec laradock-nginx-1 nginx -s reload" \
            || echo "[certbot] Renewal attempt failed"
    fi

    sleep 12h
done
