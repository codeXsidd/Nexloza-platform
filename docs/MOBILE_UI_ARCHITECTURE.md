# NexIoza Mobile UI Architecture

## Navigation Structure

Five-destination bottom navigation (mobile) / navigation rail (tablet):

| Tab | Route | Screen | Purpose |
|---|---|---|---|
| Home | `/home` | `HomeScreen` | Overview, stats, quick actions |
| Devices | `/devices` | `DevicesScreen` | Device management, pairing |
| Automation | `/automations` | `AutomationsScreen` | Rules, scenes, triggers |
| Analytics | `/analytics` | `AnalyticsScreen` | Telemetry, charts, insights |
| Settings | `/settings` | `SettingsScreen` | Preferences, account, tools |

### Secondary Navigation (Push Routes)

Accessible from screens and sidebar:

- Organizations (`/organizations`)
- Projects (`/projects`)
- Dashboards (`/dashboards`)
- Virtual Devices (`/virtual-devices`)
- Rules Engine (`/rules`)
- Alarms (`/alarms`)
- Notifications (`/notifications`)
- Scenes (`/scenes`)
- Integrations (`/integrations`)
- AI Assistant (`/ai`)
- Device Studio (`/device-studio`)
- Device Templates (`/device-templates`)
- Firmware & OTA (`/firmware`)
- Developer Tools (`/developer`)
- API Keys (`/api-keys`)

## Screen Architecture

### Home Screen

- Personalized greeting from auth user metadata
- 4 stat cards in responsive grid (Total Devices, Online, Offline, Projects)
- Quick Actions chips (New Project, Add Device, Automation, AI, Dashboards, etc.)
- Recent Activity from notifications provider

### Devices Screen

- List view with search and filter
- Online/offline indicators
- Virtual device badges
- Device detail with sensor/actuator management
- Device pairing flow

### Automation Screen

- Automation list with enable/disable
- Create automation workflow
- Links to visual rule editor (Phase 8)
- Scenes management

### Analytics Screen

- Responsive stat cards (Projects, Devices, Online, Automations)
- Device status donut chart (theme-aware hole color)
- Projects by category bar chart
- Automation health summary

### Settings Screen

Organized into sections:
1. **Account** — Profile, Organizations, Invitations
2. **Appearance** — Theme mode (Light/System/Dark)
3. **Notifications** — Push, Email, Notification Preferences
4. **Developer** — API Keys, Developer Tools, Device Studio
5. **Platform** — Integrations, AI Assistant
6. **About** — Version info, Privacy, Licenses
7. Log Out with confirmation dialog

## Layout Strategy

- Mobile (< 600px): Full-width, bottom navigation
- Tablet (600–899px): Navigation rail, 2-column grids
- The same screens render on both mobile and tablet with responsive padding and column counts
