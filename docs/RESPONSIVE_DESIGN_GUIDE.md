# NexIoza Responsive Design Guide

## Breakpoint System

Centralized in `lib/core/responsive/breakpoints.dart`.

| Name | Min Width | Columns | Padding | Navigation |
|---|---|---|---|---|
| Compact Mobile | 0px | 1 | 12px | Bottom nav |
| Mobile | 600px | 2 | 16px | Nav rail |
| Tablet | 900px | 3 | 20px | Nav rail |
| Desktop | 1200px | 4 | 24px | Sidebar |
| Wide Desktop | 1440px | 4 | 32px | Sidebar |

## Usage

### Check screen size

```dart
import 'package:nexloza/core/responsive/breakpoints.dart';

final size = AppBreakpoints.of(context);
if (AppBreakpoints.isDesktop(context)) { ... }
if (AppBreakpoints.isMobile(context)) { ... }
```

### Responsive layout switching

```dart
ResponsiveLayout(
  mobile: MobileView(),
  tablet: TabletView(),
  desktop: DesktopView(),
)
```

### Responsive grid

```dart
ResponsiveGrid(
  children: items.map((i) => ItemCard(item: i)).toList(),
)
```

Auto-selects column count based on screen width.

### Responsive padding

```dart
padding: AppBreakpoints.screenPadding(context),
```

## Testing Viewports

Representative test viewports:

| Device | Size |
|---|---|
| Small phone | 360 × 800 |
| Large phone | 430 × 932 |
| Tablet portrait | 768 × 1024 |
| Tablet landscape | 1024 × 768 |
| Laptop | 1440 × 900 |
| Desktop | 1920 × 1080 |

## Guidelines

- Never assume a device name — use `AppBreakpoints.of(context)` for all layout decisions
- Use `ResponsiveGrid` for card layouts instead of fixed column counts
- Use `AppBreakpoints.screenPadding(context)` instead of hardcoded EdgeInsets
- Test at breakpoint boundaries (599, 600, 899, 900, 1199, 1200, 1439, 1440)
- Ensure no horizontal overflow at any breakpoint
- Desktop sidebar only appears at ≥1200px
