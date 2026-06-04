import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/shared_widgets.dart';
import '../../data/models/site_task_models.dart';
import '../bloc/home_bloc.dart';

class AddTaskBottomSheet extends StatefulWidget {
  final String siteId;
  final List<SiteMemberModel> members;
  const AddTaskBottomSheet({super.key, required this.siteId, required this.members});
  @override State<AddTaskBottomSheet> createState() => _AddTaskBottomSheetState();
}

class _AddTaskBottomSheetState extends State<AddTaskBottomSheet> {
  final _formKey   = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl  = TextEditingController();
  SiteMemberModel? _selected;

  @override
  void dispose() { _titleCtrl.dispose(); _descCtrl.dispose(); super.dispose(); }

  InputDecoration _dec(String label, String hint, IconData icon) => InputDecoration(
    labelText: label, hintText: hint, prefixIcon: Icon(icon, size: 20),
    filled: true, fillColor: AppColors.surfaceWarm,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.divider)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.divider)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
  );

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_selected == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a member to assign')));
      return;
    }
    context.read<HomeBloc>().add(HomeTaskCreateRequested(CreateTaskRequest(
      siteId: widget.siteId, assignedToId: _selected!.id,
      title: _titleCtrl.text.trim(), description: _descCtrl.text.trim())));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20,
          MediaQuery.of(context).viewInsets.bottom + 32),
      child: Form(key: _formKey, child: Column(mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(width: 36, height: 4,
            decoration: BoxDecoration(color: AppColors.divider,
                borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          Text('Add new task', style: GoogleFonts.playfairDisplay(
              fontSize: 18, color: AppColors.textPrimary)),
          const SizedBox(height: 20),
          TextFormField(controller: _titleCtrl, textInputAction: TextInputAction.next,
            decoration: _dec('Task title', 'e.g. Foundation inspection', Icons.task_alt_outlined),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Title is required' : null),
          const SizedBox(height: 12),
          TextFormField(controller: _descCtrl, maxLines: 2,
            textInputAction: TextInputAction.next,
            decoration: _dec('Description (optional)', 'Any notes...', Icons.notes_outlined)),
          const SizedBox(height: 12),
          DropdownButtonFormField<SiteMemberModel>(
            value: _selected,
            hint: Text('Assign to member',
                style: GoogleFonts.lato(color: AppColors.textHint)),
            decoration: _dec('', '', Icons.person_outline).copyWith(prefixIcon: null,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
            items: widget.members.map((m) => DropdownMenuItem(
              value: m,
              child: Row(children: [
                AvatarCircle(initials: m.initials, size: 24, fontSize: 9),
                const SizedBox(width: 8),
                Text('${m.name} (${m.employeeId})',
                    style: GoogleFonts.lato(fontSize: 13)),
              ]),
            )).toList(),
            onChanged: (m) => setState(() => _selected = m),
          ),
          const SizedBox(height: 24),
          BlocBuilder<HomeBloc, HomeState>(builder: (context, state) =>
            SizedBox(width: double.infinity, height: 50,
              child: ElevatedButton(
                onPressed: state.actionLoading ? null : _submit,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: state.actionLoading
                    ? const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text('Create Task', style: GoogleFonts.lato(
                        fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
              ))),
        ])),
    );
  }
}
