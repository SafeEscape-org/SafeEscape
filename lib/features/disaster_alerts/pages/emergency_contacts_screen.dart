import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:disaster_management/features/disaster_alerts/widgets/SideNavigation/side_navigation.dart';
import 'package:disaster_management/features/disaster_alerts/constants/colors.dart';
import 'package:disaster_management/features/disaster_alerts/widgets/add_contact_form.dart';
import 'package:disaster_management/features/disaster_alerts/widgets/emergency_services_list.dart';
import 'package:disaster_management/features/disaster_alerts/widgets/contacts_list.dart';
import 'package:disaster_management/shared/widgets/app_scaffold.dart';
import 'package:disaster_management/shared/widgets/chat_assistance.dart';

class EmergencyContactsScreen extends StatefulWidget {
  const EmergencyContactsScreen({Key? key}) : super(key: key);

  @override
  State<EmergencyContactsScreen> createState() =>
      _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState extends State<EmergencyContactsScreen>
    with SingleTickerProviderStateMixin {
  final String? _userId = FirebaseAuth.instance.currentUser?.uid;
  List<Map<String, dynamic>> _contacts = [];
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _error;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fetchContacts();

    // Animation setup
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetchContacts() async {
    if (_userId == null) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final contactsJson =
          prefs.getString('emergency_contacts_$_userId') ?? '[]';
      final List<dynamic> data = json.decode(contactsJson);
      setState(() {
        _contacts = List<Map<String, dynamic>>.from(data);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load contacts: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _addContact(Map<String, String> contactData) async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final contactsJson =
          prefs.getString('emergency_contacts_$currentUserId') ?? '[]';
      final List<dynamic> existingContacts = json.decode(contactsJson);

      existingContacts.add({
        "name": contactData['name'],
        "phone": contactData['phone'],
        "relationship": contactData['relationship'] ?? ''
      });

      await prefs.setString(
        'emergency_contacts_$currentUserId',
        json.encode(existingContacts),
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Contact added successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _fetchContacts();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to add contact: ${e.toString()}';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add contact: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _removeContact(String phoneNumber) async {
    if (_userId == null) return;

    final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Remove Contact'),
            content:
                const Text('Are you sure you want to remove this contact?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child:
                    const Text('Remove', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirm) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final contactsJson =
          prefs.getString('emergency_contacts_$_userId') ?? '[]';
      final List<dynamic> existingContacts = json.decode(contactsJson);

      final updatedContacts = existingContacts
          .where((contact) => contact['phone'] != phoneNumber)
          .toList();

      await prefs.setString(
        'emergency_contacts_$_userId',
        json.encode(updatedContacts),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Contact removed successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _fetchContacts();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to remove contact: ${e.toString()}';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showAddContactForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddContactForm(
        onCancel: () => Navigator.pop(context),
        onSubmit: _addContact,
        isSubmitting: _isSubmitting,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      locationName: "Emergency Contacts",
      backgroundColor: Theme.of(context).colorScheme.background,
      drawer: const SideNavigation(userName: 'User'),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Emergency Contacts',
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: EvacuationColors.primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Quick access to your emergency contacts and services',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[700],
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                const EmergencyServicesList(),
                const SizedBox(height: 30),
                ContactsList(
                  contacts: _contacts,
                  isLoading: _isLoading,
                  isSubmitting: _isSubmitting,
                  error: _error,
                  onAddContact: _showAddContactForm,
                  onRefresh: _fetchContacts,
                  onRemoveContact: _removeContact,
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
          Positioned(
            right: 20,
            bottom: 100,
            child: ScaleTransition(
              scale: _fadeAnimation,
              child: ElevatedButton.icon(
                onPressed: _showAddContactForm,
                icon: const Icon(Icons.person_add, size: 22),
                label: const Text(
                  'Add Contact',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  backgroundColor: EvacuationColors.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 8,
                  shadowColor: EvacuationColors.primaryColor.withOpacity(0.5),
                ),
              ),
            ),
          ),
          const Positioned(
            right: 20,
            bottom: 20,
            child: ChatAssistance(),
          ),
        ],
      ),
    );
  }
}
