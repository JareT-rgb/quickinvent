import os
import re

lib = r'C:\Users\Alumnos\Documents\Eduardo\quickinvent-main\lib'

for f in os.listdir(lib):
    if not f.endswith('.dart'):
        continue
    path = os.path.join(lib, f)
    with open(path, 'r', encoding='utf-8') as file:
        content = file.read()
    
    # Eliminar imports vacíos
    content = re.sub(r"import\s+['\"]['\"];\n", "", content)
    
    # Verificar si quedan imports con rutas de carpeta (que serían incorrectos ahora)
    bad_imports = re.findall(r"import\s+['\"][^'\"]*(?:models|repositories|providers|screens|dialogs|widgets|theme)/[^'\"]*['\"];", content)
    if bad_imports:
        print(f"{f}: still has bad imports: {bad_imports}")
    
    with open(path, 'w', encoding='utf-8') as file:
        file.write(content)

print("Cleaned empty imports")
