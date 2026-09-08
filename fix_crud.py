import re

# Update Provider
with open('lib/features/admin/providers/admin_dashboard_provider.dart', 'r') as f:
    content = f.read()

# Change Future<bool> to Future<String?>
content = re.sub(r'Future<bool>\s+(create\w+|update\w+|delete\w+|convertTo\w+|updateStatus)\s*\(', r'Future<String?> \1(', content)

# Change return true; to return null;
content = re.sub(r'return true;', r'return null;', content)

# Change return false; to return lastError or something. 
# We need to capture the exception. Let's do a more structured replace.

def replace_method(match):
    body = match.group(0)
    body = body.replace('Future<bool>', 'Future<String?>')
    body = body.replace('return true;', 'return null;')
    body = body.replace('return false;', "return 'Error de base de datos o permisos (RLS). Revisa Logs.';")
    
    # Catch exceptions to return their string
    # We will just append the error message if possible, or just return it in the final return false -> return 'Error...'
    return body

with open('lib/features/admin/providers/admin_dashboard_provider.dart', 'w') as f:
    f.write(content)
