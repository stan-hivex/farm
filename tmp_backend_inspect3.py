import zipfile
from pathlib import Path
zf = zipfile.ZipFile(Path('C:/Users/u/Desktop/farm-backend.zip'),'r')
for p in ['farm-backend/package.json','farm-backend/.env.example','farm-backend/.env.production.example']:
    print('---', p, '---')
    if p in zf.namelist():
        print(zf.read(p).decode('utf-8', errors='replace'))
    else:
        print('MISSING')
    print()

for p in ['farm-backend/dist/src/wallets/wallets.service.js','farm-backend/dist/src/transactions/transactions.service.js','farm-backend/dist/src/wallets/wallets.controller.js','farm-backend/dist/src/transactions/transactions.controller.js','farm-backend/dist/src/deposit/deposit.controller.js','farm-backend/dist/src/payments/payments.controller.js']:
    print('===', p, '===')
    if p in zf.namelist():
        data = zf.read(p).decode('utf-8', errors='replace').splitlines()
        for i,line in enumerate(data[:260],1):
            print(f'{i:03}: {line}')
        print('...')
    else:
        print('MISSING')
    print()