# NexIoza Architecture

> System architecture for the NexIoza universal IoT platform.

## Overview

NexIoza is a modular, metadata-driven IoT platform built with Clean Architecture principles.

## System Diagram

<!-- TODO: Add architecture diagram in Phase 3 -->

```
Flutter App  ──HTTPS/WS──>  Supabase Backend
                                    │
                             Device Auth / Commands
                                    │
                              MQTT Broker (TLS)
                                    │
                        ESP32 / ESP8266 / Raspberry Pi
```

## Flutter App Architecture

- **Presentation Layer**: Screens, widgets, Riverpod controllers
- **Domain Layer**: Entities, use cases, repository interfaces
- **Data Layer**: Repository implementations, data sources, DTOs
- **Services Layer**: Supabase, MQTT, local DB, secure storage

Feature-first module organization under `lib/features/`.

## Backend Architecture

<!-- TODO: Supabase schema, Edge Functions, RLS — Phase 3 -->

## MQTT Protocol

<!-- TODO: Topic convention, message formats — Phase 3 -->

## Data Flow

<!-- TODO: Telemetry, command, and automation data flow diagrams — Phase 3 -->
