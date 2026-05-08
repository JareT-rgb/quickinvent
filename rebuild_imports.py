import os
import re

lib = r'C:\Users\Alumnos\Documents\Eduardo\quickinvent-main\lib'

# Mapeo: nombre de símbolo -> archivo donde se define
symbol_to_file = {}

# Primero pasada: encontrar todas las definiciones de clases, funciones, providers, etc.
for f in sorted(os.listdir(lib)):
    if not f.endswith('.dart') or f == 'main.dart':
        continue
    path = os.path.join(lib, f)
    with open(path, 'r', encoding='utf-8') as file:
        content = file.read()
    
    # Encontrar clases
    classes = re.findall(r'class\s+(\w+)', content)
    for cls in classes:
        symbol_to_file[cls] = f
    
    # Encontrar providers (variables globales que terminan en Provider)
    providers = re.findall(r'(?:final|const)\s+(\w+Provider)\s*=', content)
    for prov in providers:
        symbol_to_file[prov] = f
    
    # Encontrar funciones globales
    functions = re.findall(r'^\w+\s+([a-z]\w+)\s*\(', content, re.MULTILINE)
    for func in functions:
        symbol_to_file[func] = f

# Segunda pasada: para cada archivo, encontrar símbolos usados que no estén definidos localmente
# y que coincidan con nuestro mapeo
for f in sorted(os.listdir(lib)):
    if not f.endswith('.dart'):
        continue
    path = os.path.join(lib, f)
    with open(path, 'r', encoding='utf-8') as file:
        content = file.read()
    
    # Encontrar imports existentes
    existing_imports = set(re.findall(r"import\s+'([^']+)';", content))
    
    # Obtener nombres definidos localmente
    local_classes = set(re.findall(r'class\s+(\w+)', content))
    local_providers = set(re.findall(r'(?:final|const)\s+(\w+Provider)\s*=', content))
    local_defined = local_classes | local_providers
    
    needed_imports = set()
    
    # Buscar símbolos usados que no estén definidos localmente
    for symbol, source_file in symbol_to_file.items():
        if source_file == f:
            continue
        if symbol in local_defined:
            continue
        
        # Patrones de uso
        patterns = [
            rf'\b{re.escape(symbol)}\b',
        ]
        
        for pattern in patterns:
            if re.search(pattern, content):
                # Verificar que no sea solo en un comentario
                needed_imports.add(source_file)
                break
    
    # Agregar imports faltantes
    for imp_file in needed_imports:
        import_stmt = f"import '{imp_file}';"
        if imp_file not in existing_imports and import_stmt not in content:
            # Insertar después del último import de package:flutter
            lines = content.split('\n')
            last_import_idx = -1
            for i, line in enumerate(lines):
                if line.startswith('import '):
                    last_import_idx = i
            
            if last_import_idx >= 0:
                lines.insert(last_import_idx + 1, import_stmt)
            else:
                lines.insert(0, import_stmt)
            
            content = '\n'.join(lines)
    
    with open(path, 'w', encoding='utf-8') as file:
        file.write(content)

print("Imports rebuilt")
