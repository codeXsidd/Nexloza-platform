# Local Development Setup

## Prerequisites
- Flutter SDK 3.47+
- Docker and Docker Compose
- Supabase CLI (optional but recommended)
- Git

## Quick Start

1. **Clone the repository**
   ```bash
   git clone https://github.com/codeXsidd/nexioza-platform.git
   cd nexioza-platform
   ```

2. **Configure environment**
   ```bash
   cp .env.example .env
   # Edit .env with your Supabase project URL and anon key
   ```

3. **Start backend services**
   ```bash
   docker-compose up -d
   ```
   This starts PostgreSQL, Supabase services, and EMQX MQTT broker.

4. **Run database migrations**
   ```bash
   cd backend/supabase
   supabase db push
   ```

5. **Run the Flutter app**
   ```bash
   cd app
   flutter pub get
   flutter run
   ```

6. **Access services**
   - Supabase Studio: http://localhost:54323
   - EMQX Dashboard: http://localhost:18083
   - REST API: http://localhost:54321

## Connecting a Device
See [firmware/README.md](../../firmware/README.md) for ESP32/ESP8266 setup.
