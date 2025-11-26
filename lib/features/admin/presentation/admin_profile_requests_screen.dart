import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cleardish/core/utils/result.dart';
import 'package:cleardish/data/models/profile_change_request.dart';
import 'package:cleardish/data/repositories/profile_change_request_repo.dart';
import 'package:cleardish/data/sources/supabase_client.dart';

final pendingProfileRequestsProvider =
    FutureProvider.autoDispose<List<ProfileChangeRequest>>((ref) async {
  final repo = ref.watch(profileChangeRequestRepoProvider);
  final result = await repo.getPendingRequests();
  if (result.isFailure) {
    throw Exception(result.errorOrNull ?? 'Unknown error');
  }
  return result.dataOrNull ?? const [];
});

class AdminProfileRequestsScreen extends ConsumerWidget {
  const AdminProfileRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(pendingProfileRequestsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Allergen & Diet Approvals')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: requestsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Text('Failed to load requests: $e'),
          ),
          data: (requests) {
            if (requests.isEmpty) {
              return const Center(
                child: Text('No pending requests 🎉'),
              );
            }
            return ListView.separated(
              itemCount: requests.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, index) {
                return _RequestCard(request: requests[index]);
              },
            );
          },
        ),
      ),
    );
  }
}

class _RequestCard extends ConsumerWidget {
  const _RequestCard({required this.request});
  final ProfileChangeRequest request;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subtitle = [
      'Type: ${request.type.label}',
      'Requested: ${_formatDateTime(request.requestedAt)}',
    ].join('  •  ');

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.person_outline),
              title: Text(
                request.userNameSnapshot ??
                    request.userEmailSnapshot ??
                    request.userId,
              ),
              subtitle: Text(subtitle),
            ),
            const SizedBox(height: 8),
            Text(
              'Requested values',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            if (request.requestedValues.isEmpty)
              Text(
                'Clear all selections',
                style: Theme.of(context).textTheme.bodyMedium,
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: request.requestedValues
                    .map(
                      (value) => Chip(
                        label: Text(value),
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.12),
                      ),
                    )
                    .toList(),
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () =>
                        _handleApprove(context, ref, request, null),
                    icon: const Icon(Icons.check),
                    label: const Text('Approve'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _handleReject(context, ref, request),
                    icon: const Icon(Icons.close),
                    label: const Text('Reject'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleApprove(
    BuildContext context,
    WidgetRef ref,
    ProfileChangeRequest request,
    String? note,
  ) async {
    final adminId = SupabaseClient.instance.auth.currentUser?.id;
    if (adminId == null) {
      _showSnack(context, 'Admin auth missing', isError: true);
      return;
    }
    final repo = ref.read(profileChangeRequestRepoProvider);
    final result = await repo.approveRequest(
      requestId: request.id,
      adminId: adminId,
      adminNote: note,
    );
    if (result.isFailure) {
      _showSnack(
        context,
        result.errorOrNull ?? 'Failed to approve request',
        isError: true,
      );
      return;
    }
    ref.invalidate(pendingProfileRequestsProvider);
    _showSnack(context, 'Request approved');
  }

  Future<void> _handleReject(
    BuildContext context,
    WidgetRef ref,
    ProfileChangeRequest request,
  ) async {
    final adminId = SupabaseClient.instance.auth.currentUser?.id;
    if (adminId == null) {
      _showSnack(context, 'Admin auth missing', isError: true);
      return;
    }
    final note = await _askForNote(context);
    if (note == null) return;

    final repo = ref.read(profileChangeRequestRepoProvider);
    final result = await repo.rejectRequest(
      requestId: request.id,
      adminId: adminId,
      adminNote: note.isEmpty ? null : note,
    );
    if (result.isFailure) {
      _showSnack(
        context,
        result.errorOrNull ?? 'Failed to reject request',
        isError: true,
      );
      return;
    }
    ref.invalidate(pendingProfileRequestsProvider);
    _showSnack(context, 'Request rejected');
  }

  Future<String?> _askForNote(BuildContext context) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject request'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Reason (optional)',
          ),
          minLines: 1,
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  void _showSnack(BuildContext context, String message,
      {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final local = dateTime.toLocal();
    final date =
        '${local.day.toString().padLeft(2, '0')}.${local.month.toString().padLeft(2, '0')}.${local.year}';
    final time =
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
    return '$date $time';
  }
}
