import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:disaster_management/features/disaster_alerts/widgets/side_navigation.dart';
import 'package:disaster_management/core/constants/api_constants.dart';
import 'package:disaster_management/features/disaster_alerts/constants/colors.dart';
import 'package:disaster_management/features/disaster_alerts/widgets/add_contact_form.dart';
import 'package:disaster_management/features/disaster_alerts/widgets/emergency_services_list.dart';
import 'package:disaster_management/features/disaster_alerts/widgets/contacts_list.dart';
import 'package:disaster_management/shared/widgets/app_scaffold.dart';
import 'package:disaster_management/shared/widgets/chat_assistance.dart';

class EmergencyContactsScreen extends StatefulWidget {
  const EmergencyContactsScreen({Key? key}) : super(key: key);

  @override
  State<EmergencyContactsScreen> createState() => _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState extends State<EmergencyContactsScreen> {
  final String? _userId = FirebaseAuth.instance.currentUser?.uid;
  List<Map<String, dynamic>> _contacts = [];
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchContacts();
  }

  Future<void> _fetchContacts() async {
    if (_userId == null) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Changed from POST to GET request
      final response = await http.get(
        Uri.parse('http://${ApiConstants.socketServerIP}:${ApiConstants.socketServerPort}/api/users/$_userId/emergency-contact'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      print('Fetch contacts response status: ${response.statusCode}');
      print('Fetch contacts response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _contacts = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load contacts: ${response.statusCode} - ${response.body}';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching contacts: $e');
      setState(() {
        _error = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _addContact(Map<String, String> contactData) async {
    // Get the current user ID
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    
    if (currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User not logged in'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      // Print debug information
      print('Adding contact for user: $currentUserId');
      print('Contact data: ${json.encode(contactData)}');
      
      // Format the data exactly as expected by the API
      final formattedData = {
        "name": contactData['name'],
        "phone": contactData['phone'],
        "relationship": contactData['relationship']
      };
      
      // Use the current user ID from Firebase
      final response = await http.post(
        Uri.parse('http://${ApiConstants.socketServerIP}:${ApiConstants.socketServerPort}/api/users/$currentUserId/emergency-contact'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(formattedData),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        // Close the bottom sheet if it's still open
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
        
        // Refresh contacts
        _fetchContacts();
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Contact added successfully'),
            backgroundColor: Colors.green,
          ),
        );
        
        setState(() {
          _isSubmitting = false;
        });
      } else {
        setState(() {
          _error = 'Failed to add contact: ${response.statusCode} - ${response.body}';
          _isSubmitting = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add contact: ${response.statusCode}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error adding contact: $e');
      setState(() {
        _error = 'Error adding contact: $e';
        _isSubmitting = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add contact: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _removeContact(String phoneNumber) async {
    if (_userId == null) return;

    // Show confirmation dialog
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Contact'),
        content: const Text('Are you sure you want to remove this contact?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    ) ?? false;
    
    if (!confirm) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // URL encode the phone number to handle special characters like +
      final encodedPhone = Uri.encodeComponent(phoneNumber);
      
      final response = await http.delete(
        Uri.parse('http://${ApiConstants.socketServerIP}:${ApiConstants.socketServerPort}/api/users/$_userId/emergency-contact/$encodedPhone'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        _fetchContacts();
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Contact removed successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() {
          _error = 'Failed to remove contact: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error removing contact: $e';
        _isLoading = false;
      });
    }
  }

  void _showAddContactForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: EvacuationColors.backgroundColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: AddContactForm(
            isSubmitting: _isSubmitting,
            onCancel: () => Navigator.pop(context),
            onSubmit: (contactData) {
              // Validate data before submission
              print('Form data before submission: $contactData');
              if (contactData['name']?.isEmpty ?? true) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Name cannot be empty'), backgroundColor: Colors.red)
                );
                return;
              }
              if (contactData['phone']?.isEmpty ?? true) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Phone cannot be empty'), backgroundColor: Colors.red)
                );
                return;
              }
              _addContact(contactData);
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      locationName: "Emergency Contacts",
      backgroundColor: EvacuationColors.backgroundColor,
      drawer: const SideNavigation(userName: 'User'),  // Use a constant value for now
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _fetchContacts,
            color: EvacuationColors.primaryColor,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.all(20.0),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _buildHeader(),
                      const SizedBox(height: 20),
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
                      const SizedBox(height: 100), // Space for FAB
                    ]),
                  ),
                ),
              ],
            ),
          ),
          // Add FloatingActionButton as a positioned widget
          Positioned(
            left: 20,
            bottom: 100,
            child: Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: EvacuationColors.primaryColor.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: FloatingActionButton(
                onPressed: _showAddContactForm,
                backgroundColor: EvacuationColors.primaryColor,
                child: const Icon(Icons.add, color: Colors.white),
              ),
            ),
          ),
          // Add the ChatAssistance widget
          const Positioned(
            right: 16,
            bottom: 24,
            child: ChatAssistance(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Emergency Contacts',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: EvacuationColors.textColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Add your emergency contacts for quick access during emergencies',
          style: TextStyle(
            fontSize: 14,
            color: EvacuationColors.subtitleColor,
          ),
        ),
      ],
    );
  }
}