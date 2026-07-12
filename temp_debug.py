import pathlib 
p=pathlib.Path(r'lib/pages/dashboard/dashboard_widget.dart') 
text=p.read_text(encoding='utf-8') 
for idx, ch in enumerate(text): 
    if ch == '(' : open_count +=  
    elif ch == ')' : close_count +=  
print('paren:', open_count, close_count) 
lines=text.splitlines() 
for i in range(395, 430): 
    print(f'{i+1}: {lines[i]}') 
