import zipfile
from pathlib import Path
zf = zipfile.ZipFile(Path('C:/Users/u/Desktop/farm-backend.zip'), 'r')
print(len(zf.namelist()))
print('\n'.join(zf.namelist()[:200]))
