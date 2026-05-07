import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/models/profile.dart';
import '../../auth/providers/auth_providers.dart';

class ManageEmployeesScreen extends ConsumerStatefulWidget {
  const ManageEmployeesScreen({super.key});

  @override
  ConsumerState<ManageEmployeesScreen> createState() => _ManageEmployeesScreenState();
}

class _ManageEmployeesScreenState extends ConsumerState<ManageEmployeesScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _rateController = TextEditingController();
  bool _isLoading = false;

  Future<void> _createEmployee() async {
    if (!_formKey.currentState!.validate()) return;

    final profile = ref.read(userProfileProvider).value;
    if (profile?.organizationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: No organization found for this admin')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ref.read(authRepositoryProvider).createEmployee(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
            fullName: _fullNameController.text.trim(),
            organizationId: profile!.organizationId!,
            hourlyRateCents: (double.parse(_rateController.text) * 100).toInt(),
          );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Employee profile created successfully')),
        );
        _fullNameController.clear();
        _emailController.clear();
        _passwordController.clear();
        _rateController.clear();
        ref.invalidate(organizationEmployeesProvider);
        ref.invalidate(authRepositoryProvider);
        ref.invalidate(authStateProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create employee: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showEditDialog(Profile employee) {
    final nameCtrl = TextEditingController(text: employee.fullName);
    final rateCtrl = TextEditingController(text: (employee.hourlyRateCents / 100.0).toString());
    bool isActive = employee.isActive;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Edit ${employee.fullName}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Full Name'),
              ),
              TextField(
                controller: rateCtrl,
                decoration: const InputDecoration(labelText: 'Hourly Rate (\$)'),
                keyboardType: TextInputType.number,
              ),
              SwitchListTile(
                title: const Text('Is Active'),
                value: isActive,
                onChanged: (v) => setState(() => isActive = v),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                try {
                  await ref.read(authRepositoryProvider).updateEmployee(employee.id, {
                    'full_name': nameCtrl.text.trim(),
                    'hourly_rate_cents': (double.parse(rateCtrl.text) * 100).toInt(),
                    'is_active': isActive,
                  });
                  if (mounted) {
                    ref.invalidate(organizationEmployeesProvider);
                    Navigator.pop(context);
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final employeesAsync = ref.watch(organizationEmployeesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Employees')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Add New Employee',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _fullNameController,
                        decoration: const InputDecoration(labelText: 'Full Name'),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Required';
                          if (v.length < 2) return 'Name too short';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(labelText: 'Email Address'),
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Required';
                          final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                          if (!emailRegex.hasMatch(v)) return 'Enter a valid email';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _passwordController,
                        decoration: const InputDecoration(labelText: 'Login Password'),
                        obscureText: true,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Required';
                          if (v.length < 4) return 'Password must be at least 4 characters';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _rateController,
                        decoration: const InputDecoration(
                          labelText: 'Hourly Rate (\$)',
                          prefixText: '\$ ',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _createEmployee,
                        child: _isLoading 
                          ? const CircularProgressIndicator() 
                          : const Text('Create Employee Profile'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Existing Employees',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            employeesAsync.when(
              data: (employees) => ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: employees.length,
                itemBuilder: (context, index) {
                  final emp = employees[index];
                  return Card(
                    child: ListTile(
                      title: Text(emp.fullName),
                      subtitle: Text('${emp.email} • \$${(emp.hourlyRateCents / 100).toStringAsFixed(2)}/hr'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!emp.isActive)
                            const Padding(
                              padding: EdgeInsets.only(right: 8.0),
                              child: Chip(label: Text('Inactive', style: TextStyle(fontSize: 10))),
                            ),
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _showEditDialog(emp),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error: $e'),
            ),
          ],
        ),
      ),
    );
  }
}
