# Project Management Guide

## Overview

NexIoza organizes IoT devices into **projects** — logical groupings that share configuration, access controls, and MQTT topic namespaces. Every device belongs to exactly one project.

## Creating a Project

### Using Templates

1. Navigate to **Projects** tab
2. Tap the **+** floating action button
3. Select a template from the grid:
   - **Smart Home** — lights, fans, temperature, motion
   - **Smart Agriculture** — soil moisture, temperature, humidity
   - **Smart Irrigation** — soil sensors and valve control
   - **Weather Monitoring** — outdoor sensors (temp, humidity, pressure, rain)
   - **Water Management** — tank levels, leak detection, consumption
   - **Energy Monitoring** — voltage, current, power tracking
   - **Industrial IoT** — equipment monitoring, vibration, operational status
   - **Security Monitoring** — PIR motion, door/window, camera triggers
   - **Custom Project** — blank slate, configure everything yourself
4. The template pre-fills name, description, and category
5. Adjust fields as needed and tap **Create**

### Custom Project

Select "Custom Project" to start with a blank form. Fill in:
- **Name** (required)
- **Description** (optional)
- **Category** (select from list)

## Searching and Filtering

The Projects screen provides:
- **Search bar** — filter by project name (real-time, client-side)
- **Category chips** — horizontal scroll of filter chips to show only projects in a specific category

## Project Detail Screen

Shows:
- Project name, category icon, active/archived status badge
- **Device stats** — total devices, online count, offline count
- **Details card** — created date, updated date, status
- **View Devices** button — navigates to the filtered device list
- **Add Device** button — starts the device onboarding wizard

### Archive / Restore

Use the overflow menu (three-dot icon) to:
- **Archive** an inactive project (hides from default view)
- **Restore** an archived project
- **Delete** a project (requires confirmation; deletes all associated devices and data)

## Data Model

Projects are stored in the `projects` Supabase table with Row Level Security (RLS) policies ensuring users can only access projects they own or are members of.

| Field | Type | Description |
|-------|------|-------------|
| id | UUID | Primary key |
| name | text | Project name |
| description | text | Optional description |
| category | text | Category slug |
| organization_id | UUID | Optional org association |
| owner_id | UUID | Creator's user ID |
| settings | jsonb | Project-level config |
| is_active | boolean | Archive flag |

## MQTT Topic Namespace

Each project gets its own topic namespace:

```
nexloza/v1/{organization_id}/{project_id}/{device_id}/{channel}
```

This ensures device isolation — devices in one project cannot receive messages from another.
