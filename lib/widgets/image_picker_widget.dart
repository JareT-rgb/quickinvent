import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

class ImagePickerWidget extends StatefulWidget {
  final String? initialImageUrl;
  final XFile? initialImageFile;
  final Function(XFile? imageFile, String? imageUrl) onImageChanged;
  final double height;
  final double width;
  final BoxShape shape;

  const ImagePickerWidget({
    super.key,
    this.initialImageUrl,
    this.initialImageFile,
    required this.onImageChanged,
    this.height = 150,
    this.width = 150,
    this.shape = BoxShape.rectangle,
  });

  @override
  State<ImagePickerWidget> createState() => _ImagePickerWidgetState();
}

class _ImagePickerWidgetState extends State<ImagePickerWidget> {
  XFile? _selectedImage;
  String? _imageUrl;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedImage = widget.initialImageFile;
    _imageUrl = widget.initialImageUrl;
  }

  Future<void> _pickImage(ImageSource source) async {
    setState(() => _isLoading = true);
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = pickedFile;
          _imageUrl = null;
        });
        widget.onImageChanged(pickedFile, null);
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al seleccionar imagen: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
      _imageUrl = null;
    });
    widget.onImageChanged(null, null);
  }

  void _showImageSourceOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[300]?.withValues(alpha: 1.0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text(
                'Seleccionar imagen',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.camera_alt, color: Colors.blue),
                ),
                title: const Text('Cámara'),
                subtitle: const Text('Tomar una foto'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.photo_library, color: Colors.green),
                ),
                title: const Text('Galería'),
                subtitle: const Text('Elegir de la galería'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              if (_selectedImage != null || _imageUrl != null) ...[
                const SizedBox(height: 8),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.delete, color: Colors.red),
                  ),
                  title: const Text('Eliminar imagen'),
                  titleTextStyle: const TextStyle(color: Colors.red),
                  onTap: () {
                    Navigator.pop(context);
                    _removeImage();
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasImage = _selectedImage != null || _imageUrl != null;

    Widget imageWidget;
    if (_selectedImage != null) {
      if (kIsWeb) {
        // On web, Image.file throws an error. XFile.path contains a blob URL.
        imageWidget = Image.network(
          _selectedImage!.path,
          fit: BoxFit.cover,
          width: widget.width,
          height: widget.height,
        );
      } else {
        imageWidget = Image.file(
          File(_selectedImage!.path),
          fit: BoxFit.cover,
          width: widget.width,
          height: widget.height,
        );
      }
    } else if (_imageUrl != null) {
      imageWidget = Image.network(
        _imageUrl!,
        fit: BoxFit.cover,
        width: widget.width,
        height: widget.height,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                  : null,
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(theme),
      );
    } else {
      imageWidget = _buildPlaceholder(theme);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: _isLoading ? null : _showImageSourceOptions,
          child: Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              shape: widget.shape,
              borderRadius: widget.shape == BoxShape.rectangle
                  ? BorderRadius.circular(16)
                  : null,
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.3),
                width: 2,
              ),
              boxShadow: hasImage
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                imageWidget,
                if (_isLoading)
                  Container(
                    color: Colors.black.withValues(alpha: 0.3),
                    child: const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  ),
                if (!_isLoading)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.6),
                          ],
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            hasImage ? Icons.edit : Icons.add_a_photo,
                            color: Colors.white,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              hasImage ? 'Cambiar' : 'Agregar',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholder(ThemeData theme) {
    return Container(
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
      child: Center(
        child: FittedBox(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_photo_alternate_outlined,
                  size: 40,
                  color: theme.colorScheme.primary.withValues(alpha: 0.4),
                ),
                const SizedBox(height: 4),
                Text(
                  'SIN IMAGEN',
                  style: TextStyle(
                    color: theme.colorScheme.primary.withValues(alpha: 0.5),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
