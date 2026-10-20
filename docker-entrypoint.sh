#!/bin/sh
set -e

PORT="${PORT:-8000}"
MERCURE_PORT="${MERCURE_PORT:-3000}"
MERCURE_JWT_SECRET="${MERCURE_JWT_SECRET:-change-me-in-production}"

# Warm up cache if not already done
echo "Warming up Symfony cache..."
APP_ENV=prod php bin/console cache:warmup --no-debug || true

# Run migrations if DATABASE_URL is set
if [ ! -z "$DATABASE_URL" ]; then
    echo "Running database migrations..."
    php bin/console doctrine:migrations:migrate --no-interaction
fi

# Start the Mercure hub in the background
echo "Starting Mercure hub on port ${MERCURE_PORT}"
export ADDR="0.0.0.0:${MERCURE_PORT}"
/usr/local/bin/mercure \
    --jwt-key="${MERCURE_JWT_SECRET}" \
    --publisher-jwt-key="${MERCURE_JWT_SECRET}" \
    --subscriber-jwt-key="${MERCURE_JWT_SECRET}" \
    --allow-anonymous \
    --cors-allowed-origins="*" \
    --transport-url="bolt:///var/mercure/mercure.db" \
    &

echo "Starting PHP server on port ${PORT}"
exec php -S "0.0.0.0:${PORT}" -t public
