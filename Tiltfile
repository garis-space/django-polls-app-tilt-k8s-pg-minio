# Disable Titl analytics
analytics_settings(enable=False)

# Disable Tilt redacted secret
secret_settings(disable_scrub=True)

# Load Tilt extensions (https://github.com/tilt-dev/tilt-extensions)
load('ext://helm_resource', 'helm_resource', 'helm_repo')
load('ext://uibutton', 'cmd_button', 'bool_input', 'text_input', 'location')
load('ext://secret', 'secret_create_generic', 'secret_from_dict')
load('ext://configmap', 'configmap_create')
load('ext://dotenv', 'dotenv')

# Check if Kubernetes context is set to docker-desktop
if k8s_context() != 'docker-desktop':
    fail('Kubernetes context is not set to docker-desktop')

# Read .env file
dotenv('.env')

###
# PostgreSQL
###

# Create secrets for PostgreSQL
k8s_yaml(secret_from_dict("django-polls-postgresql", inputs = {
    'postgres-password' : os.getenv('POSTGRESQL_PASSWORD')
}))

# Add PostgreSQL Helm resource (https://artifacthub.io/packages/helm/bitnami/postgresql)
helm_repo('bitnami', 'https://charts.bitnami.com/bitnami')
helm_resource(
    name='postgresql',
    chart='bitnami/postgresql',
    namespace='default',
    flags=[
        '--set=image.tag=15-debian-11',
        # Load secret values from created secret
        '--set=global.postgresql.auth.existingSecret=django-polls-postgresql',
    ],
    labels=['database']
)

###
# Adminer
###

# Add Adminer Helm resource (https://artifacthub.io/packages/helm/cetic/adminer)
helm_repo('cetic', 'https://cetic.github.io/helm-charts')
helm_resource(
    name='adminer',
    chart='cetic/adminer',
    namespace='default',
    flags=[
        '--set=service.type=LoadBalancer',
        '--set=service.port=8080',
        '--set=config.externalserver=postgresql',
    ],
    labels=['database']
)

###
# MinIO
###

# Create secrets for MinIO
k8s_yaml(secret_from_dict("django-polls-minio", inputs = {
    'rootUser' : os.getenv('MINIO_ROOT_USER'),
    'rootPassword' : os.getenv('MINIO_ROOT_PASSWORD'),
}))

# Add MinIO Helm resource (https://artifacthub.io/packages/helm/minio/minio)
helm_repo('minio', 'https://charts.min.io')
#update_settings(k8s_upsert_timeout_secs=120)
helm_resource(
    name='minio-s3',
    chart='minio/minio',
    namespace='default',
    flags=[
        # Load secret values from created secret
        '--set=existingSecret=django-polls-minio',
        '--set=service.type=LoadBalancer',
        '--set=mode=standalone',
        '--set=persistence.enabled=false',
        '--set=replicas=1',
        '--set=consoleService.type=LoadBalancer',
        '--set=resources.requests.memory=256Mi',
        # Add buckets
        '--set=buckets[0].name=static,buckets[0].policy=public',
        '--set=buckets[1].name=media,buckets[1].policy=public',
    ],
    labels=['storage']
)

###
# Django
###

# Create a secrets from .env file for Django app
secret_create_generic('django-polls', from_env_file='.env')

# Build Django polls app
docker_build(
    'app/django-polls',
    context='./django-polls',
    live_update=[
        sync('django-polls', '/app'),
        run('cd /app && pip install -r requirements-dev.txt',
            trigger=['./django-polls/requirements.txt', './django-polls/requirements-dev.txt']),
        run('cd /app && python manage.py migrate',
            trigger=['./django-polls/polls/migrations']),
        run('cd /app && python manage.py collectstatic --noinput',
            trigger=['./django-polls/polls/static']),
    ],
)

# Kubernetes deployment
k8s_yaml('./django-polls/k8s.yml')

# Kubernetes create resource
k8s_resource(
    'django-polls',
    port_forwards=8000,
    resource_deps=['postgresql', 'minio'],
    labels=['app'],
)

###
# Custom commands for Tilt
###

# Add a button to quickly run a command in a pod
pod_exec_script = '''
    set -eu
    # get k8s pod name from tilt resource name
    POD_NAME="$(tilt get kubernetesdiscovery "$resource" -ojsonpath='{.status.pods[0].name}')"
    kubectl exec "$POD_NAME" -- $command
'''
cmd_button('podexec',
    argv=['sh', '-c', pod_exec_script],
    location=location.NAV,
    icon_name='',
    text='Exec in a pod',
    inputs=[
        text_input('resource'),
        text_input('command'),
    ]
)

# Add a button to quickly create a superuser
cmd_button('django-polls:createsuperuser',
    argv=['sh', '-c', pod_exec_script],
    env=[
        'resource=django-polls',
        'command=python manage.py createsuperuser --noinput --username {} --email {}'.format(
            os.getenv('DJANGO_SUPERUSER_USERNAME'),
            os.getenv('DJANGO_SUPERUSER_EMAIL')
        ),
    ],
    resource='django-polls',
    icon_name='login',
    text='create superuser',
)

# Add a button to run tests
cmd_button('django-polls:test',
    argv=['sh', '-c', pod_exec_script],
    env=[
        'resource=django-polls',
        'command=python manage.py test',
    ],
    resource='django-polls',
    icon_name='check_circle',
    text='run app tests',
)
