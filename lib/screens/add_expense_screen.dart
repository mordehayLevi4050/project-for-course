import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../logic/money.dart';
import '../models/categories.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/groupay_app_bar.dart';

class AddExpenseScreen extends StatefulWidget {
  final String groupId;

  const AddExpenseScreen({super.key, required this.groupId});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _amount = TextEditingController();
  final _details = TextEditingController();
  String? _category;
  String? _payerId;
  late final Set<String> _participantIds;
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    final members = context.read<AppState>().groupById(widget.groupId)!.members;
    if (members.length == 1) _payerId = members.single.id;
    // Shared with everyone by default.
    _participantIds = {for (final m in members) m.id};
  }

  @override
  void dispose() {
    _amount.dispose();
    _details.dispose();
    super.dispose();
  }

  int? get _amountAgorot => parseShekels(_amount.text);

  /// "Other" needs details to say what the expense was.
  bool get _detailsRequired => _category == otherCategory;
  bool get _detailsMissing => _detailsRequired && _details.text.trim().isEmpty;

  Future<void> _save() async {
    setState(() => _submitted = true);
    final amount = _amountAgorot;
    if (amount == null ||
        _payerId == null ||
        _participantIds.isEmpty ||
        _category == null ||
        _detailsMissing) {
      return;
    }
    final members = context.read<AppState>().groupById(widget.groupId)!.members;
    final everyone = members.every((m) => _participantIds.contains(m.id));
    await context.read<AppState>().addExpense(
          widget.groupId,
          payerId: _payerId!,
          amountAgorot: amount,
          title: _category!,
          details: _details.text,
          // Empty list means everyone.
          participantIds: everyone
              ? const []
              : [for (final m in members) if (_participantIds.contains(m.id)) m.id],
        );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final group = appState.groupById(widget.groupId)!;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: GroupayAppBar(subtitle: 'הוצאה חדשה · ${group.name}'),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Big amount field, bit style.
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text('סכום', style: textTheme.titleSmall?.copyWith(color: Colors.black54)),
                TextField(
                  controller: _amount,
                  autofocus: true,
                  textAlign: TextAlign.center,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d{0,7}([.,]\d{0,2})?')),
                  ],
                  style: textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: GroupayColors.deepTeal,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: '0',
                    suffixText: '₪',
                    suffixStyle: textTheme.headlineMedium?.copyWith(color: GroupayColors.deepTeal),
                    errorText: _submitted && _amountAgorot == null ? 'הזינו סכום גדול מ-0' : null,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('מי שילם?', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final m in group.members)
                ChoiceChip(
                  label: Text(m.name),
                  selected: _payerId == m.id,
                  selectedColor: GroupayColors.turquoise.withValues(alpha: 0.2),
                  onSelected: (_) => setState(() => _payerId = m.id),
                ),
            ],
          ),
          if (_submitted && _payerId == null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'בחרו מי שילם',
                style: textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.error),
              ),
            ),
          const SizedBox(height: 24),
          Text('עם מי מתחלק?', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: const Text('כולם'),
                selected: group.members.every((m) => _participantIds.contains(m.id)),
                selectedColor: GroupayColors.turquoise.withValues(alpha: 0.2),
                onSelected: (_) => setState(
                  () => _participantIds.addAll([for (final m in group.members) m.id]),
                ),
              ),
              for (final m in group.members)
                FilterChip(
                  label: Text(m.name),
                  selected: _participantIds.contains(m.id),
                  selectedColor: GroupayColors.turquoise.withValues(alpha: 0.2),
                  onSelected: (selected) => setState(() {
                    if (selected) {
                      _participantIds.add(m.id);
                    } else {
                      _participantIds.remove(m.id);
                    }
                  }),
                ),
            ],
          ),
          if (_submitted && _participantIds.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'בחרו לפחות משתתף אחד',
                style: textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.error),
              ),
            ),
          const SizedBox(height: 24),
          DropdownButtonFormField<String>(
            initialValue: _category,
            decoration: InputDecoration(
              labelText: 'על מה?',
              filled: true,
              fillColor: Colors.white,
              errorText: _submitted && _category == null ? 'בחרו קטגוריה' : null,
            ),
            items: [
              for (final c in appState.categories) DropdownMenuItem(value: c, child: Text(c)),
            ],
            onChanged: (c) => setState(() => _category = c),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _details,
            minLines: 3,
            maxLines: 6,
            decoration: InputDecoration(
              labelText: _detailsRequired ? 'פירוט' : 'פירוט (לא חובה)',
              hintText: 'למשל: 2 פיצות, שתייה וקינוח',
              alignLabelWithHint: true,
              filled: true,
              fillColor: Colors.white,
              errorText: _submitted && _detailsMissing ? 'נדרש פירוט' : null,
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _save,
            style: FilledButton.styleFrom(
              backgroundColor: GroupayColors.turquoise,
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            child: const Text('הוספת ההוצאה'),
          ),
        ],
      ),
    );
  }
}
