python -m pip install -r requirements.txt pyinstaller
pyinstaller --noconfirm --clean --onefile --windowed --name "Azeem-DeX" --add-data "tools;tools" src/main.py
