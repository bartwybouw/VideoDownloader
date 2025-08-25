#!/usr/bin/env python3
import http.server
import socketserver
import urllib.parse
import subprocess
import json
import os
import threading
import webbrowser

class VideoDownloadHandler(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        if self.path == '/' or self.path == '/index.html':
            self.send_response(200)
            self.send_header('Content-type', 'text/html')
            self.end_headers()
            
            html_content = '''<!DOCTYPE html>
<html lang="nl">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Video Downloader</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            max-width: 600px;
            margin: 50px auto;
            padding: 20px;
            background-color: #f5f5f5;
        }
        .container {
            background: white;
            padding: 30px;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        h1 {
            text-align: center;
            color: #333;
            margin-bottom: 30px;
        }
        label {
            display: block;
            margin: 20px 0 5px;
            font-weight: 600;
            color: #555;
        }
        input[type="text"], input[type="file"] {
            width: 100%;
            padding: 12px;
            border: 1px solid #ddd;
            border-radius: 5px;
            font-size: 16px;
            margin-bottom: 10px;
        }
        button {
            background-color: #007AFF;
            color: white;
            padding: 12px 30px;
            border: none;
            border-radius: 5px;
            font-size: 16px;
            cursor: pointer;
            width: 100%;
            margin-top: 20px;
        }
        button:hover {
            background-color: #0056b3;
        }
        button:disabled {
            background-color: #ccc;
            cursor: not-allowed;
        }
        .status {
            margin-top: 20px;
            padding: 15px;
            border-radius: 5px;
            text-align: center;
        }
        .status.success {
            background-color: #d4edda;
            color: #155724;
            border: 1px solid #c3e6cb;
        }
        .status.error {
            background-color: #f8d7da;
            color: #721c24;
            border: 1px solid #f5c6cb;
        }
        .status.info {
            background-color: #d1ecf1;
            color: #0c5460;
            border: 1px solid #bee5eb;
        }
        .loading {
            display: inline-block;
            width: 20px;
            height: 20px;
            border: 3px solid #f3f3f3;
            border-top: 3px solid #007AFF;
            border-radius: 50%;
            animation: spin 1s linear infinite;
            margin-right: 10px;
        }
        @keyframes spin {
            0% { transform: rotate(0deg); }
            100% { transform: rotate(360deg); }
        }
        .folder-info {
            font-style: italic;
            color: #666;
            font-size: 14px;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>Video Downloader</h1>
        
        <form id="downloadForm">
            <label for="url">Video URL:</label>
            <input type="text" id="url" name="url" placeholder="Plak hier de video URL" required>
            
            <label for="folder">Download Map:</label>
            <input type="text" id="folder" name="folder" placeholder="Voer het volledige pad in (bijv: /Users/jouw-naam/Downloads)" required>
            <div class="folder-info">💡 Tip: Open Finder, ga naar de gewenste map, en kopieer het pad uit de adresbalk</div>
            
            <button type="submit" id="downloadBtn">Download Video</button>
        </form>
        
        <div id="status" class="status" style="display: none;"></div>
    </div>

    <script>
        document.getElementById('downloadForm').addEventListener('submit', async function(e) {
            e.preventDefault();
            
            const url = document.getElementById('url').value;
            const folder = document.getElementById('folder').value;
            const btn = document.getElementById('downloadBtn');
            const status = document.getElementById('status');
            
            // Validate inputs
            if (!url || !folder) {
                showStatus('Vul alle velden in', 'error');
                return;
            }
            
            // Update UI
            btn.disabled = true;
            btn.innerHTML = '<span class="loading"></span>Downloaden...';
            showStatus('Download wordt gestart...', 'info');
            
            try {
                const response = await fetch('/download', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                    },
                    body: JSON.stringify({ url: url, folder: folder })
                });
                
                const result = await response.json();
                
                if (result.success) {
                    showStatus('✅ Download voltooid!', 'success');
                } else {
                    showStatus('❌ ' + result.error, 'error');
                }
            } catch (error) {
                showStatus('❌ Netwerkfout: ' + error.message, 'error');
            } finally {
                btn.disabled = false;
                btn.innerHTML = 'Download Video';
            }
        });
        
        function showStatus(message, type) {
            const status = document.getElementById('status');
            status.textContent = message;
            status.className = 'status ' + type;
            status.style.display = 'block';
        }
    </script>
</body>
</html>'''
            self.wfile.write(html_content.encode('utf-8'))
            
        elif self.path == '/download':
            self.send_error(405, "Method Not Allowed")
        else:
            super().do_GET()
    
    def do_POST(self):
        if self.path == '/download':
            content_length = int(self.headers['Content-Length'])
            post_data = self.rfile.read(content_length)
            
            try:
                data = json.loads(post_data.decode('utf-8'))
                url = data.get('url')
                folder = data.get('folder')
                
                if not url or not folder:
                    self.send_json_response({'success': False, 'error': 'URL en map zijn vereist'})
                    return
                
                # Check if folder exists
                if not os.path.exists(folder):
                    self.send_json_response({'success': False, 'error': f'Map bestaat niet: {folder}'})
                    return
                
                # Check if yt-dlp is installed
                try:
                    subprocess.run(["yt-dlp", "--version"], capture_output=True, check=True)
                except (subprocess.CalledProcessError, FileNotFoundError):
                    self.send_json_response({
                        'success': False, 
                        'error': 'yt-dlp is niet geïnstalleerd. Installeer het met: brew install yt-dlp'
                    })
                    return
                
                # Download video
                output_template = os.path.join(folder, "%(title)s.%(ext)s")
                cmd = [
                    "yt-dlp",
                    "--hls-prefer-native", 
                    url,
                    "-o", output_template
                ]
                
                result = subprocess.run(cmd, capture_output=True, text=True, timeout=300)
                
                if result.returncode == 0:
                    self.send_json_response({'success': True, 'message': 'Video succesvol gedownload'})
                else:
                    error_msg = result.stderr or "Onbekende fout bij downloaden"
                    self.send_json_response({'success': False, 'error': error_msg})
                    
            except json.JSONDecodeError:
                self.send_json_response({'success': False, 'error': 'Ongeldige JSON data'})
            except subprocess.TimeoutExpired:
                self.send_json_response({'success': False, 'error': 'Download timeout (>5 minuten)'})
            except Exception as e:
                self.send_json_response({'success': False, 'error': str(e)})
        else:
            self.send_error(404, "Not Found")
    
    def send_json_response(self, data):
        self.send_response(200)
        self.send_header('Content-type', 'application/json')
        self.end_headers()
        self.wfile.write(json.dumps(data).encode('utf-8'))

def main():
    PORT = 8000
    
    with socketserver.TCPServer(("", PORT), VideoDownloadHandler) as httpd:
        print(f"Video Downloader draait op http://localhost:{PORT}")
        print("Druk Ctrl+C om te stoppen")
        
        # Open browser
        webbrowser.open(f'http://localhost:{PORT}')
        
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print("\\nServer gestopt")

if __name__ == "__main__":
    main()