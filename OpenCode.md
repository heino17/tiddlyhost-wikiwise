# OpenCode.md

This file provides guidance to OpenCode when working with code in this repository.

## About Tiddlyhost-wikiwise

Tiddlyhost-wikiwise (this repository) is a fork of [Tiddlyhost](https://tiddlyhost.com/), a hosting service for TiddlyWiki. The upstream source code lives in the [tiddlyhost/tiddlyhost-com](https://github.com/tiddlyhost/tiddlyhost-com) repository.

The fork adds, among other things:

- Rails I18n language support (see `Readme_i18n.md`)
- Comments and voting for wikis/sites (see `Readme_Comments_and_voting.md`)
- A shoutbox mini-chat widget (see `Readme_Shoutbox.md`)
- An extended admin area (see `Readme-Admin-tab.md`)
- Expanded user management (see `Readme-User-Management.md`)
- Guest login for every wiki (see `Readme_Collaborator_Login.md`)
- SimpleWiki hosting for lightweight data-island wikis
- A dedicated legal notice (imprint) page, toggleable in the admin area

As well as TiddlyWiki, the following "TiddlyWiki-like" single-page wikis can also be created and hosted on Tiddlyhost-wikiwise:

- TiddlyWiki Classic (legacy)
- FeatherWiki
- Siteleteer
- SimpleWiki

## Development Environment

Tiddlyhost-wikiwise is a Ruby on Rails application that hosts TiddlyWiki and SimpleWiki sites with Docker-based development. The project structure includes:

- `rails/` - Main Rails application
- `docker/` - Docker configuration and volumes
- `ansible/` - Deployment automation and Jinja templates for generated configs
- `bin/` - Utility scripts
- `deploy/` - End-user Docker installation and update scripts

## Common Development Commands

### Building and Setup
```bash
# Build the development Docker image
make build-base

# Initialize Rails (sets up database, installs gems)
make rails-init

# Start the full development stack with SSL
make start
```

### Testing and Quality
```bash
# Run the full test suite
make test
# Or alternatively:
make run-tests

# Run a single test file
make onetest TEST=test/models/site_test.rb

# Run linting
make delint

# This runs both:
make haml-lint-with-todo  # HAML linting
make rubocop              # Ruby linting
```

### Development Tools
```bash
# Shell into running container
make join

# Rails console
make console

# Database migration
make db-migrate

# Clear logs and temp files
make log-clear
make tmp-clear

# Refresh the bundled SimpleWiki shell
make simple-update
```

### Bundle and Dependencies
```bash
# Install Ruby gems
make bundle-install

# Update gems
make bundle-update

# Install JavaScript packages
make yarn-install

# Update JavaScript packages
make yarn-upgrade
```

## Architecture Overview

### Core Models and Domain Classes
- `Site` - TiddlyWiki and SimpleWiki sites with version history
- `SimpleData` - Current JSON content island of a SimpleWiki site
- `SimpleDataVersion` - Versioned SimpleWiki content snapshots
- `SimplewikiShell` - Bundled SimpleWiki shell handling and upgrades
- `User` - User accounts with Devise authentication
- `Empty` - Template sites (TiddlyWiki, Feather Wiki, SimpleWiki, etc.)
- `Comment`, `SiteVote`, `ShoutboxMessage` - Community features added by the fork
- `WikiCollaborator` - Guest/collaborator access to a site
- `Setting` - Runtime feature flags and values editable in the admin area

### Key Controllers
- `TiddlywikiController` - Serves and saves TiddlyWiki sites
- `SimplewikiController` - Serves the SimpleWiki content-island API (`/simplewiki/status`, `/simplewiki/data`, `/simplewiki/shell/update`)
- `SitesController` - Site management (CRUD, history, downloads)
- `HubController` + variants - Browse/explore public sites
- `AdminController` - Extended admin area (settings, users, storage, comments)
- `SiteSessionsController` - Guest/collaborator login on site hosts
- `CommentsController`, `SiteVotesController`, `ShoutboxMessagesController` - Community features added by the fork

### Routing Architecture
The app uses domain-based routing constraints from `rails/config/settings.yml`:
- `Settings.main_site_host` (default in development: `tiddlyhost.local`) - Main application interface
- `subdomain.<main_site_host>` - Individual TiddlyWiki and SimpleWiki sites
- Legacy Tiddlyspot routes are disabled unless legacy storage credentials are configured; they are not part of the normal fork setup

### File Storage
- Uses Active Storage for file attachments and site content
- Multiple storage services: `local1`, `local2`, `thumbs2`, etc.
- TiddlyWiki site content is stored as compressed HTML blobs with version history
- For SimpleWiki, the shell is stored as the site's content blob while the pages live as JSON in `SimpleData`, with snapshots in `SimpleDataVersion`
- Thumbnails are generated via background jobs

## Configuration

### Settings
Settings are managed through `rails/config/settings.yml` and can be overridden by `settings_local.yml`. Key settings include:
- Host configuration for multi-domain setup
- Feature flags (e.g., comments, votes, shoutbox, registration, imprint page)
- Storage service mappings
- Subscription plan details

### Generated Configuration
Some files under `docker/` are generated from the Jinja templates in `ansible/playbooks/templates/docker/` and are gitignored:
- `docker/nginx-conf/nginx.conf` - Production nginx config
- `docker/nginx-conf/nginx.dev.conf` - Development nginx config (HTTP-to-HTTPS redirect includes port 7443)
- `docker/nginx-conf/server-common.conf` - Shared nginx proxy configuration
- `docker/config/settings_local.yml` - Local settings for the production compose stack

Regenerate them with:

```bash
make local-config
```

### Secrets
Encrypted secrets are managed via Rails credentials:
```bash
# View/edit secrets
make secrets
```

### Docker Development
The development environment runs in Docker containers managed using `docker compose`:
- `app` - Rails application
- `db` - PostgreSQL database
- `web` - nginx reverse proxy with SSL
- `jobs` - Rails background jobs
- `cache` - Memcached

The development stack publishes:
- HTTP on port `8034`, which redirects to HTTPS
- HTTPS on port `7443`, so the app is reached at `https://tiddlyhost.local:7443/`

Because the HTTPS port is not 443, the development settings in `rails/config/settings.yml` set `:port: 7443` for in-container requests, and nginx forwards `Host $http_host` so Rails keeps the port in generated URLs.

The development stack mounts `docker/nginx-conf/nginx.dev.conf`. The production stack (`docker-compose-prod.yml`) mounts `docker/nginx-conf/nginx.conf` and `docker/config/settings_local.yml`.

Use explicit entries in `/etc/hosts` for subdomain testing (wildcards are not supported there):
```
127.0.0.1 tiddlyhost.local
127.0.0.1 aaa.tiddlyhost.local
127.0.0.1 bbb.tiddlyhost.local
```

After changing a template, regenerate the configs and recreate the affected containers:

```bash
make local-config
docker compose up -d --force-recreate app jobs web
```

## Background Jobs

Uses Delayed Job for:
- Thumbnail generation (`GenerateThumbnailJob`)
- Attachment cleanup (`PruneAttachmentsJob`)

## Important Notes

- TiddlyWiki content is stored as compressed HTML files in Active Storage blobs
- The app supports multiple TiddlyWiki versions via "empties" (templates)
- Save history allows users to view/restore previous versions
- SimpleWiki keeps its pages in a JSON content island, separate from the shell, so the shell can be updated without touching the content
- SimpleWiki shell updates are restricted to owner and superuser; collaborators can edit pages but must not replace the shell
- Subscription management via Stripe integration
- All changed admin settings take effect immediately without requiring a restart
