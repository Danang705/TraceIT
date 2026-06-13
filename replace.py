import os
import re

directory = r'd:\SEMESTER4\PBM\TraceIT-main\TraceIT-main\lib'

pattern = re.compile(r'ScaffoldMessenger\.of\(context\)\.showSnackBar\(\s*(?:const\s*)?SnackBar\(\s*content:\s*Text\(([^)]+)\)(?:,\s*backgroundColor:\s*[^)]+)?\s*\)\s*,?\s*\);', re.DOTALL | re.MULTILINE)

pattern_multi = re.compile(r'ScaffoldMessenger\.of\(context\)\.showSnackBar\(\s*(?:const\s*)?SnackBar\(\s*content:\s*Text\((.*?)\)\s*,.*?backgroundColor:\s*(AppColors\.danger|AppColors\.success|AppColors\.warning|Colors\.red|Colors\.green).*?\)\s*,?\s*\);', re.DOTALL | re.MULTILINE)

for root, _, files in os.walk(directory):
    for file in files:
        if file.endswith('.dart'):
            filepath = os.path.join(root, file)
            with open(filepath, 'r', encoding='utf-8') as f:
                content = f.read()
            
            original_content = content
            
            def repl(m):
                text_arg = m.group(1).strip()
                match_str = m.group(0)
                is_error = 'false'
                if 'danger' in match_str or 'red' in match_str or 'warning' in match_str or 'error' in match_str.lower() or 'gagal' in text_arg.lower() or 'harap' in text_arg.lower():
                    is_error = 'true'
                return f'CustomSnackBar.show(context, {text_arg}, isError: {is_error});'
            
            content = re.sub(pattern_multi, repl, content)
            content = re.sub(pattern, repl, content)
            
            if content != original_content:
                depth = filepath.count(os.sep) - directory.count(os.sep)
                if depth == 0:
                    import_stmt = "import 'utils/custom_snackbar.dart';"
                elif depth == 1:
                    import_stmt = "import '../utils/custom_snackbar.dart';"
                elif depth == 2:
                    import_stmt = "import '../../utils/custom_snackbar.dart';"
                elif depth == 3:
                    import_stmt = "import '../../../utils/custom_snackbar.dart';"
                else:
                    import_stmt = "import 'package:traceit/utils/custom_snackbar.dart';"
                    
                if 'custom_snackbar.dart' not in content:
                    import_match = list(re.finditer(r'^import .*;$', content, re.MULTILINE))
                    if import_match:
                        last_import = import_match[-1]
                        content = content[:last_import.end()] + '\n' + import_stmt + content[last_import.end():]
                
                with open(filepath, 'w', encoding='utf-8') as f:
                    f.write(content)
                print(f'Updated {filepath}')
