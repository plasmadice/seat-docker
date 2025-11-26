![SeAT](https://i.imgur.com/aPPOxSK.png)

# seat-docker

## This repository contains the SeAT Docker Setup

Please use the main SeAT repository [here](https://github.com/eveseat/seat) for issues.

## Quick Start

The default `docker-compose.yml` file is configured to work with **Cloudflare Tunnels** and can be easily deployed using **Portainer GitOps** or locally with Docker Compose.

### Prerequisites

1. **Cloudflare Account** with a domain
2. **Docker** and **Docker Compose** installed (for local deployment)
3. **Portainer** (optional, for GitOps deployment)

### Deployment Steps

#### Step 1: Create Cloudflare Tunnel

1. Go to [Cloudflare Dashboard](https://dash.cloudflare.com/)
2. Navigate to **Zero Trust** → **Networks** → **Tunnels**
3. Click **Create a tunnel**
4. Select **Cloudflared** as the connector
5. Give your tunnel a name (e.g., `seat-tunnel`)
6. Copy the **Tunnel Token** (you'll need this for `CLOUDFLARE_TUNNEL_TOKEN`)

#### Step 2: Configure DNS Subdomain

1. In the Cloudflare Dashboard, go to your domain's **DNS** settings
2. Create a new **A record** or **CNAME record**:
   - **Type**: CNAME (recommended) or A
   - **Name**: `seat` (or your preferred subdomain)
   - **Target**: `100.64.0.1` (for CNAME) or your tunnel's IP
   - **Proxy status**: Proxied (orange cloud) ✅

**Example**: If your domain is `example.com`, create `seat.example.com`

#### Step 3: Configure Tunnel Routing

1. Go back to **Zero Trust** → **Networks** → **Tunnels**
2. Click on your tunnel → **Configure**
3. Go to **Public Hostnames** tab
4. Click **Add a public hostname**
5. Configure:
   - **Subdomain**: `seat` (or your chosen subdomain)
   - **Domain**: Select your domain (e.g., `example.com`)
   - **Service**: `http://front:8080`
   - **Path**: (leave empty for root)
6. Click **Save hostname**

#### Step 4: Configure Environment Variables

Copy `.env.example` to `.env` and configure the required variables:

```bash
cp .env.example .env
```

**Required variables:**
- `CLOUDFLARE_TUNNEL_TOKEN` - Your tunnel token from Step 1
- `SEAT_DOMAIN` - Your subdomain (e.g., `seat.example.com`)
- `APP_URL` - Full URL with protocol (e.g., `https://seat.example.com`)
- `DB_PASSWORD` - Database password (generate a secure one)
- `APP_KEY` - Application encryption key (generate using `openssl rand -base64 32 | tr -d "=+/" | cut -c1-32`)
- `EVE_CLIENT_ID` - EVE Online SSO Client ID
- `EVE_CLIENT_SECRET` - EVE Online SSO Client Secret

See `.env.example` for all available options.

#### Step 5: Deploy

**Option A: Local Deployment**
```bash
docker compose up -d
```

**Option B: Portainer GitOps Deployment**

1. In Portainer, go to **Stacks** → **Add stack**
2. Select **Repository** method
3. Configure:
   - **Repository URL**: Your Git repository URL
   - **Compose path**: `docker-compose.yml`
   - **Reference**: `main` (or your branch)
4. Add environment variables:
   - Click **Environment variables**
   - Add all variables from your `.env` file (Portainer doesn't read `.env` files directly)
   - **Important**: Set `CLOUDFLARE_TUNNEL_TOKEN`, `SEAT_DOMAIN`, `APP_URL`, `DB_PASSWORD`, `APP_KEY`, `EVE_CLIENT_ID`, and `EVE_CLIENT_SECRET`
5. Click **Deploy the stack**

**Note for Portainer**: Portainer GitOps requires environment variables to be set in the Portainer UI. The `.env` file is not used directly by Portainer.

### Verify Deployment

1. Check container status:
   ```bash
   docker compose ps
   ```

2. Check Cloudflare Tunnel logs:
   ```bash
   docker compose logs cloudflare-tunnel
   ```

3. Access your SeAT instance:
   - Open `https://seat.example.com` (or your configured domain)
   - Get admin login link:
     ```bash
     docker compose exec front php artisan seat:admin:login
     ```

## Accessing the Frontend Service

### Executing Commands in the Frontend Container

To execute commands in the frontend service without needing to `cd` into the compose file directory, use one of these resilient methods:

**Method 1: Using absolute path to docker-compose.yml**
```bash
docker compose -f /path/to/seat-docker/docker-compose.yml exec front <command>
```

**Method 2: Using container name pattern (most resilient)**
```bash
docker exec $(docker ps -q -f name=seat-docker-front) <command>
```

**Method 3: Using project name**
```bash
docker compose -p seat-docker exec front <command>
```

### Critical Commands

**Get Admin Login Link**
```bash
docker compose exec front php artisan seat:admin:login
```
This generates a temporary login URL for the built-in admin account.

**Run Diagnostics**
```bash
docker compose exec front php artisan seat:admin:diagnose
```
Use this command to diagnose potential SeAT installation problems. This is highly recommended when troubleshooting issues.

**View Configuration**
```bash
# Show all configuration values
docker compose exec front php artisan config:show

# Show specific config (e.g., app.url)
docker compose exec front php artisan config:show app.url
```

**Other Useful Commands**
```bash
# Clear configuration cache
docker compose exec front php artisan config:clear

# Clear route cache
docker compose exec front php artisan route:clear

# List all routes
docker compose exec front php artisan route:list

# Set administrator email
docker compose exec front php artisan seat:admin:email admin@example.com

# Run database migrations
docker compose exec front php artisan migrate

# Update SDE (Static Data Export)
docker compose exec front php artisan eve:update:sde
```

### Accessing Container Shell

To get an interactive shell inside the frontend container:

```bash
docker compose exec front /bin/sh
```

Or using the container name pattern:
```bash
docker exec -it $(docker ps -q -f name=seat-docker-front) /bin/sh
```

## Uninstalling the Service

To stop and remove all containers, networks, and optionally volumes:

**Using the uninstall script (recommended):**
```bash
./uninstall.sh
```

The script will:
- Stop and remove all containers
- Remove networks
- Optionally remove volumes (with confirmation prompt)

**Manual uninstall:**
```bash
# Stop and remove containers/networks (preserves volumes)
docker compose -f /path/to/seat-docker/docker-compose.yml down

# Stop and remove everything including volumes (WARNING: deletes all data)
docker compose -f /path/to/seat-docker/docker-compose.yml down -v
```

**Note:** The uninstall script uses the docker-compose.yml file location automatically, so you can run it from any directory.
