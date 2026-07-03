from pathlib import Path
import ast
import base64

input_path = Path(r"c:/Users/u/AppData/Roaming/Code/User/workspaceStorage/576755aa84044ad5f7ccecaad9a93ec3/GitHub.copilot-chat/chat-session-resources/f9e466ee-8308-4fbf-8699-b7a140a2912e/call_mTflOzgAHd3slv2B7i0rnUlS__vscode-1783051774611/content.txt")
output_path = Path(r"c:/farm/deployed_admin_screenshot.png")
text = input_path.read_text(encoding='utf-8')
if text.startswith('"') and text.endswith('"'):
    text = ast.literal_eval(text)
else:
    text = text.strip()
output_path.write_bytes(base64.b64decode(text))
print(output_path)
