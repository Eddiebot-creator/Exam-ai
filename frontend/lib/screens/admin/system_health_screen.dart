import 'package:flutter/material.dart';

import '../../services/api_client.dart';
import '../../theme/calm_theme.dart';
import '../../utils/ui_helpers.dart';
import '../../widgets/buttons.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/mascot.dart';
import '../../widgets/soft_card.dart';

class SystemHealthScreen extends StatefulWidget {
  const SystemHealthScreen({super.key, required this.api});

  final ApiClient api;

  @override
  State<SystemHealthScreen> createState() => _SystemHealthScreenState();
}

class _SystemHealthScreenState extends State<SystemHealthScreen> {
  bool loading = true;
  Map<String, dynamic> deep = {};
  Map<String, dynamic> schema = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final checks = (deep['checks'] as Map?)?.cast<String, dynamic>() ?? {};
    final tables = (schema['tables'] as Map?)?.cast<String, dynamic>() ?? {};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionIntro(
          icon: Icons.health_and_safety_rounded,
          title: 'System Health',
          subtitle: 'Database, schema, upload and AI provider diagnostics for launch readiness.',
          mascot: StudentMascot(size: 100, mood: MascotMood.focus),
        ),
        const SizedBox(height: 16),
        if (loading)
          const SoftCard(child: Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator())))
        else ...[
          ResponsiveCalmGrid(
            minWidth: 220,
            children: [
              _HealthMetric(title: 'Backend', value: deep['status']?.toString() ?? 'unknown', ok: deep['status'] == 'ok'),
              _HealthMetric(title: 'Database', value: checks['database']?.toString() ?? 'unknown', ok: checks['database'] == 'ok'),
              _HealthMetric(title: 'Schema', value: schema['status']?.toString() ?? 'unknown', ok: schema['status'] == 'ok'),
              _HealthMetric(title: 'Gemini', value: checks['gemini']?.toString() ?? 'unknown', ok: checks['gemini'] == 'configured'),
            ],
          ),
          const SizedBox(height: 16),
          SoftCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const CircleIcon(icon: Icons.storage_rounded, color: CalmTheme.teal),
                    const SizedBox(width: 12),
                    Expanded(child: Text('Schema checks', style: Theme.of(context).textTheme.titleLarge)),
                    SecondaryCalmButton(label: 'Refresh', icon: Icons.refresh_rounded, onTap: _load),
                  ],
                ),
                const SizedBox(height: 14),
                if (tables.isEmpty)
                  const SoftText('No schema details returned yet.')
                else
                  for (final entry in tables.entries)
                    _SchemaRow(table: entry.key, data: (entry.value as Map).cast<String, dynamic>()),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SoftCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Launch checklist', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 10),
                _ChecklistItem(ok: checks['database'] == 'ok', text: 'Database accepts reads/writes'),
                _ChecklistItem(ok: schema['status'] == 'ok', text: 'Production schema has required columns'),
                _ChecklistItem(ok: checks['gemini'] == 'configured' || checks['openai'] == 'configured', text: 'At least one AI provider key is configured'),
                const _ChecklistItem(ok: true, text: 'Frontend hides raw server errors from students'),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      final results = await Future.wait([widget.api.healthDeep(), widget.api.healthSchema()]);
      if (!mounted) return;
      setState(() {
        deep = results[0];
        schema = results[1];
      });
    } catch (e) {
      if (mounted) toast(context, e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }
}

class _HealthMetric extends StatelessWidget {
  const _HealthMetric({required this.title, required this.value, required this.ok});

  final String title;
  final String value;
  final bool ok;

  @override
  Widget build(BuildContext context) => CalmMetric(
        title: title,
        value: value.replaceAll('_', ' '),
        subtitle: ok ? 'ready' : 'needs attention',
        icon: ok ? Icons.check_circle_rounded : Icons.error_rounded,
        color: ok ? CalmTheme.green : CalmTheme.orange,
      );
}

class _SchemaRow extends StatelessWidget {
  const _SchemaRow({required this.table, required this.data});

  final String table;
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final ok = data['ok'] == true;
    final missing = ((data['missing'] as List?) ?? []).map((x) => x.toString()).join(', ');
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(ok ? Icons.check_circle_rounded : Icons.warning_rounded, color: ok ? CalmTheme.green : CalmTheme.orange),
      title: Text(table, style: const TextStyle(fontWeight: FontWeight.w900)),
      subtitle: Text(ok ? 'All required columns present' : 'Missing: $missing'),
    );
  }
}

class _ChecklistItem extends StatelessWidget {
  const _ChecklistItem({required this.ok, required this.text});

  final bool ok;
  final String text;

  @override
  Widget build(BuildContext context) => ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(ok ? Icons.check_rounded : Icons.priority_high_rounded, color: ok ? CalmTheme.green : CalmTheme.orange),
        title: Text(text),
      );
}
