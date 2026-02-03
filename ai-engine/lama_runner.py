import sys
import os

# 强制添加用户包路径，防止 ModuleNotFoundError
user_site = os.path.expanduser("~/.local/lib/python3.14/site-packages")
if user_site not in sys.path:
    sys.path.insert(0, user_site)

from lama_service import app
if __name__ == '__main__':
    app.run(host='127.0.0.1', port=5005)
