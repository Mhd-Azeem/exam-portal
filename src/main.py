import os, subprocess, threading, tkinter as tk
from tkinter import filedialog, messagebox
import customtkinter as ctk

ctk.set_appearance_mode("dark")
ctk.set_default_color_theme("blue")

BASE=os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TOOLS=os.path.join(BASE,"tools")
ADB=os.path.join(TOOLS,"adb.exe")
SCRCPY=os.path.join(TOOLS,"scrcpy.exe")

class DexApp(ctk.CTk):
    def __init__(self):
        super().__init__()
        self.title("Azeem DeX")
        self.geometry("1100x700")
        self.minsize(850,550)
        self.status=ctk.StringVar(value="No Android device connected")
        self.device=ctk.StringVar(value="—")
        self.build_ui()
        self.after(700,self.refresh)

    def build_ui(self):
        side=ctk.CTkFrame(self,width=230,corner_radius=0); side.pack(side="left",fill="y")
        ctk.CTkLabel(side,text="AZEEM DeX",font=ctk.CTkFont(size=26,weight="bold")).pack(padx=25,pady=(30,5))
        ctk.CTkLabel(side,text="Android Desktop • v1.0",text_color="gray").pack(pady=(0,25))
        for text,cmd in [("Refresh Device",self.refresh),("Open Phone",self.mirror),("Install APK",self.install_apk),("File Transfer",self.open_storage),("Wireless ADB",self.wireless),("Disconnect",self.disconnect)]:
            ctk.CTkButton(side,text=text,command=cmd,height=42).pack(fill="x",padx=20,pady=7)
        ctk.CTkLabel(side,textvariable=self.status,wraplength=190,text_color="gray").pack(side="bottom",padx=20,pady=25)

        main=ctk.CTkFrame(self,fg_color="transparent"); main.pack(side="left",fill="both",expand=True,padx=30,pady=30)
        ctk.CTkLabel(main,text="Android Desktop",font=ctk.CTkFont(size=34,weight="bold")).pack(anchor="w")
        ctk.CTkLabel(main,text="Connect your Android phone with USB debugging enabled.",text_color="gray").pack(anchor="w",pady=(3,25))
        card=ctk.CTkFrame(main); card.pack(fill="x",pady=10)
        ctk.CTkLabel(card,text="CONNECTED DEVICE",font=ctk.CTkFont(size=13,weight="bold"),text_color="gray").pack(anchor="w",padx=25,pady=(20,5))
        ctk.CTkLabel(card,textvariable=self.device,font=ctk.CTkFont(size=22,weight="bold")).pack(anchor="w",padx=25,pady=(0,20))
        grid=ctk.CTkFrame(main,fg_color="transparent"); grid.pack(fill="both",expand=True,pady=20)
        actions=[("Phone Screen","Mirror and control your phone",self.mirror),("APK Installer","Install an APK from Windows",self.install_apk),("Android Files","Open device storage in Explorer",self.open_storage),("Wi-Fi Mode","Connect using adb over TCP/IP",self.wireless)]
        for i,(a,b,c) in enumerate(actions):
            box=ctk.CTkFrame(grid); box.grid(row=i//2,column=i%2,padx=8,pady=8,sticky="nsew")
            ctk.CTkLabel(box,text=a,font=ctk.CTkFont(size=20,weight="bold")).pack(anchor="w",padx=20,pady=(22,4))
            ctk.CTkLabel(box,text=b,text_color="gray").pack(anchor="w",padx=20)
            ctk.CTkButton(box,text="Open",command=c).pack(anchor="w",padx=20,pady=20)
        grid.columnconfigure((0,1),weight=1); grid.rowconfigure((0,1),weight=1)

    def adb(self,*args):
        if not os.path.exists(ADB): return ""
        p=subprocess.run([ADB,*args],capture_output=True,text=True,creationflags=subprocess.CREATE_NO_WINDOW)
        return (p.stdout+p.stderr).strip()

    def refresh(self):
        out=self.adb("devices")
        devices=[x.split()[0] for x in out.splitlines()[1:] if "\tdevice" in x]
        if devices:
            serial=devices[0]
            model=self.adb("-s",serial,"shell","getprop","ro.product.model") or serial
            self.device.set(model); self.status.set("Connected • "+serial)
        else:
            self.device.set("No device"); self.status.set("Connect USB + enable USB debugging")

    def mirror(self):
        if not os.path.exists(SCRCPY): return messagebox.showerror("Missing component","scrcpy.exe is missing from tools.")
        subprocess.Popen([SCRCPY,"--window-title=Azeem DeX • Phone","--turn-screen-off"],cwd=TOOLS)

    def install_apk(self):
        path=filedialog.askopenfilename(filetypes=[("Android APK","*.apk")])
        if not path:return
        self.status.set("Installing APK…")
        def work():
            out=self.adb("install","-r",path)
            self.after(0,lambda: messagebox.showinfo("APK Installer",out))
            self.after(0,self.refresh)
        threading.Thread(target=work,daemon=True).start()

    def open_storage(self):
        messagebox.showinfo("Android Files","Version 1 uses Windows Explorer/MTP for file transfer. Unlock your phone and choose File Transfer (MTP) from the USB notification.")

    def wireless(self):
        ip=ctk.CTkInputDialog(text="Enter phone IP address (example 192.168.1.20):","Wi-Fi ADB").get_input()
        if ip:
            self.adb("tcpip","5555")
            out=self.adb("connect",ip+":5555")
            messagebox.showinfo("Wi-Fi ADB",out); self.refresh()

    def disconnect(self):
        self.adb("disconnect"); self.refresh()

if __name__=="__main__":
    DexApp().mainloop()
