# Forgejo Server

this is my setup for a Forgejo instance running on docker compose with a Traefik proxy.

## Backups

Backups are done using [restic](https://restic.net/) and stored in a Scaleway Object Storage bucket.

### Initialization

Make sure to install restic on the forgejo host machine:

```bash
# Debian
apt-get install restic
```

Initialize the bucket (only needed once):

```bash
# create a restic.env file with the following variables
export RESTIC_REPOSITORY="s3:https://my-bucket.s3.fr-par.scw.cloud/my-bucket"
export AWS_ACCESS_KEY_ID="secret"
export AWS_SECRET_ACCESS_KEY="secret"
export RESTIC_PASSWORD="secret" # will be used to encrypt the backups, save it somewhere safe
```

Set up a CRON job to run restic:

```bash
crontab -e

# daily backup at 3am
0 3 * * * /opt/apps/forgejo-server/backup.sh >> /opt/apps/forgejo-server/backup.log 2>&1
```

### Restore

> The password used to encrypt the backups is saved in my password manager.

Make sure the `restic.env` file with the environment variables exists as described above.
Running the restore script will stop the container, make a backup of the current data folder, restore the latest backup from restic and start the container again.

```bash
chmod +x /opt/apps/forgejo-server/restore.sh
/opt/apps/forgejo-server/restore.sh
```

## Runner Installation

### Set up a runner on another VM/VPS

1. spin up a new ubuntu machine and install docker
1. Follow the "binary installation" guide from the [Forgejo Docs](https://forgejo.org/docs/latest/admin/actions/runner-installation/#downloading-and-installing-the-binary)
   - make sure to replace the architecture with `arm64` if applicable
   - you might have to remove the brackets from the ${RUNNER_VERSION} variables
1. Modify the config to use Docker from the host as described in the [docs](https://forgejo.org/docs/latest/admin/actions/runner-installation/#configuration)
   1. `forgejo-runner generate-config > config.yml`
   1. edit `config.yml`, set `container.docker_host = "automount"`
   1. move the `config.yml` to `/etc/forgejo-runner/config.yml`
1. Create and start a systemd service for the runner as explained in the [Forgejo Docs](https://forgejo.org/docs/latest/admin/actions/runner-installation/#running-as-a-systemd-service) and modify the start command by adding `--config /etc/forgejo-runner/config.yml`
