import 'package:flutter/material.dart';
import 'package:disaster_management/features/disaster_alerts/constants/colors.dart';

class AddContactForm extends StatefulWidget {
  final VoidCallback onCancel;
  final Function(Map<String, String>) onSubmit;
  final bool isSubmitting;

  const AddContactForm({
    Key? key,
    required this.onCancel,
    required this.onSubmit,
    this.isSubmitting = false,
  }) : super(key: key);

  @override
  State<AddContactForm> createState() => _AddContactFormState();
}

class _AddContactFormState extends State<AddContactForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _relationshipController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _relationshipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Add Emergency Contact',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: EvacuationColors.textColor,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: widget.onCancel,
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 16),
            Focus(
              child: TextFormField(
                controller: _nameController,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: EvacuationColors.primaryColor.withOpacity(0.3)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: EvacuationColors.primaryColor.withOpacity(0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: EvacuationColors.primaryColor, width: 2),
                  ),
                  prefixIcon: const Icon(Icons.person),
                  filled: true,
                  fillColor: EvacuationColors.primaryColor.withOpacity(0.05),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 16),
            Focus(
              child: TextFormField(
                controller: _phoneController,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: EvacuationColors.primaryColor.withOpacity(0.3)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: EvacuationColors.primaryColor.withOpacity(0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: EvacuationColors.primaryColor, width: 2),
                  ),
                  prefixIcon: const Icon(Icons.phone),
                  hintText: '+911234567890',
                  filled: true,
                  fillColor: EvacuationColors.primaryColor.withOpacity(0.05),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a phone number';
                  }
                  if (!value.startsWith('+') || value.length < 11) {
                    return 'Please enter a valid phone number with country code';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 16),
            Focus(
              child: TextFormField(
                controller: _relationshipController,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  labelText: 'Relationship',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: EvacuationColors.primaryColor.withOpacity(0.3)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: EvacuationColors.primaryColor.withOpacity(0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: EvacuationColors.primaryColor, width: 2),
                  ),
                  prefixIcon: const Icon(Icons.people),
                  hintText: 'Family, Friend, etc.',
                  filled: true,
                  fillColor: EvacuationColors.primaryColor.withOpacity(0.05),
                ),
                onFieldSubmitted: (_) {
                  _submitForm();
                },
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a relationship';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: widget.isSubmitting ? null : _submitForm,
              style: ElevatedButton.styleFrom(
                backgroundColor: EvacuationColors.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 2,
              ),
              child: widget.isSubmitting
                ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text('Add Contact', style: TextStyle(fontSize: 16)),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _submitForm() {
    FocusScope.of(context).unfocus();
    
    if (_formKey.currentState!.validate()) {
      final contactData = {
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'relationship': _relationshipController.text.trim(),
      };
      
      // Debug print to verify data format
      print('Submitting contact data: $contactData');
      
      widget.onSubmit(contactData);
    }
  }
}