import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/site_task_models.dart';
import '../bloc/home_bloc.dart';

class CreateSiteBottomSheet extends StatefulWidget {
  const CreateSiteBottomSheet({super.key});
  @override State<CreateSiteBottomSheet> createState() => _CreateSiteBottomSheetState();
}

class _CreateSiteBottomSheetState extends State<CreateSiteBottomSheet> {
  final _formKey  = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _locCtrl  = TextEditingController();
  final _descCtrl = TextEditingController();

  @override
  void dispose() { _nameCtrl.dispose(); _locCtrl.dispose(); _descCtrl.dispose(); super.dispose(); }

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
    context.read<HomeBloc>().add(HomeSiteCreateRequested(CreateSiteRequest(
      name: _nameCtrl.text.trim(), location: _locCtrl.text.trim(),
      description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim())));
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
          Text('Create new site', style: GoogleFonts.playfairDisplay(
              fontSize: 18, color: AppColors.textPrimary)),
          const SizedBox(height: 20),
          TextFormField(controller: _nameCtrl, textInputAction: TextInputAction.next,
            decoration: _dec('Site name', 'e.g. Pune Highway Block A', Icons.location_city_outlined),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Site name is required' : null),
          const SizedBox(height: 12),
          TextFormField(controller: _locCtrl, textInputAction: TextInputAction.next,
            decoration: _dec('Location', 'e.g. Pune, Maharashtra', Icons.place_outlined),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Location is required' : null),
          const SizedBox(height: 12),
          TextFormField(controller: _descCtrl, maxLines: 2,
            textInputAction: TextInputAction.done,
            decoration: _dec('Description (optional)', 'Any notes...', Icons.notes_outlined)),
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
                    : Text('Create Site', style: GoogleFonts.lato(
                        fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
              ))),
        ])),
    );
  }
}
