import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../core/models/supabase_to_firebase_adapter.dart';
import '../../core/theme.dart';
import '../../services/user_service.dart';
import '../../utils/helpers.dart';
import '../../widgets/animated_app_bar.dart';
import '../../widgets/loading_indicator.dart';

/// Screen for managing users (admin only)
class UserManagementScreen extends StatefulWidget {
  /// Constructor
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final UserService _userService = UserService();
  final TextEditingController _emailController = TextEditingController();
  
  List<UserModel> _users = [];
  bool _isLoading = false;
  bool _isAddingUser = false;
  String? _errorMessage;
  UserRole _selectedRole = UserRole.editor;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  /// Load all users
  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final users = await _userService.getUsers();
      if (mounted) {
        setState(() {
          _users = users;
          _isLoading = false;
        });
      }
    } catch (e) {
      logger.e('Error loading users: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load users. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  /// Show dialog to add new user
  void _showAddUserDialog() {
    _emailController.clear();
    _selectedRole = UserRole.editor;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add New User'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Error message
                if (_errorMessage != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppTheme.spacingSmall),
                    decoration: BoxDecoration(
                      color: AppTheme.errorColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(
                        AppTheme.borderRadiusMedium,
                      ),
                      border: Border.all(
                        color: AppTheme.errorColor.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.errorColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingMedium),
                ],
                
                // Email field
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    hintText: 'Enter user\'s email',
                    prefixIcon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  enabled: !_isAddingUser,
                ),
                
                const SizedBox(height: AppTheme.spacingMedium),
                
                // Role selection
                DropdownButtonFormField<UserRole>(
                  value: _selectedRole,
                  decoration: const InputDecoration(
                    labelText: 'Role',
                    prefixIcon: Icon(Icons.security),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: UserRole.admin,
                      child: Row(
                        children: [
                          const Icon(Icons.admin_panel_settings, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Admin',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text('(Full Access)'),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: UserRole.editor,
                      child: Row(
                        children: [
                          const Icon(Icons.edit, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Editor',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text('(Manage Apps Only)'),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: UserRole.viewer,
                      child: Row(
                        children: [
                          const Icon(Icons.visibility, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Viewer',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text('(View Only)'),
                        ],
                      ),
                    ),
                  ],
                  onChanged: _isAddingUser
                      ? null
                      : (value) {
                          if (value != null) {
                            setDialogState(() {
                              _selectedRole = value;
                            });
                          }
                        },
                ),
                
                const SizedBox(height: AppTheme.spacingMedium),
                
                // Info box about default password
                Builder(
                  builder: (context) {
                    final isAdmin = _selectedRole == UserRole.admin;
                    final infoMessage = isAdmin
                        ? 'The initial password will be set to "123456". The admin will be able to change it after first login.'
                        : 'A password reset link will be sent to this email address.';
                    
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppTheme.spacingSmall),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(
                          AppTheme.borderRadiusMedium,
                        ),
                        border: Border.all(
                          color: Colors.blue.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isAdmin ? Icons.vpn_key : Icons.email,
                            color: Colors.blue,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              infoMessage,
                              style: TextStyle(
                                color: Colors.blue.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: _isAddingUser
                  ? null
                  : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: _isAddingUser
                  ? null
                  : () => _addUser(
                        context,
                        setDialogState,
                      ),
              child: _isAddingUser
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('Add User'),
            ),
          ],
        ),
      ),
    );
  }

  /// Add a new user
  Future<void> _addUser(
    BuildContext context,
    StateSetter setDialogState,
  ) async {
    final email = _emailController.text.trim();
    
    // Validate email
    if (email.isEmpty || !email.contains('@')) {
      setDialogState(() {
        _errorMessage = 'Please enter a valid email address';
      });
      return;
    }
    
    setDialogState(() {
      _isAddingUser = true;
      _errorMessage = null;
    });
    
    try {
      // Add the user using the service (handles default password)
      final success = await _userService.addUser(
        email,
        _selectedRole,
        _userService.getCurrentUser()?.uid
      );
      
      if (!mounted) return;
      
      if (success) {
        // Close dialog
        Navigator.of(context).pop();
        
        // Show success message with appropriate wording
        final passwordInfo = _selectedRole == UserRole.admin 
            ? 'Initial password is "123456"' 
            : 'Password reset link sent';
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('User $email added successfully. $passwordInfo'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        
        // Reload users
        _loadUsers();
      } else {
        if (!mounted) return;
        
        setDialogState(() {
          _isAddingUser = false;
          _errorMessage = 'Failed to add user. Please try again.';
        });
      }
    } catch (e) {
      logger.e('Error adding user: $e');
      
      if (!mounted) return;
      
      String errorMessage = 'Failed to add user. Please try again.';
      
      // Extract helpful error message if possible
      if (e.toString().contains('email-already-in-use')) {
        errorMessage = 'Email is already in use.';
      } else if (e.toString().contains('invalid-email')) {
        errorMessage = 'Invalid email format.';
      }
      
      setDialogState(() {
        _isAddingUser = false;
        _errorMessage = errorMessage;
      });
    }
  }

  /// Update user role
  Future<void> _updateUserRole(UserModel user, UserRole newRole) async {
    if (user.role == newRole) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _userService.updateUserRole(user.id, newRole);
      
      if (!mounted) return;
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${user.email} updated to ${newRole.toString().split('.').last}'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Reload users
      _loadUsers();
    } catch (e) {
      logger.e('Error updating user role: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to update user role. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  /// Build user role icon
  Widget _buildRoleIcon(UserRole role) {
    IconData iconData;
    Color iconColor;
    
    switch (role) {
      case UserRole.admin:
        iconData = Icons.admin_panel_settings;
        iconColor = Colors.red;
        break;
      case UserRole.editor:
        iconData = Icons.edit;
        iconColor = Colors.green;
        break;
      case UserRole.viewer:
        iconData = Icons.visibility;
        iconColor = Colors.blue;
        break;
    }
    
    return Icon(
      iconData,
      color: iconColor,
      size: 20,
    );
  }

  /// Build user list item
  Widget _buildUserListItem(UserModel user) {
    final currentUser = _userService.getCurrentUser();
    final isCurrentUser = currentUser?.email == user.email;
    
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingLarge,
        vertical: AppTheme.spacingSmall,
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: _buildRoleIcon(user.role),
        ),
        title: Text(
          user.email,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          user.role.toString().split('.').last.toUpperCase(),
        ),
        trailing: isCurrentUser
            ? const Chip(
                label: Text('You'),
                backgroundColor: Colors.grey,
                labelStyle: TextStyle(color: Colors.white),
              )
            : PopupMenuButton<UserRole>(
                icon: const Icon(Icons.more_vert),
                onSelected: (role) => _updateUserRole(user, role),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: UserRole.admin,
                    child: Row(
                      children: [
                        Icon(
                          Icons.admin_panel_settings,
                          color: user.role == UserRole.admin
                              ? Colors.grey
                              : Colors.red,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Set as Admin',
                          style: TextStyle(
                            color: user.role == UserRole.admin
                                ? Colors.grey
                                : null,
                          ),
                        ),
                      ],
                    ),
                    enabled: user.role != UserRole.admin,
                  ),
                  PopupMenuItem(
                    value: UserRole.editor,
                    child: Row(
                      children: [
                        Icon(
                          Icons.edit,
                          color: user.role == UserRole.editor
                              ? Colors.grey
                              : Colors.green,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Set as Editor',
                          style: TextStyle(
                            color: user.role == UserRole.editor
                                ? Colors.grey
                                : null,
                          ),
                        ),
                      ],
                    ),
                    enabled: user.role != UserRole.editor,
                  ),
                  PopupMenuItem(
                    value: UserRole.viewer,
                    child: Row(
                      children: [
                        Icon(
                          Icons.visibility,
                          color: user.role == UserRole.viewer
                              ? Colors.grey
                              : Colors.blue,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Set as Viewer',
                          style: TextStyle(
                            color: user.role == UserRole.viewer
                                ? Colors.grey
                                : null,
                          ),
                        ),
                      ],
                    ),
                    enabled: user.role != UserRole.viewer,
                  ),
                ],
              ),
      )
      .animate()
      .fadeIn(
        duration: AppTheme.shortAnimationDuration,
      )
      .slideX(
        begin: -0.1,
        end: 0,
        duration: AppTheme.shortAnimationDuration,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AnimatedAppBar(
        title: 'User Management',
        actions: [
          // Add user button
          IconButton(
            icon: const Icon(Icons.person_add),
            tooltip: 'Add User',
            onPressed: _isLoading ? null : _showAddUserDialog,
          ),
          
          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _isLoading ? null : _loadUsers,
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingIndicator(
              message: 'Loading users...',
              useScaffold: true,
            )
          : Column(
              children: [
                // Info banner about user roles
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(AppTheme.spacingMedium),
                  padding: const EdgeInsets.all(AppTheme.spacingMedium),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(
                      AppTheme.borderRadiusMedium,
                    ),
                    border: Border.all(
                      color: Colors.blue.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.blue,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'User Role Permissions',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildRoleIcon(UserRole.admin),
                          const SizedBox(width: 8),
                          const Text(
                            'Admin: ',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const Expanded(
                            child: Text('Full access including user management'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _buildRoleIcon(UserRole.editor),
                          const SizedBox(width: 8),
                          const Text(
                            'Editor: ',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const Expanded(
                            child: Text('Can manage apps but not users'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _buildRoleIcon(UserRole.viewer),
                          const SizedBox(width: 8),
                          const Text(
                            'Viewer: ',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const Expanded(
                            child: Text('View-only access'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Error message
                if (_errorMessage != null) ...[
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingLarge,
                      vertical: AppTheme.spacingSmall,
                    ),
                    padding: const EdgeInsets.all(AppTheme.spacingMedium),
                    decoration: BoxDecoration(
                      color: AppTheme.errorColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(
                        AppTheme.borderRadiusMedium,
                      ),
                      border: Border.all(
                        color: AppTheme.errorColor.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: AppTheme.errorColor,
                        ),
                        const SizedBox(width: AppTheme.spacingSmall),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.errorColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                  .animate()
                  .fadeIn(duration: AppTheme.shortAnimationDuration)
                  .shake(),
                ],
                
                // User list
                Expanded(
                  child: _users.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.people_outline,
                                size: 64,
                                color: Colors.grey,
                              ),
                              const SizedBox(height: AppTheme.spacingMedium),
                              Text(
                                'No users found',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: AppTheme.spacingSmall),
                              const Text(
                                'Tap the + button to add a user',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _users.length,
                          itemBuilder: (context, index) {
                            return _buildUserListItem(_users[index]);
                          },
                        ),
                ),
              ],
            ),
    );
  }
} 