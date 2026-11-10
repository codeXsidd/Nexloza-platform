# NexIoza Design System

## Brand Identity

- **Product:** NexIoza Universal IoT Platform
- **Style:** Premium IoT SaaS
- **Framework:** Material 3 (Material Design 3)
- **Design direction:** Blynk simplicity + ThingsBoard operational depth

## Color Palette

### Brand Colors

| Token | Value | Usage |
|---|---|---|
| Primary | `#6366F1` | Main actions, navigation indicators, links |
| Primary Dark | `#4F46E5` | Pressed states, emphasis |
| Primary Light | `#818CF8` | Dark theme primary, subtle highlights |
| Secondary | `#0EA5E9` | Secondary actions, information |
| Tertiary | `#8B5CF6` | Accent, highlights |

### Semantic Colors

| Token | Value | Usage |
|---|---|---|
| Success | `#22C55E` | Online status, confirmations, positive state |
| Warning | `#F59E0B` | Caution states, medium severity |
| Error | `#EF4444` | Critical alerts, destructive actions |
| Info | `#3B82F6` | Informational states, virtual badges |

### Device Status

| Token | Value |
|---|---|
| Online | `#22C55E` |
| Offline | `#9CA3AF` |
| Device Warning | `#F59E0B` |

### Alarm Severity

| Level | Color |
|---|---|
| Critical | `#EF4444` |
| High | `#F97316` |
| Medium | `#F59E0B` |
| Warning | `#EAB308` |
| Info | `#3B82F6` |

### Surface Colors (Light)

| Token | Value |
|---|---|
| Background | `#F8FAFC` |
| Surface | `#FFFFFF` |
| Surface Elevated | `#FFFFFF` |
| Card | `#FFFFFF` |
| Divider | `#E2E8F0` |
| Text Primary | `#0F172A` |
| Text Secondary | `#64748B` |
| Disabled | `#CBD5E1` |

### Surface Colors (Dark)

| Token | Value |
|---|---|
| Background | `#0F172A` |
| Surface | `#1E293B` |
| Surface Elevated | `#334155` |
| Card | `#1E293B` |
| Divider | `#334155` |
| Text Primary | `#F1F5F9` |
| Text Secondary | `#94A3B8` |
| Disabled | `#475569` |

## Spacing System

8-point grid system:

| Token | Value |
|---|---|
| `xs` | 4px |
| `sm` | 8px |
| `md` | 16px |
| `lg` | 24px |
| `xl` | 32px |
| `xxl` | 48px |

### Radii

| Token | Value |
|---|---|
| Card | 12px |
| Button | 12px |
| Input | 12px |
| Sheet | 20px |

## Typography

Material 3 type scale with system font. Full range from `displayLarge` (57px) to `labelSmall` (11px).

## Responsive Breakpoints

| Breakpoint | Width | Layout |
|---|---|---|
| Compact Mobile | < 600px | Bottom navigation, single column |
| Mobile | 600–899px | Navigation rail, 2 columns |
| Tablet | 900–1199px | Navigation rail, 3 columns |
| Desktop | 1200–1439px | Sidebar, 4 columns |
| Wide Desktop | ≥ 1440px | Sidebar (wide), 4 columns |

## Themes

- **Light mode:** Warm slate background (#F8FAFC), white cards, indigo primary
- **Dark mode:** Deep slate background (#0F172A), dark cards, light indigo primary
- **System mode:** Follows device preference

## Design System Components

Located in `lib/core/design_system/`:

| Component | File | Purpose |
|---|---|---|
| `NexStatCard` | `nex_stat_card.dart` | Statistics display with icon, value, label |
| `NexDeviceCard` | `nex_device_card.dart` | Device list item with online status |
| `NexDeviceGridCard` | `nex_device_card.dart` | Device grid card for grid view |
| `NexAlarmCard` | `nex_alarm_card.dart` | Alarm with severity badge, left border |
| `NexIntegrationCard` | `nex_integration_card.dart` | Integration status card |
| `NexSectionHeader` | `nex_section_header.dart` | Section title with optional action |
| `NexErrorPanel` | `nex_error_panel.dart` | Error state with retry |
| `NexOfflinePanel` | `nex_error_panel.dart` | Offline state with retry |
| `NexLoadingSkeleton` | `nex_loading_skeleton.dart` | Animated loading placeholder |
| `NexCardSkeleton` | `nex_loading_skeleton.dart` | Card-shaped loading skeleton |
| `NexListSkeleton` | `nex_loading_skeleton.dart` | List of loading skeletons |

## Responsive Utilities

Located in `lib/core/responsive/`:

| Component | File | Purpose |
|---|---|---|
| `AppBreakpoints` | `breakpoints.dart` | Breakpoint constants and helpers |
| `ResponsiveBuilder` | `responsive_builder.dart` | Builder widget with screen size |
| `ResponsiveLayout` | `responsive_builder.dart` | Mobile/tablet/desktop layout switch |
| `ResponsiveGrid` | `responsive_builder.dart` | Auto-column responsive grid |
