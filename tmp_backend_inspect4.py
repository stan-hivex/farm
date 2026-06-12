import zipfile
from pathlib import Path
zf = zipfile.ZipFile(Path('C:/Users/u/Desktop/farm-backend.zip'),'r')
for p in ['farm-backend/dist/src/wallets/wallets.controller.js','farm-backend/dist/src/deposit/deposit.controller.js','farm-backend/dist/src/payments/payments.controller.js','farm-backend/dist/src/transactions/transactions.controller.js']:
    print('---', p, '---')
    if p in zf.namelist():
        text = zf.read(p).decode('utf-8', errors='replace')
        for line in text.splitlines():
            if 'controller' in line.lower() or 'post(' in line or 'get(' in line or 'patch(' in line or 'route' in line or 'auth' in line:
                print(line)
    else:
        print('MISSING')
    print()