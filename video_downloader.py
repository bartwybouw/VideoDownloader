#!/usr/bin/env python3
import tkinter as tk
from tkinter import ttk, filedialog, messagebox
import subprocess
import threading
import os

class VideoDownloaderApp:
    def __init__(self, root):
        self.root = root
        self.root.title("Video Downloader")
        self.root.geometry("600x400")
        
        # Variables
        self.url_var = tk.StringVar()
        self.folder_var = tk.StringVar(value="Geen map geselecteerd")
        self.status_var = tk.StringVar()
        self.is_downloading = False
        
        self.create_widgets()
        
    def create_widgets(self):
        # Main frame
        main_frame = ttk.Frame(self.root, padding="20")
        main_frame.grid(row=0, column=0, sticky=(tk.W, tk.E, tk.N, tk.S))
        
        # Title
        title_label = ttk.Label(main_frame, text="Video Downloader", font=("Arial", 18, "bold"))
        title_label.grid(row=0, column=0, columnspan=3, pady=(0, 20))
        
        # URL section
        url_label = ttk.Label(main_frame, text="Video URL:", font=("Arial", 12, "bold"))
        url_label.grid(row=1, column=0, columnspan=3, sticky=tk.W, pady=(0, 5))
        
        url_entry = ttk.Entry(main_frame, textvariable=self.url_var, width=70)
        url_entry.grid(row=2, column=0, columnspan=3, sticky=(tk.W, tk.E), pady=(0, 20))
        
        # Folder section
        folder_label = ttk.Label(main_frame, text="Download locatie:", font=("Arial", 12, "bold"))
        folder_label.grid(row=3, column=0, columnspan=3, sticky=tk.W, pady=(0, 5))
        
        folder_display = ttk.Label(main_frame, textvariable=self.folder_var, 
                                 background="white", relief="sunken", padding=5)
        folder_display.grid(row=4, column=0, columnspan=2, sticky=(tk.W, tk.E), pady=(0, 20))
        
        folder_button = ttk.Button(main_frame, text="Kies Map", command=self.select_folder)
        folder_button.grid(row=4, column=2, padx=(10, 0), pady=(0, 20))
        
        # Download button
        self.download_button = ttk.Button(main_frame, text="Download Video", 
                                        command=self.download_video, style="Accent.TButton")
        self.download_button.grid(row=5, column=0, columnspan=3, pady=(0, 20))
        
        # Progress bar
        self.progress = ttk.Progressbar(main_frame, mode='indeterminate')
        self.progress.grid(row=6, column=0, columnspan=3, sticky=(tk.W, tk.E), pady=(0, 10))
        
        # Status label
        status_label = ttk.Label(main_frame, textvariable=self.status_var, 
                               wraplength=550, justify="center")
        status_label.grid(row=7, column=0, columnspan=3, pady=(0, 20))
        
        # Configure grid weights
        self.root.columnconfigure(0, weight=1)
        self.root.rowconfigure(0, weight=1)
        main_frame.columnconfigure(0, weight=1)
        main_frame.columnconfigure(1, weight=1)
        
    def select_folder(self):
        folder = filedialog.askdirectory(title="Selecteer download map")
        if folder:
            self.folder_var.set(folder)
    
    def download_video(self):
        url = self.url_var.get().strip()
        folder = self.folder_var.get()
        
        if not url:
            messagebox.showerror("Fout", "Voer een video URL in")
            return
            
        if folder == "Geen map geselecteerd":
            messagebox.showerror("Fout", "Selecteer een download map")
            return
            
        # Check if yt-dlp is installed
        if not self.check_ytdlp():
            messagebox.showerror("Fout", 
                "yt-dlp is niet geïnstalleerd.\n\n"
                "Installeer het met:\nbrew install yt-dlp")
            return
            
        # Start download in separate thread
        self.is_downloading = True
        self.download_button.config(text="Downloaden...", state="disabled")
        self.progress.start()
        self.status_var.set("Download wordt gestart...")
        
        thread = threading.Thread(target=self.do_download, args=(url, folder))
        thread.daemon = True
        thread.start()
    
    def check_ytdlp(self):
        try:
            subprocess.run(["yt-dlp", "--version"], capture_output=True, check=True)
            return True
        except (subprocess.CalledProcessError, FileNotFoundError):
            return False
    
    def do_download(self, url, folder):
        try:
            # Build yt-dlp command
            output_template = os.path.join(folder, "%(title)s.%(ext)s")
            cmd = [
                "yt-dlp",
                "--hls-prefer-native",
                url,
                "-o", output_template
            ]
            
            # Run yt-dlp
            result = subprocess.run(cmd, capture_output=True, text=True)
            
            # Update UI on main thread
            if result.returncode == 0:
                self.root.after(0, self.download_finished, "✅ Download voltooid!", True)
            else:
                error_msg = f"❌ Download mislukt:\n{result.stderr}"
                self.root.after(0, self.download_finished, error_msg, False)
                
        except Exception as e:
            error_msg = f"❌ Fout: {str(e)}"
            self.root.after(0, self.download_finished, error_msg, False)
    
    def download_finished(self, message, success):
        self.is_downloading = False
        self.download_button.config(text="Download Video", state="normal")
        self.progress.stop()
        self.status_var.set(message)
        
        if success:
            messagebox.showinfo("Succes", "Video succesvol gedownload!")

def main():
    root = tk.Tk()
    app = VideoDownloaderApp(root)
    root.mainloop()

if __name__ == "__main__":
    main()