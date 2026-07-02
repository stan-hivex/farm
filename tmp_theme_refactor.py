from pathlib import Path
import re
root = Path('lib')
replacements = [
    (r'Colors\.white70', 'context.onSurface.withOpacity(0.7)'),
    (r'Colors\.white60', 'context.onSurface.withOpacity(0.6)'),
    (r'Colors\.white54', 'context.onSurface.withOpacity(0.54)'),
    (r'Colors\.white38', 'context.onSurface.withOpacity(0.38)'),
    (r'Colors\.white24', 'context.onSurface.withOpacity(0.24)'),
    (r'Colors\.white12', 'context.onSurface.withOpacity(0.12)'),
    (r'Colors\.white10', 'context.onSurface.withOpacity(0.1)'),
    (r'Colors\.white', 'context.onSurface'),
    (r'Colors\.black87', 'context.onBackground.withOpacity(0.87)'),
    (r'Colors\.black54', 'context.onBackground.withOpacity(0.54)'),
    (r'Colors\.black12', 'context.onBackground.withOpacity(0.12)'),
    (r'Colors\.black', 'context.background'),
    (r'Colors\.grey\.shade900', 'context.textPrimary'),
    (r'Colors\.grey\.shade700', 'context.textSecondary'),
    (r'Colors\.grey\.shade300', 'context.borderColor'),
    (r'Colors\.grey\.shade200', 'context.borderColor'),
    (r'Colors\.grey\.shade100', 'context.surface'),
    (r'Colors\.grey\.shade50', 'context.surface'),
    (r'Colors\.grey\[700\]', 'context.textSecondary'),
    (r'Colors\.grey\[100\]', 'context.surface'),
    (r'Colors\.grey', 'context.textSecondary'),
    (r'Colors\.red\.shade900', 'context.errorColor'),
    (r'Colors\.red', 'context.errorColor'),
    (r'Colors\.green\.shade100', 'context.successColor.withOpacity(0.4)'),
    (r'Colors\.green\.shade50', 'context.successColor.withOpacity(0.2)'),
    (r'Colors\.green', 'context.successColor'),
    (r'Colors\.orange\.shade50', 'context.warningColor.withOpacity(0.2)'),
    (r'Colors\.orange', 'context.warningColor'),
    (r'Colors\.blueGrey', 'context.secondaryColor'),
    (r'Colors\.transparent', 'Colors.transparent'),
    (r'Colors\.white\.withOpacity', 'context.onSurface.withOpacity'),
    (r'Colors\.black\.withOpacity', 'context.background.withOpacity'),
    (r'Colors\.black\.withAlpha', 'context.background.withAlpha'),
    (r'Color\(0xFF111111\)', 'context.surface'),
]
files = list(root.glob('pages/**/*.dart')) + list(root.glob('admin/**/*.dart')) + list(root.glob('components/**/*.dart'))
modified = 0
for p in files:
    text = p.read_text(encoding='utf-8')
    original = text
    for pat, repl in replacements:
        text = re.sub(pat, repl, text)
    if text != original:
        if "import '/core/theme_extensions.dart';" not in text:
            lines = text.splitlines()
            insert_after = -1
            for i, line in enumerate(lines):
                if line.startswith("import '/flutter_flow/flutter_flow_util.dart';"):
                    insert_after = i
                    break
            if insert_after == -1:
                for i, line in enumerate(lines):
                    if line.startswith('import ') and 'package:' in line:
                        insert_after = i
                if insert_after == -1:
                    lines.insert(0, "import '/core/theme_extensions.dart';")
                else:
                    lines.insert(insert_after + 1, "import '/core/theme_extensions.dart';")
            else:
                lines.insert(insert_after + 1, "import '/core/theme_extensions.dart';")
            text = '\n'.join(lines) + '\n'
        p.write_text(text, encoding='utf-8')
        modified += 1
print(f'patched {modified} files')
