# Cross-Platform Shadcn UI Integration Guide (React & Flutter)

This document establishes the official cross-platform implementation guide for **shadcn/ui** across Infortts React web apps and Flutter mobile/desktop applications.

---

## 1. Design Token Mapping (Single Source of Truth)

All themes map to the canonical Infortts Acoustic Brand Tokens ([`tokens.json`](file:///Users/admin/dev/inforttsOrg/logos/3d/brand/tokens.json)):

| Token Role | Infortts Value | React / Tailwind (CSS Var) | Flutter (`shadcn_ui`) |
| :--- | :--- | :--- | :--- |
| **Background** | `#05070C` (Infortts Black) | `--background: 225 43% 3%` | `background: Color(0xFF05070C)` |
| **Card / Panel** | `#090D1A` (Dark Carbon) | `--card: 226 38% 7%` | `card: Color(0xFF090D1A)` |
| **Popover** | `#121B2D` (Panel Bg) | `--popover: 226 38% 7%` | `popover: Color(0xFF121B2D)` |
| **Primary** | `#00D2FF` (Sonar Cyan) | `--primary: 191 100% 50%` | `primary: Color(0xFF00D2FF)` |
| **Secondary** | `#162032` (Steel) | `--secondary: 222 34% 15%` | `secondary: Color(0xFF162032)` |
| **Border / Input** | `#1E293B` (Border) | `--border: 217 33% 16%` | `border: Color(0xFF1E293B)` |
| **Ring** | `#00D2FF` (Sonar Focus) | `--ring: 191 100% 50%` | `ring: Color(0xFF00D2FF)` |
| **Radius** | `8px` (`0.5rem`) | `--radius: 0.5rem` | `radius: BorderRadius.circular(8)` |

---

## 2. React Implementation (Web)

Configuration file: [`components.json`](file:///Users/admin/dev/inforttsOrg/projects/professional/components.json)
UI Library folder: [`src/components/ui/`](file:///Users/admin/dev/inforttsOrg/projects/professional/src/components/ui)

```tsx
import { Button } from "@/components/ui/button"
import { Badge } from "@/components/ui/badge"
import { Card, CardHeader, CardTitle, CardContent } from "@/components/ui/card"

export function MetricCard() {
  return (
    <Card className="border-border bg-card">
      <CardHeader>
        <Badge variant="cyan" dot>Optimal</Badge>
        <CardTitle>Distributed Throughput</CardTitle>
      </CardHeader>
      <CardContent>
        <Button variant="default">Inspect Telemetry</Button>
      </CardContent>
    </Card>
  )
}
```

---

## 3. Flutter Implementation (Mobile & Desktop)

Using the open-source [`shadcn_ui`](https://pub.dev/packages/shadcn_ui) package:

```yaml
# pubspec.yaml
dependencies:
  shadcn_ui: ^0.18.0
```

```dart
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

void main() {
  runApp(const InforttsApp());
}

class InforttsApp extends StatelessWidget {
  const InforttsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ShadApp(
      title: 'Infortts Enterprise',
      darkTheme: ShadThemeData(
        brightness: Brightness.dark,
        colorScheme: const ShadZincColorScheme.dark(
          background: Color(0xFF05070C),
          card: Color(0xFF090D1A),
          primary: Color(0xFF00D2FF),
          secondary: Color(0xFF162032),
          border: Color(0xFF1E293B),
        ),
        radius: BorderRadius.circular(8),
      ),
      themeMode: ThemeMode.dark,
      home: const DashboardScreen(),
    );
  }
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ShadCard(
          title: const Text('2,000+ CAU Real-time'),
          description: const Text('Sub-15ms p99 Redis buffers'),
          footer: ShadButton(
            child: const Text('Schedule Discovery'),
            onPressed: () {},
          ),
        ),
      ),
    );
  }
}
```
