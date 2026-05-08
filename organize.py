import os
import shutil

lib = r'C:\Users\Alumnos\Documents\Eduardo\quickinvent-main\lib'

# Definir la estructura de carpetas
structure = {
    'models': ['product.dart', 'category.dart', 'cart_item.dart', 'sale.dart', 'sale_detail_item.dart', 'product_return.dart', 'category_sale.dart'],
    'repositories': ['products_repository.dart', 'sales_repository.dart', 'auth_repository.dart'],
    'providers': ['products_provider.dart', 'cart_notifier.dart', 'held_carts_notifier.dart', 'suspended_sales_provider.dart', 'theme_notifier.dart', 'theme_provider.dart'],
    'screens': ['main_screen.dart', 'pos_screen.dart', 'inventory_screen.dart', 'sales_history_screen.dart', 'sale_detail_screen.dart', 'sale_completion_screen.dart', 'reports_screen.dart', 'dead_stock_report_screen.dart', 'returns_screen.dart', 'profile_screen.dart', 'settings_screen.dart', 'login_screen.dart', 'register_screen.dart', 'category_management_screen.dart', 'add_product_screen.dart'],
    'dialogs': ['add_product_dialog.dart', 'edit_product_dialog.dart', 'checkout_dialog.dart', 'new_return_dialog.dart', 'held_carts_dialog.dart'],
    'widgets': ['app_shell.dart', 'app_sidebar.dart', 'low_stock_banner.dart', 'image_picker_widget.dart', 'receipt_generator.dart', 'auth_gate.dart', 'dashboard_stats.dart'],
    'theme': ['app_theme.dart'],
}

# Archivos que se quedan en la raíz
root_files = ['main.dart']

# 1. Crear carpetas
for folder in structure.keys():
    folder_path = os.path.join(lib, folder)
    os.makedirs(folder_path, exist_ok=True)
    print(f"Created: {folder}/")

# 2. Construir mapeo: archivo -> carpeta
file_to_folder = {}
for folder, files in structure.items():
    for f in files:
        file_to_folder[f] = folder

# 3. Mover archivos
for folder, files in structure.items():
    for f in files:
        src = os.path.join(lib, f)
        dst = os.path.join(lib, folder, f)
        if os.path.exists(src):
            shutil.move(src, dst)
            print(f"Moved: {f} -> {folder}/")

# 4. Actualizar imports en todos los archivos .dart
def get_relative_path(from_file, to_file):
    """Calcula la ruta relativa entre dos archivos en lib/"""
    from_folder = file_to_folder.get(from_file, '')
    to_folder = file_to_folder.get(to_file, '')
    
    if from_folder == to_folder:
        return f'./{to_file}' if from_folder else to_file
    
    if from_folder and to_folder:
        return f'../{to_folder}/{to_file}'
    elif from_folder:
        return f'../{to_file}'
    elif to_folder:
        return f'./{to_folder}/{to_file}'
    else:
        return to_file

# Procesar cada archivo
all_dart_files = []
for root, dirs, files in os.walk(lib):
    for f in files:
        if f.endswith('.dart'):
            all_dart_files.append(os.path.relpath(os.path.join(root, f), lib).replace('\\', '/'))

for rel_path in all_dart_files:
    file_path = os.path.join(lib, rel_path)
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    original_content = content
    
    # Obtener el nombre del archivo actual (sin carpeta)
    current_file = os.path.basename(rel_path)
    
    # Reemplazar imports que referencian archivos movidos
    for imported_file, imported_folder in file_to_folder.items():
        # Patrón: import 'archivo.dart';
        old_import = f"import '{imported_file}';"
        if old_import in content:
            new_path = get_relative_path(current_file, imported_file)
            # Quitar ./ al inicio para consistencia con el estilo del proyecto
            if new_path.startswith('./'):
                new_path = new_path[2:]
            new_import = f"import '{new_path}';"
            content = content.replace(old_import, new_import)
    
    if content != original_content:
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Updated imports: {rel_path}")

print("\nOrganization complete!")
