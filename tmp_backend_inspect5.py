import zipfile, re
from pathlib import Path
zf = zipfile.ZipFile(Path('C:/Users/u/Desktop/farm-backend.zip'),'r')
for p in ['farm-backend/dist/src/wallets/wallets.controller.js','farm-backend/dist/src/deposit/deposit.controller.js','farm-backend/dist/src/payments/payments.controller.js','farm-backend/dist/src/transactions/transactions.controller.js']:
    print('---', p, '---')
    if p in zf.namelist():
        text = zf.read(p).decode('utf-8', errors='replace')
        for m in re.finditer(r'\b(post|get|patch|put|delete|useGuards|Controller)\b', text, re.I):
            start = max(0, m.start()-80)
            end = m.start()+120
            print(text[start:end].replace('\n',' '))
    else:
        print('MISSING')
    print()