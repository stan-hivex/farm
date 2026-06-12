import zipfile
from pathlib import Path
zf = zipfile.ZipFile(Path('C:/Users/u/Desktop/farm-backend.zip'),'r')
files = [
    'farm-backend/package.json',
    'farm-backend/.env.example',
    'farm-backend/.env.production.example',
    'farm-backend/dist/src/wallets/wallets.controller.js',
    'farm-backend/dist/src/wallets/wallets.service.js',
    'farm-backend/dist/src/payments/payments.service.js',
    'farm-backend/dist/src/deposit/deposit.service.js',
    'farm-backend/dist/src/transactions/transactions.service.js',
    'farm-backend/dist/src/auth/auth.service.js',
    'farm-backend/dist/src/auth/auth.controller.js',
]
for p in files:
    print('---', p, '---')
    if p in zf.namelist():
        data = zf.read(p).decode('utf-8', errors='replace').splitlines()
        for i, line in enumerate(data[:220], 1):
            print(f'{i:03}: {line}')
    else:
        print('MISSING', p)
    print()