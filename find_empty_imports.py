import os
import re

lib = r'C:\Users\Alumnos\Documents\Eduardo\quickinvent-main\lib'

for f in os.listdir(lib):
    if not f.endswith('.dart'):
        continue
    path = os.path.join(lib, f)
    with open(path, 'r', encoding='utf-8') as file:
        content = file.read()
    
    empty = re.findall(r"import\s+['\"]['\"];", content)
    if empty:
        print(f"{f}: {len(empty)} empty import(s)")
