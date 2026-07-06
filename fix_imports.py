import os
import re

dirs = ['overlay', 'widgets', 'services', 'theme', '.']

def fix_imports(filepath):
    with open(filepath, 'r') as f:
        content = f.read()

    # Remove all relative imports like import "../something"
    content = re.sub(r'import\s+"(?:\.\./)+.*?"\n?', '', content)
    content = re.sub(r'import\s+"\./.*?"\n?', '', content)
    
    # We will add standard imports right after the last standard Qt/Quickshell import
    # or at the top if none found.
    standard_imports = ""
    
    # For files in subdirectories, we import other subdirectories
    parts = filepath.split('/')
    if len(parts) > 1 and parts[0] in ['overlay', 'widgets', 'services', 'theme']:
        standard_imports = 'import "../overlay"\nimport "../widgets"\nimport "../services"\nimport "../theme"\n'
    elif filepath == 'shell.qml':
        standard_imports = 'import "./overlay"\nimport "./widgets"\nimport "./services"\nimport "./theme"\n'

    # Find the last import Quickshell or import QtQuick
    last_import_pos = -1
    for match in re.finditer(r'import\s+[a-zA-Z0-9_.]+', content):
        last_import_pos = match.end()
    
    if last_import_pos != -1:
        # Find the end of the line
        line_end = content.find('\n', last_import_pos)
        if line_end != -1:
            content = content[:line_end+1] + standard_imports + content[line_end+1:]
        else:
            content = content + "\n" + standard_imports
    else:
        content = standard_imports + content

    with open(filepath, 'w') as f:
        f.write(content)

for d in dirs:
    if os.path.isdir(d):
        for f in os.listdir(d):
            if f.endswith('.qml'):
                fix_imports(os.path.join(d, f))

if os.path.exists('shell.qml'):
    fix_imports('shell.qml')

