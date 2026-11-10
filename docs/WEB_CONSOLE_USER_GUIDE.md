# NexIoza Web Developer Console — User Guide

## Accessing the Console

Open the NexIoza web application in Chrome or any modern browser at the configured URL. The developer console layout automatically activates when the browser window is 1200px or wider.

## Sidebar Navigation

The left sidebar provides access to all console features organized into sections.

### Collapse / Expand

Click the chevron icon in the sidebar header to toggle between expanded (260px) and collapsed (72px icon-only) modes.

### Navigation Sections

**General**
- **Overview** — Dashboard with device counts, online/offline stats, quick actions, recent activity
- **Organizations** — Create and manage organizations, members, and roles
- **Projects** — Create projects, manage settings, view device assignments

**Device Management**
- **Devices** — View all devices, add new devices, pair devices, manage sensors and actuators
- **Device Templates** — Browse hardware templates for ESP32, ESP8266, Raspberry Pi, and protocol templates for MQTT and HTTP
- **Virtual Devices** — Create virtual devices for testing, run simulators, view digital twin state

**Intelligence**
- **Dashboard Builder** — Create, edit, and manage dashboards with 47 widget types across 6 categories
- **Telemetry & Analytics** — Real-time and historical telemetry, device status charts, project analytics
- **Automation & Rules** — Create automation rules, visual rule builder with 39 node types, scenes, scheduling
- **Alerts & Notifications** — View active alarms, alarm history, escalation policies, notification preferences

**Platform**
- **Integrations** — MQTT, HTTP, Alexa (placeholder), Google Home (placeholder), Webhooks, AI Assistant
- **Firmware & OTA** — Future capability (migration exists, management coming soon)
- **API & Developer Tools** — API keys, MQTT connection info, topic format reference, device studio

**Settings** — Theme, notifications, profile, organizations, developer tools

## Working with Devices

1. Navigate to **Devices** in the sidebar
2. Use the search bar to find devices by name
3. Click a device to view its detail page with sensors, actuators, and connection status
4. Use **Add Device** to register a new physical device
5. Use **Pair Device** for the guided pairing flow

## Building Dashboards

1. Navigate to **Dashboard Builder**
2. Click **Create Dashboard** to start a new dashboard
3. Use the widget catalog to add from 47 available widget types
4. Configure each widget's data source, title, and display settings
5. Drag and resize widgets in the editor
6. Save the dashboard

## Managing Automations

1. Navigate to **Automation & Rules**
2. View existing automation rules with their enable/disable status
3. Create new rules using the visual rule editor
4. The editor provides 39 node types across triggers, conditions, actions, and flow control
5. Validate rules before publishing
6. View execution history and use dry-run for testing

## Alarm Management

1. Navigate to **Alerts & Notifications**
2. View alarms by severity: Critical, High, Medium, Warning, Info
3. Acknowledge active alarms
4. View escalation policies and notification delivery status
5. Configure notification preferences for alarm delivery

## Keyboard Navigation

The web console supports keyboard navigation:
- Tab through interactive elements
- Enter/Space to activate buttons and links
- Escape to close dialogs and modals
