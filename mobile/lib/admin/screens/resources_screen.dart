import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/loading_error.dart';
import '../providers/admin_providers.dart';
import '../services/admin_service.dart';
import '../models/admin_models.dart';

class ResourcesScreen extends ConsumerWidget {
  const ResourcesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resourcesAsync = ref.watch(adminResourcesProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(adminResourcesProvider),
      child: resourcesAsync.when(
        loading: () => const LoadingState(message: 'Loading resources…'),
        error: (e, _) => ErrorState(
            message: 'Failed to load resources',
            onRetry: () => ref.invalidate(adminResourcesProvider)),
        data: (result) => result.data.isEmpty
            ? const EmptyState(
                message: 'No resources yet.',
                icon: Icons.folder_open_outlined)
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: result.data.length,
                itemBuilder: (_, i) => _ResourceTile(
                  resource: result.data[i],
                  onDelete: () => _confirmDelete(context, ref, result.data[i]),
                ),
              ),
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, AdminResourceItem r) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Resource?'),
        content: Text('Delete "${r.title}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error),
              child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await AdminService.deleteResource(r.id);
      ref.invalidate(adminResourcesProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
}

class _ResourceTile extends StatelessWidget {
  final AdminResourceItem resource;
  final VoidCallback onDelete;
  const _ResourceTile({required this.resource, required this.onDelete});

  static IconData _iconFor(String? type) {
    if (type == null) return Icons.insert_drive_file_outlined;
    if (type.contains('pdf')) return Icons.picture_as_pdf_outlined;
    if (type.contains('image')) return Icons.image_outlined;
    if (type.contains('video')) return Icons.videocam_outlined;
    return Icons.insert_drive_file_outlined;
  }

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 6)],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(_iconFor(resource.fileType),
                  color: AppColors.primary, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(resource.title,
                      style:
                          const TextStyle(fontWeight: FontWeight.w600)),
                  if (resource.subjectName != null)
                    Text(resource.subjectName!,
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 11)),
                  if (resource.fileSize != null)
                    Text(_formatSize(resource.fileSize!),
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 11)),
                ],
              ),
            ),
            IconButton(
                icon: const Icon(Icons.delete_outline,
                    size: 18, color: AppColors.error),
                onPressed: onDelete),
          ],
        ),
      );

  String _formatSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1048576) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / 1048576).toStringAsFixed(1)}MB';
  }
}

// ─── Upload dialog ─────────────────────────────────────────────────────────────

class ResourceUploadDialog extends ConsumerStatefulWidget {
  const ResourceUploadDialog({super.key});

  @override
  ConsumerState<ResourceUploadDialog> createState() =>
      _ResourceUploadDialogState();
}

class _ResourceUploadDialogState
    extends ConsumerState<ResourceUploadDialog> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _urlCtrl = TextEditingController();

  int? _subjectId;
  String? _filePath;
  String? _fileName;
  bool _uploading = false;
  bool _useFile = true;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _urlCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final subjectsAsync = ref.watch(adminSubjectsProvider);

    return AlertDialog(
      title: const Text('Upload Resource'),
      content: SizedBox(
        width: 340,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                    labelText: 'Title *', isDense: true),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _descCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                    labelText: 'Description', isDense: true),
              ),
              const SizedBox(height: 10),
              subjectsAsync.maybeWhen(
                data: (subjects) => DropdownButtonFormField<int>(
                  value: _subjectId,
                  decoration: const InputDecoration(
                      labelText: 'Subject', isDense: true),
                  items: [
                    const DropdownMenuItem(
                        value: null, child: Text('None')),
                    ...subjects.map((s) =>
                        DropdownMenuItem(value: s.id, child: Text(s.name))),
                  ],
                  onChanged: (v) => setState(() => _subjectId = v),
                ),
                orElse: () => const SizedBox.shrink(),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  ChoiceChip(
                    label: const Text('File'),
                    selected: _useFile,
                    onSelected: (_) => setState(() => _useFile = true),
                    selectedColor: AppColors.primaryLight,
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('URL'),
                    selected: !_useFile,
                    onSelected: (_) => setState(() => _useFile = false),
                    selectedColor: AppColors.primaryLight,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (_useFile) ...[
                OutlinedButton.icon(
                  onPressed: _pickFile,
                  icon: const Icon(Icons.attach_file, size: 16),
                  label:
                      Text(_fileName ?? 'Choose file'),
                ),
              ] else ...[
                TextField(
                  controller: _urlCtrl,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                      labelText: 'URL *', isDense: true),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _uploading ? null : _upload,
          style: ElevatedButton.styleFrom(minimumSize: const Size(80, 36)),
          child: _uploading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Text('Upload'),
        ),
      ],
    );
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.single.path != null) {
      setState(() {
        _filePath = result.files.single.path;
        _fileName = result.files.single.name;
      });
    }
  }

  Future<void> _upload() async {
    if (_titleCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter a title.')));
      return;
    }
    if (_useFile && _filePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Choose a file.')));
      return;
    }
    if (!_useFile && _urlCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter a URL.')));
      return;
    }

    setState(() => _uploading = true);
    try {
      await AdminService.uploadResource(
        title: _titleCtrl.text,
        description:
            _descCtrl.text.isEmpty ? null : _descCtrl.text,
        subjectId: _subjectId,
        filePath: _useFile ? _filePath : null,
        fileName: _useFile ? _fileName : null,
        url: !_useFile ? _urlCtrl.text : null,
      );
      ref.invalidate(adminResourcesProvider);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }
}
