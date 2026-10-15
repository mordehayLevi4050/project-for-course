import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../logic/money.dart';
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
  final _title = TextEditingController();
  final _details = TextEditingController();
  String? _payerId;
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    final members = context.read<AppState>().groupById(widget.groupId)!.members;
    if (members.length == 1) _payerId = members.single.id;
  }

  @override
  void dispose() {
    _amount.dispose();
    _title.dispose();
    _details.dispose();
    super.dispose();
  }

  int? get _amountAgorot => parseShekels(_amount.text);

  Future<void> _save() async {
    setState(() => _submitted = true);
    final amount = _amountAgorot;
    if (amount == null || _payerId == null || _title.text.trim().isEmpty) return;
    await context.read<AppState>().addExpense(
          widget.groupId,
          payerId: _payerId!,
          amountAgorot: amount,
          title: _title.text,
          details: _details.text,
        );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final group = context.watch<AppState>().groupById(widget.groupId)!;
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
          TextField(
            controller: _title,
            maxLength: 40,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: 'על מה?',
              hintText: 'למשל: ארוחת ערב',
              filled: true,
              fillColor: Colors.white,
              errorText: _submitted && _title.text.trim().isEmpty ? 'הזינו תיאור קצר' : null,
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _details,
            minLines: 3,
            maxLines: 6,
            decoration: const InputDecoration(
              labelText: 'פירוט (לא חובה)',
              hintText: 'למשל: 2 פיצות, שתייה וקינוח',
              alignLabelWithHint: true,
              filled: true,
              fillColor: Colors.white,
            ),
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
