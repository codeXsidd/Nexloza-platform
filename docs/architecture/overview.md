# Nexloza Architecture Overview

## System Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    Flutter Mobile App                     │
│  ┌──────┐ ┌────────┐ ┌───────┐ ┌──────┐ ┌───────────┐  │
│  │ Auth │ │Projects│ │Devices│ │ Auto │ │AI Assistant│  │
│  └──┬───┘ └───┬────┘ └──┬────┘ └──┬───┘ └─────┬─────┘  │
└─────┼─────────┼─────────┼─────────┼───────────┼─────────┘
      │         │         │         │           │
      ▼         ▼         ▼         ▼           ▼
┌─────────────────────────────────────────────────────────┐
│                      Supabase                            │
│  ┌──────┐ ┌────────┐ ┌────────┐ ┌───────┐ ┌─────────┐  │
│  │ Auth │ │PostgreSQL│ │Realtime│ │Storage│ │  Edge   │  │
│  │      │ │  + RLS  │ │       │ │       │ │Functions│  │
│  └──────┘ └────────┘ └────────┘ └───────┘ └────┬────┘  │
└─────────────────────────────────────────────────┼───────┘
                                                  │
         ┌────────────────────┬───────────────────┤
         │                    │                   │
         ▼                    ▼                   ▼
┌──────────────┐  ┌──────────────────┐  ┌────────────────┐
│  EMQX MQTT   │  │   AWS Bedrock    │  │ Alexa / Google │
│   Broker     │  │   (Claude AI)    │  │  Home Cloud    │
└──────┬───────┘  └──────────────────┘  └────────────────┘
       │
       ▼
┌──────────────────────────────────────────────────────────┐
│              IoT Devices (ESP32, ESP8266, etc.)           │
│  ┌─────────┐ ┌───────────┐ ┌──────────┐ ┌────────────┐  │
│  │ Sensors │ │ Actuators │ │ Relays   │ │   Custom   │  │
│  └─────────┘ └───────────┘ └──────────┘ └────────────┘  │
└──────────────────────────────────────────────────────────┘
```

## Data Flows

### Device Telemetry
Device → MQTT → Telemetry Ingest Function → PostgreSQL → Supabase Realtime → App

### Device Commands
App → Device Command Function → PostgreSQL → MQTT → Device → ACK → App

### Automation
Telemetry → Automation Engine → Evaluate Triggers/Conditions → Execute Actions → Notification
