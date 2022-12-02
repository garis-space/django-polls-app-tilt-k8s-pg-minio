#!/bin/bash
set -e

if [ "$1" = 'server' ]; then
    exec gunicorn --workers 2 --threads 4 --timeout 60 --access-logfile '-' \
        --error-logfile '-' --bind=0.0.0.0:8000 app.wsgi
fi

if [ "$1" = 'migrate' ]; then
	exec python manage.py migrate
fi

if [ "$1" = 'collectstatic' ]; then
    exec python manage.py collectstatic --noinput
fi

exec "$@"
