import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:disaster_management/features/disaster_alerts/widgets/side_navigation.dart';
import 'package:disaster_management/core/constants/api_constants.dart';
import 'package:disaster_management/features/disaster_alerts/constants/colors.dart';
// TODO: Create and import the AddContactForm widget
// import 'package:disaster_management/features/disaster_alerts/widgets/add_contact_form.dart';
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
      final response = await http.get(
        Uri.parse('http://${ApiConstants.socketServerIP}:${ApiConstants.socketServerPort}/api/users/$_userId/emergency-contact'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _contacts = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load contacts: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _addContact(Map<String, String> contactData) async {
    if (_userId == null) {
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
      // Debug the request
      print('Adding contact: $contactData');
      print('URL: http://${ApiConstants.socketServerIP}:${ApiConstants.socketServerPort}/api/users/$_userId/emergency-contact');
      
      final response = await http.post(
        Uri.parse('http://${ApiConstants.socketServerIP}:${ApiConstants.socketServerPort}/api/users/$_userId/emergency-contact'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(contactData),
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
      
      // Show error in snackbar for better visibility
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
            child: _buildAddContactForm(
              onCancel: () => Navigator.pop(context),
              onSubmit: (contactData) {
                print('Form submitted with data: $contactData');
                _addContact(contactData);
              },
            ),
          ),
        ),
      );
    }

  @override
  Widget build(BuildContext context) {
    // Get the current user's name if available
    final User? currentUser = FirebaseAuth.instance.currentUser;
    final String userName = currentUser?.displayName ?? '';
    
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
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.all(16.0),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _buildHeader(),
                      const SizedBox(height: 16),
                      _buildEmergencyServices(),
                      const SizedBox(height: 24),
                      _buildContactsSection(),
                      const SizedBox(height: 100), // Space for FAB
                    ]),
                  ),
                ),
              ],
            ),
          ),
          // Add FloatingActionButton as a positioned widget
          Positioned(
            left: 16,  // Changed from right to left
            bottom: 100,
            child: FloatingActionButton(
              onPressed: _showAddContactForm,
              backgroundColor: EvacuationColors.primaryColor,
              child: const Icon(Icons.add, color: Colors.white),
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

  Widget _buildEmergencyServices() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Emergency Services',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: EvacuationColors.textColor,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 100,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildServiceCard('Police', '100', Icons.local_police, Colors.blue),
              _buildServiceCard('Ambulance', '108', Icons.local_hospital, Colors.red),
              _buildServiceCard('Fire', '101', Icons.fire_truck, Colors.orange),
              _buildServiceCard('Women', '1091', Icons.woman, Colors.purple),
              _buildServiceCard('Child', '1098', Icons.child_care, Colors.green),
              _buildServiceCard('Disaster', '1070', Icons.emergency, Colors.brown),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildServiceCard(String title, String number, IconData icon, Color color) {
    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: EvacuationColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Handle call action
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: EvacuationColors.textColor,
                  ),
                ),
                Text(
                  number,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContactsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Your Contacts',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: EvacuationColors.textColor,
              ),
            ),
            if (_isLoading && !_isSubmitting)
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(EvacuationColors.primaryColor),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Error message
        if (_error != null)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 16),
                  onPressed: _fetchContacts,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Retry',
                ),
              ],
            ),
          ),
        
        // Contacts list
        if (_isLoading && _contacts.isEmpty && !_isSubmitting)
          _buildLoadingContacts()
        else if (_contacts.isEmpty)
          _buildEmptyContacts()
        else
          _buildContactsList(),
      ],
    );
  }

  Widget _buildLoadingContacts() {
    return Column(
      children: List.generate(
        3,
        (index) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: EvacuationColors.cardBackground,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: EvacuationColors.primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      height: 14,
                      color: Colors.grey[200],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 150,
                      height: 12,
                      color: Colors.grey[200],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyContacts() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: EvacuationColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.contact_phone_outlined,
            size: 48,
            color: EvacuationColors.subtitleColor.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No emergency contacts added yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: EvacuationColors.textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add contacts that should be notified in case of emergency',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: EvacuationColors.subtitleColor,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _showAddContactForm,
            style: ElevatedButton.styleFrom(
              backgroundColor: EvacuationColors.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Add Contact'),
          ),
        ],
      ),
    );
  }

  Widget _buildContactsList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _contacts.length,
      itemBuilder: (context, index) {
        final contact = _contacts[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: EvacuationColors.cardBackground,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: EvacuationColors.primaryColor.withOpacity(0.1),
              radius: 24,
              child: Text(
                contact['name'][0].toUpperCase(),
                style: TextStyle(
                  color: EvacuationColors.primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            title: Text(
              contact['name'],
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: EvacuationColors.textColor,
                fontSize: 16,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  contact['phone'],
                  style: TextStyle(
                    color: EvacuationColors.subtitleColor,
                    fontSize: 14,
                  ),
                ),
                Text(
                  contact['relationship'],
                  style: TextStyle(
                    fontSize: 12,
                    color: EvacuationColors.subtitleColor.withOpacity(0.7),
                  ),
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.call, color: Colors.green),
                  tooltip: 'Call contact',
                  onPressed: () {
                    // Handle call action
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  tooltip: 'Remove contact',
                  onPressed: () => _removeContact(contact['phone']),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Add this method to build the contact form
  Widget _buildAddContactForm({
    required VoidCallback onCancel,
    required Function(Map<String, String>) onSubmit,
  }) {
    final _formKey = GlobalKey<FormState>();
    final _nameController = TextEditingController();
    final _phoneController = TextEditingController();
    final _relationshipController = TextEditingController();
    
    return SingleChildScrollView(
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
                  onPressed: onCancel,
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.person),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              decoration: InputDecoration(
                labelText: 'Phone Number',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.phone),
                hintText: '+911234567890',
              ),
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a phone number';
                }
                // Basic phone validation - should start with + and have at least 10 digits
                if (!value.startsWith('+') || value.length < 11) {
                  return 'Please enter a valid phone number with country code';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _relationshipController,
              decoration: InputDecoration(
                labelText: 'Relationship',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.people),
                hintText: 'Family, Friend, etc.',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a relationship';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  // Create contact data map
                  final contactData = {
                    'name': _nameController.text.trim(),
                    'phone': _phoneController.text.trim(),
                    'relationship': _relationshipController.text.trim(),
                  };
                  
                  // Call the onSubmit callback with the contact data
                  onSubmit(contactData);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: EvacuationColors.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Add Contact'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}