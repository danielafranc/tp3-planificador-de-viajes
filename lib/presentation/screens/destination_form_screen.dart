import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/services/image_upload_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/app_text_field.dart';
import '../../domain/destination.dart';
import '../providers/destination_provider.dart';

class DestinationFormScreen extends ConsumerStatefulWidget {
  static const String createName = 'destination_form_create_screen';
  static const String editName = 'destination_form_edit_screen';

  final Destination? initialDestination;

  const DestinationFormScreen({
    super.key,
    this.initialDestination,
  });

  @override
  ConsumerState<DestinationFormScreen> createState() =>
      _DestinationFormScreenState();
}

class _DestinationFormScreenState extends ConsumerState<DestinationFormScreen> {
  final nameController = TextEditingController();
  final provinceController = TextEditingController();
  final descriptionController = TextEditingController();
  final imageUrlController = TextEditingController();
  final priceController = TextEditingController();

  bool isSaving = false;
  bool isFeatured = false;
  bool isTouristic = true;
  
  bool isUploadingImage = false;
  XFile? selectedImage;
  final imagePicker = ImagePicker();
  final imageUploadService = ImageUploadService();

  final Set<String> selectedTransports = {'bus'};

  bool get isEditMode => widget.initialDestination != null;

  @override
  void initState() {
    super.initState();

    final destination = widget.initialDestination;

    if (destination != null) {
      nameController.text = destination.name;
      provinceController.text = destination.province;
      descriptionController.text = destination.description;
      imageUrlController.text = destination.imageUrl;
      priceController.text = destination.priceFromUsd.toStringAsFixed(0);

      isFeatured = destination.isFeatured;
      isTouristic = destination.isTouristic;

      selectedTransports
        ..clear()
        ..addAll(destination.availableTransports);
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    provinceController.dispose();
    descriptionController.dispose();
    imageUrlController.dispose();
    priceController.dispose();
    super.dispose();
  }

  String buildDestinationId(String name) {
    return name
        .trim()
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ñ', 'n')
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
  }

  Future<void> pickAndUploadImage() async {
  try {
    final image = await imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (image == null) {
      return;
    }

    setState(() {
      selectedImage = image;
      isUploadingImage = true;
    });

    final imageUrl = await imageUploadService.uploadImage(image);

    if (!mounted) {
      return;
    }

    setState(() {
      imageUrlController.text = imageUrl;
      isUploadingImage = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Imagen subida correctamente.')),
    );
  } catch (e) {
    if (!mounted) {
      return;
    }

    setState(() {
      isUploadingImage = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No se pudo subir la imagen.')),
    );
  }
}

  Future<void> saveDestination() async {
    final name = nameController.text.trim();
    final province = provinceController.text.trim();
    final description = descriptionController.text.trim();
    final imageUrl = imageUrlController.text.trim();
    final priceText = priceController.text.trim();

    if (name.isEmpty ||
        province.isEmpty ||
        description.isEmpty ||
        imageUrl.isEmpty ||
        priceText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completá todos los campos.')),
      );
      return;
    }

    final price = double.tryParse(priceText.replaceAll(',', '.'));

    if (price == null || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresá un precio válido.')),
      );
      return;
    }

    if (selectedTransports.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleccioná al menos un transporte.')),
      );
      return;
    }

    final id = isEditMode
        ? widget.initialDestination!.id
        : buildDestinationId(name);

    if (id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El nombre del destino no es válido.')),
      );
      return;
    }

    final destination = Destination(
      id: id,
      name: name,
      province: province,
      description: description,
      imageUrl: imageUrl,
      priceFromUsd: price,
      isFeatured: isFeatured,
      isTouristic: isTouristic,
      availableTransports: selectedTransports.toList(),
    );

    setState(() {
      isSaving = true;
    });

    try {
      if (isEditMode) {
        await ref.read(destinationProvider.notifier).updateDestination(
              destination,
            );
      } else {
        await ref.read(destinationProvider.notifier).createDestination(
              destination,
            );
      }

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEditMode
                ? 'Destino actualizado correctamente.'
                : 'Destino creado correctamente.',
          ),
        ),
      );

      context.pop();
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEditMode
                ? 'No se pudo actualizar el destino.'
                : 'No se pudo crear el destino.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  void toggleTransport(String transport, bool selected) {
    setState(() {
      if (selected) {
        selectedTransports.add(transport);
      } else {
        selectedTransports.remove(transport);
      }
    });
  }

  Widget imagePreview() {
    final imageUrl = imageUrlController.text.trim();

    if (imageUrl.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          imageUrl,
          height: 150,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              height: 150,
              width: double.infinity,
              color: AppColors.blueCard,
              alignment: Alignment.center,
              child: const Text(
                'No se pudo cargar la imagen',
                style: TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pearl,
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        foregroundColor: AppColors.white,
        title: Text(isEditMode ? 'Editar destino' : 'Nuevo destino'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            AppTextField(
              label: 'Nombre',
              hint: 'Ej: Bariloche',
              controller: nameController,
            ),
            const SizedBox(height: 14),
            AppTextField(
              label: 'Provincia',
              hint: 'Ej: Río Negro',
              controller: provinceController,
            ),
            const SizedBox(height: 14),
            AppTextField(
              label: 'Descripción',
              hint: 'Descripción breve del destino',
              controller: descriptionController,
            ),
            const SizedBox(height: 14),
            AppTextField(
              label: 'URL de imagen',
              hint: 'Se completa automáticamente al subir imagen',
              controller: imageUrlController,
              keyboardType: TextInputType.url,
              suffixIcon: IconButton(
                tooltip: 'Actualizar vista previa',
                onPressed: () {
                  setState(() {});
                },
                icon: const Icon(Icons.refresh),
              ),
            ),
            const SizedBox(height: 10),
            AppSecondaryButton(
              text: isUploadingImage ? 'Subiendo imagen...' : 'Seleccionar imagen',
              onPressed: isUploadingImage ? null : pickAndUploadImage,
              leading: const Icon(Icons.image_outlined, size: 18),
            ),
            imagePreview(),
            const SizedBox(height: 14),
            AppTextField(
              label: 'Precio desde USD',
              hint: 'Ej: 420',
              controller: priceController,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 18),
            SwitchListTile(
              value: isFeatured,
              activeThumbColor: AppColors.navy,
              title: const Text(
                'Destino destacado',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: const Text('Si está activo aparece en el carrusel.'),
              onChanged: (value) {
                setState(() {
                  isFeatured = value;
                });
              },
            ),
            SwitchListTile(
              value: isTouristic,
              activeThumbColor: AppColors.navy,
              title: const Text(
                'Destino turístico',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              onChanged: (value) {
                setState(() {
                  isTouristic = value;
                });
              },
            ),
            const SizedBox(height: 8),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Transportes disponibles',
                style: TextStyle(
                  color: AppColors.black,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 8),
            CheckboxListTile(
              value: selectedTransports.contains('plane'),
              activeColor: AppColors.navy,
              title: const Text('Avión'),
              onChanged: (value) {
                toggleTransport('plane', value ?? false);
              },
            ),
            CheckboxListTile(
              value: selectedTransports.contains('bus'),
              activeColor: AppColors.navy,
              title: const Text('Micro'),
              onChanged: (value) {
                toggleTransport('bus', value ?? false);
              },
            ),
            CheckboxListTile(
              value: selectedTransports.contains('car'),
              activeColor: AppColors.navy,
              title: const Text('Auto'),
              onChanged: (value) {
                toggleTransport('car', value ?? false);
              },
            ),
            const SizedBox(height: 18),
            AppPrimaryButton(
              text: isSaving
                  ? 'Guardando...'
                  : isEditMode
                      ? 'Guardar cambios'
                      : 'Guardar destino',
              onPressed: isSaving ? null : saveDestination,
            ),
          ],
        ),
      ),
    );
  }
}