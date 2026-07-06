import os

dirs = ['overlay', 'widgets', 'services', 'theme', '.']

imports_str = 'import "../overlay"\nimport "../widgets"\nimport "../services"\nimport "../theme"\n'
imports_str_shell = 'import "./overlay"\nimport "./widgets"\nimport "./services"\nimport "./theme"\n'

def fix_file(filepath):
    with open(filepath, 'r') as f:
        content = f.read()

    if filepath == 'shell.qml':
        content = content.replace(imports_str_shell, '')
        content = imports_str_shell + content
    else:
        content = content.replace(imports_str, '')
        content = imports_str + content

    with open(filepath, 'w') as f:
        f.write(content)

for d in dirs:
    if os.path.isdir(d):
        for f in os.listdir(d):
            if f.endswith('.qml'):
                fix_file(os.path.join(d, f))

if os.path.exists('shell.qml'):
    fix_file('shell.qml')

