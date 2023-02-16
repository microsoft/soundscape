# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

import argparse
from functools import cmp_to_key
import json
import os
import re
import subprocess
import asyncio
import time
import uuid

import semver

from azure.identity import DefaultAzureCredential
from azure.mgmt.resource import ResourceManagementClient, SubscriptionClient
from azure.mgmt.containerregistry import ContainerRegistryManagementClient
from azure.mgmt.authorization import AuthorizationManagementClient
from azure.graphrbac import GraphRbacManagementClient

small_db_size = 90
large_db_size = 1100
small_cpu_sku = 'Standard_DS3_v2'
large_cpu_sku = 'Standard_DS4_v2'
small_db_sku = 'Standard_D2s_v3'
large_db_sku = 'Standard_D4s_v3'

scale_parameters = {
    'test': {
        'node_count': 1,
        'nginx_count': 1,
        'vm_sku': small_cpu_sku,
        'db_sku': small_db_sku,
        'db_size': small_db_size,
        'nginx_log': True,
        'values': None,
    },
    'stress': {
        'node_count': 1,
        'nginx_count': 1,
        'vm_sku': small_cpu_sku,
        'db_sku': small_db_sku,
        'db_size': small_db_size,
        'nginx_log': True,
        'values': ['values-stress.yaml'],
        'stress': True
    },
    'production-test': {
        'node_count': 1,
        'nginx_count': 1,
        'vm_sku': small_cpu_sku,
        'db_sku': small_db_sku,
        'db_size': small_db_size,
        'nginx_log': True,
        'values': None,
    },
    'test-big': {
        'node_count': 3,
        'nginx_count': 1,
        'vm_sku': large_cpu_sku,
        'db_sku': large_db_sku,
        'db_size': large_db_size,
        'nginx_log': False,
        'values': ['values-production.yaml']
    },
    'stress-big': {
        'node_count': 3,
        'nginx_count': 1,
        'vm_sku': large_cpu_sku,
        'db_sku': large_db_sku,
        'db_size': large_db_size,
        'nginx_log': False,
        'values': ['values-production.yaml', 'values-stress.yaml', 'values-stress-big.yaml'],
        'stress': True
    },
    'production': {
        'node_count': 3,
        'nginx_count': 2,
        'vm_sku': large_cpu_sku,
        'db_sku': large_db_sku,
        'db_size': large_db_size,
        'nginx_log': False,
        'values': ['values-production.yaml']
    },
    'production-backup': {
        'node_count': 1,
        'nginx_count': 2,
        'vm_sku': large_cpu_sku,
        'db_sku': large_db_sku,
        'db_size': large_db_size,
        'nginx_log': False,
        'values': ['values-production.yaml', 'values-backup.yaml']
    }
}

def run_with_retry(args, count, **kwargs):
    if count <= 0:
        return

    for n in range(0, count - 1):
        try:
            subprocess.run(args, check=True, **kwargs)
            return
        except Exception:
            print('DELAYING BEFORE RETRY')
            time.sleep(30)
    subprocess.run(args, check=True, **kwargs)

async def async_run(args, **kwargs):
    proc = await asyncio.create_subprocess_exec(*args, **kwargs)
    (stdout_data, _) = await proc.communicate()
    return proc, stdout_data

async def async_run_check(args, **kwargs):
    proc, stdout_data = await async_run(args, **kwargs)
    if proc.returncode == 0:
        return proc, stdout_data
    raise Exception('ERROR: ' + ' '.join(args))

async def run_with_retry_async(args, count):
    if count <= 0:
        return

    for n in range(0, count - 1):
        proc, _ = await async_run(args)
        if proc.returncode == 0:
            return;
        await asyncio.sleep(30)
    await async_run_check(args)

def run_with_retry_io(args, count):
    for n in range(0, count - 1):
        try:
            return subprocess.run(args, check=True, stdout=subprocess.PIPE)
        except Exception:
            print('DELAYING BEFORE RETRY')
            time.sleep(30)
    return subprocess.run(args, check=True, stdout=subprocess.PIPE)

# Pick kubernetes version that is current but not the latest minor version
# N.B. This is consistent with what Azure says they do but not how it behaves
def determine_kubernetes_version(config, location, exclude_preview):
    args = [
        'az',
        'aks',
        'get-versions',
        '--subscription', config['subscription_id'],
        '--output', 'json',
        '--location', location,
    ]

    completed = subprocess.run(args, check=True, stdout=subprocess.PIPE)
    output = json.loads(completed.stdout.decode('ascii'))

    orchestrators = output['orchestrators']
    if exclude_preview:
        orchestrators = filter(lambda x: not x['isPreview'], orchestrators)
    kube_versions = map(lambda o: str(o['orchestratorVersion']), orchestrators)
    kube_versions = sorted(kube_versions, key=cmp_to_key(semver.cmp), reverse=True)

    return kube_versions[0]

def check_kubernetes_cluster_name(config, location):
    args = [
        'az',
        'aks',
        'show',
        '--subscription', config['subscription_id'],
        '--resource-group', config['resource_group'],
        '--name', config['cluster_name'],
        '--output', 'none'
    ]

    completed = subprocess.run(args, stderr=subprocess.DEVNULL, stdout=subprocess.DEVNULL)
    if completed.returncode == 0:
        print('ERROR: kubernetes service with name \'{0}\' already exists'.format(config['cluster_name']))
        exit(1)

async def create_vnet_subnet(config, vnetsub_name, prefix, disable_network_policy, configure_postgres):
    args = [
        'az',
        'network',
        'vnet',
        'subnet',
        'create',
        '--subscription', config['subscription_id'],
        '--resource-group', config['resource_group'],
        '--vnet-name', config['vnet_name'],
        '--name', vnetsub_name,
        '--address-prefixes', prefix,
        '--output', 'json'
    ]

    if disable_network_policy:
       args.extend(['--disable-private-endpoint-network-policies', 'true'])

    if configure_postgres:
        args.extend(['--delegations', 'Microsoft.DBforPostgreSQL/flexibleServers'])
        args.extend(['--service-endpoints', 'Microsoft.Storage'])

    completed, stdout_data = await async_run_check(args, stdout=asyncio.subprocess.PIPE)
    output = json.loads(stdout_data.decode('ascii'))
    return output['id']

async def create_vnet(config):
    args = [
        'az',
        'network',
        'vnet',
        'create',
        '--subscription', config['subscription_id'],
        '--location', config['location'],
        '--name', config['vnet_name'],
        '--resource-group', config['resource_group'],
        '--address-prefixes', '10.0.0.0/8',
        '--output', 'none'
    ]

    await async_run_check(args)

    snets = config['snets']
    snet_ids = {}
    for (snet, prefix) in zip(snets.keys(), range(240, 255)):
        ip_mask = '10.{0}.0.0/16'.format(prefix)
        disable_network_policy = snets[snet].get('disable_network_policy', False)
        configure_postgres = snets[snet].get('configure_postgres', False)
        snet_ids[snet] =  await create_vnet_subnet(config, snets[snet]['name'], ip_mask, disable_network_policy, configure_postgres)

    return snet_ids

def delete_vnet_subnet(config, vnet_subname):
    args = [
        'az',
        'network',
        'vnet',
        'subnet',
        'delete',
        '--subscription', config['subscription_id'],
        '--vnet-name', config['vnet_name'],
        '--resource-group', config['resource_group'],
        '--name', vnet_subname,
    ]

    print('TASK: delete vnet subnet: {0}'.format(vnet_subname))
    subprocess.run(args, check=False, stderr=subprocess.DEVNULL)

def delete_vnet(config):

    for snet, v in config['snets'].items():
        delete_vnet_subnet(config, v['name'])

    args = [
        'az',
        'network',
        'vnet',
        'delete',
        '--subscription', config['subscription_id'],
        '--resource-group', config['resource_group'],
        '--name', config['vnet_name'],
    ]

    subprocess.run(args, check=True)

# N.B. no AKS api
async def create_kubernetes_cluster(config, location, mi_cluster, podsub_id, nodesub_id, container_registry_id):
    print('TASK:   create kubernetes cluster: STARTED')
    start = time.perf_counter()

    # N.B. move this code elsewhere?
    if not config['kubernetes_version']:
        kubernetes_version = determine_kubernetes_version(config, location, True)
    elif config['kubernetes_version'] == 'latest':
        kubernetes_version = determine_kubernetes_version(config, location, False)
    else:
        kubernetes_version = config['kubernetes_version']

    try:
        os.remove(os.environ['HOME'] + '/.azure/aksServicePrincipal.json')
    except Exception:
        pass

    addons = ','.join(['monitoring', 'azure-keyvault-secrets-provider', 'azure-policy'])

    args = [
        'az',
        'aks',
        'create',
        '--subscription', config['subscription_id'],
        '--resource-group', config['resource_group'],
        '--location', config['location'],
        '--name', config['cluster_name'],
        '--generate-ssh-keys',
        '--node-count', str(config['parameters']['node_count']),
        '--node-vm-size', config['parameters']['vm_sku'],
        '--os-sku', 'CBLMariner',
        '--load-balancer-sku', 'standard',
        '--auto-upgrade-channel', 'node-image',
        '--enable-addons', addons,
        '--enable-secret-rotation',
        '--attach-acr', container_registry_id,
        '--enable-managed-identity',
        '--assign-identity', mi_cluster['id'],
        '--enable-pod-identity',
        '--network-plugin', 'azure',
        '--vnet-subnet-id', nodesub_id,
        '--pod-subnet-id', podsub_id,
        '--output', 'none'
    ]

    if kubernetes_version:
        args.extend(['--kubernetes-version', kubernetes_version])

    if not config['production']:
        args.extend(['--auto-upgrade-channel', 'rapid'])

    try:
        os.remove(os.environ['HOME'] + '/.azure/aksServicePrincipal.json')
    except Exception:
        pass

    await run_with_retry_async(args, 5)
    end = time.perf_counter()
    print('TASK:   create kubernetes cluster: DONE took {0:.2f}s'.format(end-start))

# N.B. no AKS api
async def delete_kubernetes_cluster(config):

    print('TASK:   delete kubernetes cluster: STARTED')
    args = [
        'az',
        'aks',
        'delete',
        '--subscription', config['subscription_id'],
        '--resource-group', config['resource_group'],
        '--name', config['cluster_name'],
        '--output', 'none',
        '--yes'
    ]

    await async_run_check(args)
    print('TASK:   delete kubernetes cluster: DONE')

# N.B. no AKS api
def get_aks_credentials(config):
    args = [
        'az',
        'aks',
        'get-credentials',
        '--subscription', config['subscription_id'],
        '--resource-group', config['resource_group'],
        '--name', config['cluster_name'],
        '--overwrite-existing'
    ]

    subprocess.run(args, check=True)

def get_container_registry_info(config, container_registry):
    registry = config['acr_client'].registries.get(config['infra']['resource_group'], container_registry)
    return registry.login_server, registry.id

async def allow_pod_mi_to_access_keyvault_certificates(config, mi_pod):

    args = [
        'az',
        'keyvault',
        'set-policy',
        '--subscription', config['infra']['subscription_id'],
        '--name', config['infra']['keyvault_name'],
        '--spn', mi_pod['clientId'],
        '--certificate-permissions', 'get',
        '--key-permissions', 'get',
        '--secret-permissions', 'get',
        '--output', 'none'
    ]
    await run_with_retry_async(args, 5)

def helm_init(config):
    args = [
        'helm',
        'repo',
        'add',
        '--namespace', config['namespace'],
        'ingress-nginx', 'https://kubernetes.github.io/ingress-nginx'
    ]

    subprocess.run(args, check=True)

    args = [
        'helm',
        'repo',
        'update',
        '--namespace', config['namespace'],
    ]

    subprocess.run(args, check=True)

def nginx_ingress_install(config, name, ip_address, identity_name):
    parameters = config['parameters']
    args = [
        'helm',
        'install',
        name,
        'ingress-nginx/ingress-nginx',
        '--version', nginx_chart_version,
        '--namespace', config['namespace'],
        '--set-string', 'controller.extraArgs.enable-ssl-chain-completion=false',
        '--set', 'controller.image.registry=mcr.microsoft.com/oss/kubernetes',
        '--set', 'controller.image.digest=null',
        '--set', 'controller.allowSnippetAnnotations=false',
        '--set', 'controller.replicaCount={0}'.format(parameters['nginx_count']),
        '--set', 'controller.service.loadBalancerIP={0}'.format(ip_address),
        '--set', 'controller.service.externalTrafficPolicy=Local',
        '--set', 'controller.service.annotations.service\.beta\.kubernetes\.io/azure-dns-label-name={0}'.format(config['dns_name']),
        '--set', 'controller.podLabels.aadpodidbinding={0}'.format(identity_name),
        '-f', 'soundscape/other/nginx-csi-patch.yaml'
    ]

    if nginx_override:
        args.extend(['--set', 'controller.image.image={0}'.format(nginx_image_name)])

    if not parameters['nginx_log']:
        args.extend(['--set-string', 'controller.config.disable-access-log=true'])

    subprocess.run(args, check=True)

def service_install(config, container_registry_login, release, tenant):
    args = [
        'helm',
        'install',
        '--namespace', config['namespace'],
        'soundscape-service',
        'soundscape'
    ]

    parameters = config['parameters']
    if parameters['values']:
        for v in parameters['values']:
            args.extend(['--values', 'soundscape/' + v])

    args.extend(['--set', 'soundscapeImageVersion=' + release,
                 '--set', 'containerRegistry={0}'.format(container_registry_login),
                 '--set', 'keyVault={0}'.format(config['infra']['keyvault_name']),
                 '--set', 'tenantId={0}'.format(tenant),
                 '--set', 'subscription_id={0}'.format(config['subscription_id'])
    ])

    subprocess.run(args, check=True)

def check_for_secret(config, secret):

    args = [
        'kubectl',
        'get',
        '-n', config['namespace'],
        'secret',
        secret
    ]

    run_with_retry(args, 5, stderr=subprocess.DEVNULL, stdout=subprocess.DEVNULL)

def stress_install(config, container_registry_login, service_version):

    image = '{0}/{1}:{2}'.format(container_registry_login, 'soundscape/stress', service_version)

    args = [
        'kubectl',
        'create',
        '-n', config['namespace'],
        'deployment',
        'soundscape-stress',
        '--image', image
    ]

    run_with_retry(args, 5)

def service_upgrade(config, service_version):
    args = [
        'helm',
        'upgrade',
        '--namespace', config['namespace'],
        'soundscape-service',
        'soundscape'
    ]

    args.extend(['--reuse-values',
                 '--set', 'soundscapeImageVersion=' + service_version])

    subprocess.run(args, check=True)

async def create_dns_zone(config, zone_name):
    args = [
        'az',
        'network',
        'private-dns',
        'zone',
        'create',
        '--subscription', config['subscription_id'],
        '--resource-group', config['resource_group'],
        '--name',  zone_name,
        '--output', 'none'
    ]

    await async_run_check(args)

async def create_dns_zone_records(config, zone_name, zone_suffix, records):

    for fqdns, ip_addr in records.items():

        name = fqdns.replace("." + zone_suffix, "")
        print('NAME: {0}'.format(name))

        args = [
            'az',
            'network',
            'private-dns',
            'record-set',
            'a',
            'add-record',
            '--subscription', config['subscription_id'],
            '--resource-group', config['resource_group'],
            '--zone-name',  zone_name,
            '--record-set-name', name,
            '-a', ip_addr,
            '--output', 'none'
        ]

        print('TASK:\t{0} A {1}'.format(name, ip_addr))
        await async_run_check(args)

async def delete_dns_zone(config, zone_name):
    args = [
        'az',
        'network',
        'private-dns',
        'zone',
        'delete',
        '--subscription', config['subscription_id'],
        '--resource-group', config['resource_group'],
        '--name', zone_name,
        '--yes'
    ]

    await async_run(args)

async def create_link_dns_zone(config, zone_name, link_name):
    args = [
        'az',
        'network',
        'private-dns',
        'link',
        'vnet',
        'create',
        '--subscription', config['subscription_id'],
        '--resource-group', config['resource_group'],
        '--registration-enabled', 'false',
        '--virtual-network', config['vnet_name'],
        '--zone-name', zone_name,
        '--name', link_name,
        '--output', 'none'
    ]

    await async_run_check(args)

async def delete_link_dns_zone(config, zone_name, link_name):
    args = [
        'az',
        'network',
        'private-dns',
        'link',
        'vnet',
        'delete',
        '--subscription', config['subscription_id'],
        '--resource-group', config['resource_group'],
        '--zone-name', zone_name,
        '--name', link_name,
        '--output', 'none',
        '--yes'
    ]

    await async_run_check(args)

async def create_private_endpoint(config, subnet_name, resource_id, group_id, endpt_name):

    args = [
        'az',
        'network',
        'private-endpoint',
        'create',
        '--name', endpt_name,
        '--subscription', config['subscription_id'],
        '--resource-group', config['resource_group'],
        '--location', config['location'],
        '--vnet-name', config['vnet_name'],
        '--subnet', subnet_name,
        '--private-connection-resource-id', resource_id,
        '--group-id', group_id,
        '--connection-name', endpt_name,
        '--output', 'json'
    ]

    completed, stdout_data = await async_run_check(args, stdout=subprocess.PIPE)
    output = json.loads(stdout_data.decode('ascii'))
    interface_id = output['networkInterfaces'][0]['id']

    # N.B. subscription/resource-group are implied by id.
    args = [
        'az',
        'network',
        'nic',
        'show',
        '--ids', interface_id,
        '--output', 'json'
    ]

    completed, stdout_data = await async_run_check(args, stdout=subprocess.PIPE)
    output = json.loads(stdout_data.decode('ascii'))
    records = {}
    for config in output['ipConfigurations']:
        if 'privateLinkConnectionProperties' in config:
            k = config['privateLinkConnectionProperties']['fqdns'][0]
            v = config['privateIpAddress']
            records[k] = v
    return records

async def delete_private_endpoint(config, endpt_name):

    args = [
        'az',
        'network',
        'private-endpoint',
        'delete',
        '--subscription', config['subscription_id'],
        '--resource-group', config['resource_group'],
        '--name', endpt_name,
        '--output', 'none'
    ]

    await async_run_check(args)

async def db_create_postgres(config, storage, sku, pgsub_id):

    args = [
        'az',
        'postgres',
        'flexible-server',
        'create',
        '--subscription', config['subscription_id'],
        '--resource-group', config['resource_group'],
        '--location', config['location'],
        '--name', config['db_name'],
        '--admin-user', 'osm',
        '--tier', 'GeneralPurpose',
        '--sku-name', sku,
        '--subnet', pgsub_id,
        '--private-dns-zone', config['db_dns_zone'],
        '--storage-size', str(storage),
        '--version', '13',
        '--tags', 'soundscapedb=true',
        '--output', 'json',
        '--only-show-errors'
    ]

    completed, stdout_data = await async_run_check(args, stdout=asyncio.subprocess.PIPE)
    output = json.loads(stdout_data.decode('ascii'))
    server_hostname = output['host']
    password = output['password']

    dsn2_template = 'host={host} port=5432 dbname=osm user={user} password={password}'
    dsn = dsn2_template.format(host=server_hostname,
                               user='osm',
                               password=password)
    proto = {
        'name': 'soundscape-database',
        'dsn2': dsn
    }

    args = [
        'az',
        'postgres',
        'flexible-server',
        'parameter',
        'set',
        '--subscription', config['subscription_id'],
        '--resource-group', config['resource_group'],
        '--server-name', config['db_name'],
        '--name', 'azure.extensions',
        '--value', 'postgis,hstore',
        '--output', 'none'
    ]

    await async_run_check(args)
    return proto

async def db_delete_postgres(config):

    args = [
        'az',
        'postgres',
        'flexible-server',
        'delete',
        '--subscription', config['subscription_id'],
        '--name', config['db_name'],
        '--resource-group', config['resource_group'],
        '--yes'
    ]

    await async_run_check(args)

async def db_create(config, pgsub_id):
    print('TASK:   create database: STARTED')
    start = time.perf_counter()

    def storage_size(n):
        for size in [32, 64, 128, 256, 512, 1024, 2048, 4096]:
            if size > n:
                return size
        return 0

    size = storage_size(config['parameters']['db_size'])
    db_sku = config['parameters']['db_sku']
    dbdesc = await db_create_postgres(config, size, db_sku, pgsub_id)
    end = time.perf_counter()
    print('TASK:   create database: DONE - took {0:.2f}s'.format(end-start))
    return dbdesc

def db_register(config, dbdesc):

    # NOTE: alter the draft database secret to reflect endpoint ip rather than the DNS address
    # refactor once SoundscapeDb() is moved into soundscape_provision

#    dbdesc['dsn2'] = re.sub(r"host=(\S*)",'host=' + ipAddr, dbdesc['dsn2'])
    kube = SoundscapeKube(None, config['namespace'])
    kube.connect()
    kube.register_database(dbdesc)

async def db_delete(config):
    print('TASK:   delete database: STARTED')
    await db_delete_postgres(config)
    print('TASK:   delete database: DONE')

def assign_pod_managed_identity_roles(config, node_resource_group, mi_pod):
    # add reader access for the identity to the resource-group containing
    # cluster innards

    args = [
        'az',
        'group',
        'show',
        '--subscription', config['subscription_id'],
        '--name', node_resource_group,
        '--output', 'json'
    ]

    completed = subprocess.run(args, check=True, stdout=subprocess.PIPE)
    output = json.loads(completed.stdout.decode('ascii'))
    node_resource_group_id = output['id']

    args = [
        'az',
        'role',
        'assignment',
        'create',
        '--subscription', config['subscription_id'],
        '--role', 'Reader',
        '--assignee', mi_pod['clientId'],
        '--scope', node_resource_group_id,
        '--output', 'none'
    ]

    subprocess.run(args, check=True, stderr=subprocess.DEVNULL)

def assign_cluster_managed_identity_roles(config, mi_cluster, nodesub_id):

    args = [
        'az',
        'role',
        'assignment',
        'create',
        '--subscription', config['subscription_id'],
        '--role', 'Network Contributor',
        '--assignee', mi_cluster['clientId'],
        '--scope', nodesub_id,
        '--output', 'none'
    ]

    subprocess.run(args, check=True, stderr=subprocess.DEVNULL)

def create_pod_identity(config, identity_name, mi_pod):

    args = [
        'az',
        'aks',
        'pod-identity',
        'add',
        '--subscription', config['subscription_id'],
        '--resource-group', config['resource_group'],
        '--cluster-name', config['cluster_name'],
        '--namespace', config['namespace'],
        '--name', identity_name,
        '--identity-resource-id', mi_pod['id'],
        '--output', 'none'
    ]
    subprocess.run(args, check=True)

async def create_managed_identity(config, mi_name):
    args = [
        'az',
        'identity',
        'create',
        '--subscription', config['subscription_id'],
        '--resource-group', config['resource_group'],
        '--location', config['location'],
        '--name', mi_name,
       '--output', 'json'
    ]

    completed, stdout_data = await async_run_check(args, stdout=asyncio.subprocess.PIPE)
    output = json.loads(stdout_data.decode('ascii'))
    return {
        'id': output['id'],
        'clientId': output['clientId']
    }

def delete_managed_identity(config, mi_name):
    args = [
        'az',
        'identity',
        'delete',
        '--subscription', config['subscription_id'],
        '--resource-group', config['resource_group'],
        '--name', mi_name,
    ]

    subprocess.run(args, check=True)

def get_cluster_node_resource_group(config):
    args = [
        'az',
        'aks',
        'show',
        '--subscription', config['subscription_id'],
        '--resource-group', config['resource_group'],
        '--name', config['cluster_name'],
        '--query', 'nodeResourceGroup',
        '-o', 'tsv'
    ]

    completed = subprocess.run(args, check=True, stdout=subprocess.PIPE)
    return completed.stdout.decode('ascii').strip()

# N.B. implementable via API
def create_static_public_ip_for_ingress(config, node_resource_group):
    args = [
        'az',
        'network',
        'public-ip',
        'create',
        '--allocation-method', 'static',
        '--sku', 'Standard',
        '--subscription', config['subscription_id'],
        '--resource-group', node_resource_group,
        '--name', config['ip_name']
    ]

    completed = subprocess.run(args, check=True, stdout=subprocess.PIPE)
    output = json.loads(completed.stdout.decode('ascii'))

    return output['publicIp']['ipAddress']

# N.B. implementable via API

def fetch_file(account_name, container_name, file, file_dest):
    args = [
        'az',
        'storage',
        'blob',
        'download',
        '--auth-mode', 'key',
        '--account-name', account_name,
        '--container-name', container_name,
        '--name', file,
        '-f', file_dest,
        '--output', 'none'
    ]
    subprocess.run(args, check=True)

def fetch_azsecpak_template():
    fetch_file('soundscapesecrets', 'azsecpak', 'azsecpak_mi.yaml', 'soundscape/templates/azsecpak.yaml')

def fetch_service_versions(config, container_registry):
    args = [
        'az',
        'acr',
        'repository',
        'show-tags',
        '--name', container_registry,
        '--subscription', config['infra']['subscription_id'],
        '--repository', 'soundscape/ingest',
        '--orderby', 'time_desc',
        '--output', 'json'
    ]
    try:
        completed = subprocess.run(args, check=True, stdout=subprocess.PIPE)
        output = json.loads(completed.stdout.decode('ascii'))
    except:
        output = []

    return output

def filter_service_version_for_branch(versions, branch):
    ref_branch_name = 'refs_heads_' + branch.replace('/', '_')
    matching_versions = list(filter(lambda x: x.startswith(ref_branch_name + '_'), versions))

    return matching_versions

def fetch_current_branch():
    args = [
        'git',
        'symbolic-ref',
        '--short',
        'HEAD'
    ]
    completed = subprocess.run(args, check=True, stdout=subprocess.PIPE)
    output = completed.stdout.decode('ascii').strip()
    return output

async def delete_link_zone_endpoint(config, link, zone, endpt):
    print('TASK: delete link to zone {0}: STARTED'.format(zone))
    await delete_link_dns_zone(config, zone, link)
    print('TASK: delete link to zone {0}: DONE'.format(zone))

    print('TASK: delete private dns zone {0}: STARTED'.format(zone))
    await delete_dns_zone(config, zone)
    print('TASK: delete private dns zone {0}: DONE'.format(zone))

    if endpt:
        print('TASK: delete endpoint {0}: STARTED'.format(endpt))
        await delete_private_endpoint(config, endpt)
        print('TASK: delete endpoint {0}: DONE'.format(endpt))

async def delete_network_async(config):
    print('TASK: delete {link, dns_zone, endpoint} for {postgres, keyvault, acr}: STARTED')
    await asyncio.gather(
        delete_link_zone_endpoint(config, config['db_dns_zone_link'], config['db_dns_zone'], None),
        delete_link_zone_endpoint(config, config['kv_dns_zone_link'], config['kv_dns_zone'], config['kv_endpt']),
        delete_link_zone_endpoint(config, config['cr_dns_zone_link'], config['cr_dns_zone'], config['cr_endpt']),
    )
    print('TASK: delete {link, dns_zone, endpoint} for {postgres, keyvault, acr}: DONE')

def delete_network(config):
    asyncio.run(delete_network_async(config))

    print('TASK: delete vnet: STARTED')
    delete_vnet(config)
    print('TASK: delete vnet: DONE')

def deprovision(config):
    location = config['res_client'].resource_groups.get(args.resource_group).location

    if not config['delete_yes']:
        confirm = input('Are you sure you want to do this.  Enter \'{0}\' to confirm: '.format(config['name']))
        if confirm != config['name']:
            print('Aborting delete')
            exit(1)

    print('TASK: delete resources in parallel: STARTED')
    delete_resources(config)
    print('TASK: delete resources in parallel: DONE')

    print('TASK: delete network resources in parallel: STARTED')
    delete_network(config)
    print('TASK: delete network resources in parallel: DONE')

    print('TASK: delete pod managed identity: STARTED')
    delete_managed_identity(config, config['mi_podname'])
    print('TASK: delete pod managed identity: DONE')

    print('TASK: delete cluster managed identity: STARTED')
    delete_managed_identity(config, config['mi_clustername'])
    print('TASK: delete cluster managed identity: DONE')

    print('TASK: resource group \'{0}\' in \'{1}\' was NOT deleted in case it included unrelated resources'.format(config['resource_group'], location))

def check_azure_credentials(subscription_id, delete_task):
    args = [
        'az',
        'account',
        'list-locations',
        '--output', 'none'
    ]
    completed = subprocess.run(args)
    if completed.returncode != 0:
        print('TASK: Credentials likely expired, invoking \'az login\'')
        args = [
            'az',
            'login',
            '--output', 'none'
        ]
        subprocess.run(args, check=True)

    args = [
        'az',
        'ad',
        'signed-in-user',
        'show',
        '--output', 'json'
    ]
    completed = subprocess.run(args, check=True, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL)
    output = json.loads(completed.stdout.decode('ascii'))
    user = output['userPrincipalName']

    args = [
        'az',
        'role',
        'assignment',
        'list',
        '--subscription', subscription_id,
        '--assignee', user,
        '--output', 'json'
    ]
    completed = subprocess.run(args, check=True, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL)
    output = json.loads(completed.stdout.decode('ascii'))

    for r in output:
        if r['roleDefinitionName'] == 'Owner':
            print('TASK: Validated running as \'Owner\' role')
            return

    print('ERROR: User not running as \'Owner\' role')
    exit(1)


def check_azure_feature(subscription_id, name, namespace):
    args = [
        'az',
        'feature',
        'show',
        '--subscription', subscription_id,
        '--name', name,
        '--namespace', namespace,
        '--output', 'json'
    ]

    try:
        completed = subprocess.run(args, check=True, stdout=subprocess.PIPE)
        output = json.loads(completed.stdout.decode('ascii'))
        registered = output['properties']['state'] == 'Registered'
    except Exception:
        registered = False

    if not registered:
        print('ERROR: Required azure feature \'{0}/{1}\' not enabled'.format(namespace, name))
        exit(1)

def check_azure_provider(subscription_id, provider):
    args = [
        'az',
        'provider',
        'show',
        '--subscription', subscription_id,
        '--namespace', provider,
        '--output', 'json'
    ]

    try:
        completed = subprocess.run(args, check=True, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL)
        output = json.loads(completed.stdout.decode('ascii'))
        registered = output['registrationState'] == 'Registered'
    except Exception:
        registered = False

    if not registered:
        print('ERROR: Required azure provider \'{0}\' not enabled'.format(provider))
        exit(1)

def check_azure_extension(extension, version):
    args = [
        'az',
        'extension',
        'show',
        '--name', extension,
        '--output', 'json'
    ]

    completed = subprocess.run(args, check=True, stdout=subprocess.PIPE)
    output = json.loads(completed.stdout.decode('ascii'))
    if semver.compare(output['version'], version) < 0:
        print('ERROR: Required azure extension \'{0}\' needs to be of version {1} or better'.format(extension, version))
        exit(1)

def check_azure_version(version):
    args = [
        'az',
        'version',
        '--output', 'json'
    ]

    completed = subprocess.run(args, check=True, stdout=subprocess.PIPE)
    output = json.loads(completed.stdout.decode('ascii'))

    if semver.compare(output['azure-cli'], version) < 0:
        print('ERROR: Required azure CLI needs to be of version {0} or better'.format(version))
        exit(1)

def check_azure_configuration(subscription_id, delete_task):

    required_features = {
        'EnablePodIdentityPreview': 'Microsoft.ContainerService',
        'PodSubnetPreview': 'Microsoft.ContainerService',
    }

    required_extensions = {
        'aks-preview': '0.5.55'
    }

    required_providers = [
        'Microsoft.Compute',
        'Microsoft.OperationsManagement',
        'Microsoft.PolicyInsights',
        'Microsoft.Capacity',
        'Microsoft.Insights',
    ]

    check_azure_version('2.33.1')

    for name, namespace in required_features.items():
        check_azure_feature(subscription_id, name, namespace)

    for ext, version in required_extensions.items():
        check_azure_extension(ext, version)

    for provider in required_providers:
        check_azure_provider(subscription_id, provider)

def select_subscription(subscription):
    if subscription != None:
        return subscription

    args = [
        'az',
        'account',
        'list',
        '--output', 'json'
    ]
    completed = subprocess.run(args, check=True, stdout=subprocess.PIPE)
    output = json.loads(completed.stdout.decode('ascii'))
    for s in output:
        if s['isDefault'] == True:
            return s['id'];
    print('ERROR: --subscription not specified and no default')
    exit(1)

def determine_service_version(config, container_registry, require_specified):

    if config['specified_service_version']:
        return config['specified_service_version']

    if require_specified:
        print('ERROR: --service-version must be specified')
        exit(1)

    versions = fetch_service_versions(config, container_registry)
    branch = fetch_current_branch()
    matching_versions = filter_service_version_for_branch(versions, branch)

    if len(matching_versions) > 0:
        return matching_versions[0]
    else:
        print('ERROR: Unable to find service version that matches this branch')
        exit(1)

def get_subscription_tenant(config):
    args = [
        'az',
        'account',
        'show',
        '--subscription', config['subscription_id'],
        '--output', 'json'
    ]

    completed = subprocess.run(args, check=True, stdout=subprocess.PIPE)
    output = json.loads(completed.stdout.decode('ascii'))

    return output['tenantId']

def get_keyvault_id(config):
    args = [
        'az',
        'keyvault',
        'show',
        '--subscription', config['infra']['subscription_id'],
        '--resource-group', config['infra']['resource_group'],
        '--name', config['infra']['keyvault_name'],
        '--output', 'json'
    ]

    completed = subprocess.run(args, check=True, stdout=subprocess.PIPE)
    output = json.loads(completed.stdout.decode('ascii'))

    return output['id']

def update_helm_chart(config):
    if config['install_azsecpak']:
        print('TASK: fetching azsecpak template: STARTED')
        fetch_azsecpak_template()
        print('TASK: fetching azsecpak template: DONE')

def create_resource_group_if_necessary(config, resource_group):
    if config['res_client'].resource_groups.check_existence(resource_group):
        print('TASK: Resource group \'{0}\' already exists'.format(resource_group))
        # N.B. overrides location with specified rather than resource group
        location = config['location']
    else:
        resource_group_params = {'location': config['location']}
        config['res_client'].resource_groups.create_or_update(resource_group, resource_group_params)
        print('TASK: Created Resource group \'{0}\' in \'{1}\''.format(resource_group,
                                                                       config['location']))
        location = config['res_client'].resource_groups.get(resource_group).location
    return location

def helm_release_container_registry(config):

    args = [
        'helm',
        'get',
        'values',
        '--namespace', config['namespace'],
        'soundscape-service',
        '--output', 'json'
    ]
    completed = subprocess.run(args, check=True, stdout=subprocess.PIPE)
    output = json.loads(completed.stdout.decode('ascii'))
    (container_registry,_,_) =  output['containerRegistry'].partition('.')
    return container_registry


async def create_resources_async(config, mi_cluster, podsub_id, nodesub_id, container_registry_id, pgsub_id):

    return await asyncio.gather(
        create_kubernetes_cluster(config, config['location'], mi_cluster, podsub_id, nodesub_id, container_registry_id),
        db_create(config, pgsub_id)
    )

def create_resources(config, mi_cluster, podsub_id, nodesub_id, container_registry_id, pgsub_id):
    _, database_desc = asyncio.run(create_resources_async(config, mi_cluster, podsub_id, nodesub_id, container_registry_id, pgsub_id))
    return database_desc


async def delete_resources_async(config):
    await asyncio.gather(
        delete_kubernetes_cluster(config),
        db_delete(config)
    )

def delete_resources(config):
    asyncio.run(delete_resources_async(config))

# OPEN: storage accounts., container registries, keyvault, location
def upgrade_service(config):

    print('TASK: get kubernetes credentials: STARTED')
    get_aks_credentials(config)
    print('TASK: get kubernetes credentials: DONE')

    print('TASK: get container registry of current release: STARTED')
    container_registry = helm_release_container_registry(config)
    print('TASK: get container registry of current release: DONE')

    service_version = determine_service_version(config, container_registry, True)
    print('TASK: Service version \'{0}\''.format(service_version))

    update_helm_chart(config)

    print('TASK: upgrade service: STARTED')
    service_upgrade(config, service_version)
    print('TASK: upgrade service: DONE')

async def create_identities(config):
    print('TASK: create {cluster, pod} managed identity: STARTED')

    mi_cluster, mi_pod = await asyncio.gather(
        create_managed_identity(config, config['mi_clustername']),
        create_managed_identity(config, config['mi_podname']),
    )
    print('TASK: create {cluster,pod} managed identity: DONE')

    print('TASK: allow pod mi to retrieve certs from key vault: STARTED')
    await allow_pod_mi_to_access_keyvault_certificates(config, mi_pod)
    print('TASK: allow pod mi to retrieve certs from key vault: DONE')

    return mi_cluster, mi_pod

async def create_network_db(config):

    print('TASK: create private dns zone for postgres: STARTED')
    await create_dns_zone(config, config['db_dns_zone'])
    print('TASK: create private dns zone for postgres: DONE')

async def create_network_kv(config):

    print('TASK: get keyvault access info: STARTED')
    keyvault_id = get_keyvault_id(config)
    print('TASK: get keyvault access info: DONE')

    await create_network_endpoint(config,
                                  'keyvault',
                                  keyvault_id,
                                  config['kv_dns_zone'],
                                  config['kv_dns_suffix'],
                                  config['kv_dns_zone_link'],
                                  'vault',
                                  config['kv_endpt'],
                                  config['snets']['cmn_snet']['name'],
                                  config['infra']['keyvault_name'])

async def create_network_acr(config, container_registry):

    print('TASK: get container registry docker access info: STARTED')
    container_registry_login, container_registry_id = get_container_registry_info(config, container_registry)
    print('TASK: get container registry docker access info: DONE')

    await create_network_endpoint(config,
                                  'acr',
                                  container_registry_id,
                                  config['cr_dns_zone'],
                                  config['cr_dns_suffix'],
                                  config['cr_dns_zone_link'],
                                  'registry',
                                  config['cr_endpt'],
#new or see if can be shared
                                  config['snets']['cmn_snet']['name'],
                                  container_registry)

    return container_registry_login, container_registry_id

async def create_network_endpoint(config, resource_name, resource_id, zone, zone_suffix, link_name, endpt_type, endpt_name, subnet, dns_name):

    print('TASK: create private dns zone for {0}: STARTED'.format(resource_name))
    await create_dns_zone(config, zone)
    print('TASK: create private dns zone for {0}: DONE'.format(resource_name))

    print('TASK: link private dns zone for {0} to vnet: STARTED'.format(resource_name))
    await create_link_dns_zone(config, zone, link_name)
    print('TASK: link private dns zone for {0} to vnet: DONE'.format(resource_name))

    print('TASK: create {0} private endpoint: STARTED'.format(resource_name))
    records = await create_private_endpoint(config, subnet, resource_id, endpt_type, endpt_name)
    print('TASK: create {0} private endpoint: DONE'.format(resource_name))

    print('TASK: create endpoint dns record in {0} dns zone: STARTED'.format(resource_name))

    await create_dns_zone_records(config,
                                  zone,
                                  zone_suffix,
                                  records)
    print('TASK: create endpoint dns record in {0} dns zone: DONE'.format(resource_name))

async def create_network(config, container_registry):

    print('TASK: create virtual network and subnets: STARTED')
    subnet_ids = await create_vnet(config)
    print('TASK: create virtual network and subnets: DONE')

    result = await asyncio.gather(
        create_network_db(config),
        create_network_kv(config),
        create_network_acr(config, container_registry),
    )

    _, _, (container_registry_login, container_registry_id) = result;

    return container_registry_login, container_registry_id, subnet_ids

async def setup_environment_async(config, container_registry):
    return await asyncio.gather(
        create_identities(config),
        create_network(config, container_registry),
    )

def setup_environment(config, container_registry):
    ident, net = asyncio.run(setup_environment_async(config, container_registry))
    return ident, net

def provision_service(config):

    create_resource_group_if_necessary(config, config['resource_group'])

    if config['production']:
        container_registry = config['infra']['container_registry_release']
    else:
        container_registry = config['infra']['container_registry']

    service_version = determine_service_version(config, container_registry, True)
    print('TASK: Service version \'{0}\''.format(service_version))

    print('TASK: Determine tenant: STARTED')
    tenant = get_subscription_tenant(config)
    print('TASK: Determine tenant: DONE')

    print('TASK: check kubernetes cluster name free: STARTED')
    check_kubernetes_cluster_name(config, config['location'])
    print('TASK: check kubernetes cluster name free: DONE')

    update_helm_chart(config)

    print('TASK: setup environment: STARTED')
    (mi_cluster, mi_pod), (container_registry_login, container_registry_id, subnet_ids) = setup_environment(config, container_registry)
    print('TASK: setup environment: DONE')

    print('TASK: assign roles to cluster managed identity: STARTED')
    assign_cluster_managed_identity_roles(config, mi_cluster, subnet_ids['node_snet'])
    print('TASK: assign roles to cluster managed identity: DONE')

    print('TASK: create resources in parallel: STARTED')
    database_desc = create_resources(config, mi_cluster, subnet_ids['pod_snet'], subnet_ids['node_snet'], container_registry_id, subnet_ids['pg_snet'])
    print('TASK: create resources in parallel: DONE')
    node_resource_group = get_cluster_node_resource_group(config)

    print('TASK: assign roles to pod managed identity: STARTED')
    assign_pod_managed_identity_roles(config, node_resource_group, mi_pod)
    print('TASK: assign roles to pod managed identity: DONE')

    print('TASK: create aad pod identity: STARTED')
    create_pod_identity(config, 'soundscape-identity', mi_pod)
    print('TASK: create aad pod identity DONE')

    print('TASK: create public ip for ingress: STARTED')
    ip_address = create_static_public_ip_for_ingress(config, node_resource_group)
    print('TASK: create public ip for ingress: DONE')

    print('TASK: get kubernetes credentials: STARTED')
    get_aks_credentials(config)
    print('TASK: get kubernetes credentials: DONE')

    print('TASK: initialize HELM: STARTED')
    helm_init(config)
    print('TASK: initialize HELM: DONE')

    print('TASK: register database with service: STARTED')
    db_register(config, database_desc)
    print('TASK: register database with service: DONE')

    print('TASK: service install: STARTED')
    service_install(config, container_registry_login, service_version, tenant)
    print('TASK: service install: DONE')

    print('TASK: check secrets availability: STARTED')
    check_for_secret(config, 'your_secret')
    print('TASK: check secrets availability: DONE')

    print('TASK: nginx install into cluster: STARTED')
    nginx_ingress_install(config, 'soundscape-ingress', ip_address, 'soundscape-identity')
    print('TASK: nginx install into cluster: DONE')

    if config['parameters'].get('stress', False):
        print('TASK: stress install: STARTED')
        stress_install(config, container_registry_login, service_version)
        print('TASK: stress install: DONE')

    print('SERVICE DNS: {0}.{1}'.format(config['dns_name'], config['location'] + '.cloudapp.azure.com'))
    print('SERVICE PROVISION: complete')

def dispatch(config):

    if config['action'] == 'delete':
        deprovision(config);
    elif config['action'] == 'upgrade':
        upgrade_service(config)
    else:
        provision_service(config)

parser = argparse.ArgumentParser(description='Soundscape Service Provisioner')
parser.add_argument('--subscription', type=str, default=None)
parser.add_argument('--resource-group', type=str, required=True)
parser.add_argument('--name', type=str, required=True)
parser.add_argument('--location', type=str, default=None)
parser.add_argument('--namespace', type=str, default='soundscape')
parser.add_argument('--scale', type=str, choices=scale_parameters.keys(), default='test')
parser.add_argument('--kubernetes-version', type=str, default=None)
parser.add_argument('--service-version', type=str, default=None)
parser.add_argument('--delete', action='store_true')
parser.add_argument('--upgrade', action='store_true')
parser.add_argument('--yes', action='store_true')

args = parser.parse_args()

credential = DefaultAzureCredential(exclude_interactive_browser=False)
subscription_id = select_subscription(args.subscription)

check_azure_credentials(subscription_id, args.delete)
check_azure_configuration(subscription_id, args.delete)

if not args.name.startswith('soundscape-'):
    print('name must start with \'soundscape-\'')
    exit(1)

if args.delete and args.upgrade:
    print('ERROR: --delete and --upgrade are mutually exclusive operations')
    exit(1)

if args.delete:
    action = 'delete'
elif args.upgrade:
    action = 'upgrade'
else:
    action = 'install'

config = {
    'infra': subscriptions[subscription_id],
    'action' : action,
    'name'   : args.name,
    'subscription_id' : subscription_id,
    'resource_group' : args.resource_group,
    'location': args.location if args.location else subscriptions[subscription_id]['default_location'],
    'cluster_name': args.name + '-aks',
    'mi_podname' : args.name + '-mipod',
    'mi_clustername' : args.name + '-micluster',
    'db_name' : args.name + '-db',
    'db_dns_zone' : args.name + '-db' + '.privatelink.postgres.database.azure.com',
    'db_dns_zone_link' : args.name + '-vnet-link',

    'kv_dns_zone' : 'privatelink.vaultcore.azure.net',
    'kv_dns_suffix': 'vault.azure.net',
    'kv_dns_zone_link' : args.name + '-kv-link',
    'kv_endpt' : args.name + '-kv-endpt',

    'cr_dns_zone' : 'privatelink.azurecr.io',
    'cr_dns_suffix': 'azurecr.io',
    'cr_dns_zone_link' : args.name + '-cr-link',
    'cr_endpt' : args.name + '-cr-endpt',

    'ip_name' : args.name + '-ip',
    'vnet_name' : args.name + '-vnet',

    'snets': {
        'pod_snet': {
            'name': args.name + '-vnet' + '-podsnet',
        },
        'node_snet': {
            'name': args.name + '-vnet' + '-nodesnet',
        },
        'cmn_snet': {
            'name': args.name + '-vnet' + '-cmnsnet',
            'disable_network_policy': True,
        },
        'pg_snet': {
            'name': args.name + '-vnet' + '-pgsnet',
            'configure_postgres': True,
        }
    },

    'dns_name' : (args.name + '-aks-' + args.resource_group).lower(),
    'parameters' : scale_parameters[args.scale],
    'kubernetes_version' : args.kubernetes_version,
    'namespace': args.namespace,
    'res_client' : ResourceManagementClient(credential, subscription_id=subscription_id),
    'acr_client' : ContainerRegistryManagementClient(credential, subscription_id=subscriptions[subscription_id]['subscription_id']),
    'auth_client' : AuthorizationManagementClient(credential, subscription_id=subscription_id),
    'rbac_client' : GraphRbacManagementClient(credential, tenant_id=subscription_id),
    'delete_yes' : args.delete and args.yes,
    'production' : args.scale.startswith('production'),
    'specified_service_version': args.service_version,
    'install_azsecpak': False,
}

dispatch(config)
exit(0)
