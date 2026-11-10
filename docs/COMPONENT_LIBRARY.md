# NexIoza Component Library

## Design System Components

All components are in `lib/core/design_system/` and exported from `design_system.dart`.

### NexStatCard

Statistics display with icon, value, label, and optional navigation.

```dart
NexStatCard(
  label: 'Total Devices',
  value: '42',
  icon: Icons.devices_other,
  iconColor: AppColors.primary,
  subtitle: 'Across 3 projects',
  onTap: () => navigateToDevices(),
)
```

### NexDeviceCard

Device list item with online/offline status, virtual badge, and favorite toggle.

```dart
NexDeviceCard(
  name: 'Living Room Sensor',
  subtitle: 'ESP32 • Temperature',
  isOnline: true,
  isVirtual: false,
  isFavorite: true,
  onTap: () => navigateToDetail(),
  onFavoriteTap: () => toggleFavorite(),
)
```

### NexDeviceGridCard

Grid-layout device card for grid view mode.

```dart
NexDeviceGridCard(
  name: 'Garden Valve',
  subtitle: 'ESP8266',
  icon: Icons.water_drop,
  isOnline: true,
  control: Switch(value: isOpen, onChanged: toggleValve),
)
```

### NexAlarmCard

Alarm display with severity color, left border accent, and acknowledge action.

```dart
NexAlarmCard(
  title: 'High Temperature Alert',
  description: 'Sensor reading exceeds 45°C threshold',
  deviceName: 'Server Room Sensor',
  severity: AlarmSeverityLevel.critical,
  timestamp: '2 min ago',
  isAcknowledged: false,
  onTap: () => viewAlarm(),
  onAcknowledge: () => acknowledgeAlarm(),
)
```

### NexIntegrationCard

Integration status display with status badge.

```dart
NexIntegrationCard(
  name: 'MQTT',
  description: 'NanoMQ broker connection',
  icon: Icons.router,
  status: IntegrationStatus.connected,
  onTap: () => configureIntegration(),
)
```

Supported statuses: `connected`, `configured`, `available`, `disconnected`, `requiresCredentials`, `requiresExternalSetup`, `comingSoon`, `notImplemented`.

### NexSectionHeader

Section title with optional action button.

```dart
NexSectionHeader(
  title: 'Recent Devices',
  actionLabel: 'View All',
  actionIcon: Icons.arrow_forward,
  onAction: () => viewAllDevices(),
)
```

### NexErrorPanel / NexOfflinePanel

Error and offline states with retry.

```dart
NexErrorPanel(
  message: 'Failed to load devices',
  detail: 'Check your connection and try again',
  onRetry: () => refresh(),
)
```

### NexLoadingSkeleton

Animated loading placeholder with variants.

```dart
NexLoadingSkeleton(width: 200, height: 16)
NexLoadingSkeleton.circle(size: 40)
NexLoadingSkeleton.text(width: 120)
NexLoadingSkeleton.card()
NexCardSkeleton(lines: 3)
NexListSkeleton(itemCount: 5)
```

## Shared Widgets (Pre-existing)

Located in `lib/shared/widgets/`:

| Widget | Purpose |
|---|---|
| `AppButton` | Primary action button |
| `AppScaffold` | Navigation shell (mobile/tablet/desktop) |
| `AppTextField` | Text input field |
| `ConfirmationDialog` | Destructive action confirmation |
| `EmptyStateWidget` | Empty content state |
| `ErrorWidget` | Error display |
| `LoadingIndicator` | Circular progress indicator |
| `NotFoundScreen` | 404 route handler |
| `StatusBadge` | Status indicator badge |
| `WebConsoleSidebar` | Desktop sidebar navigation |
