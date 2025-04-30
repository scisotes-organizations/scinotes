#!/usr/bin/env python3
"""
SciNotes Coordinate Server
This server receives coordinates from the iOS app and prints them to standard output.
"""

from http.server import HTTPServer, BaseHTTPRequestHandler
import json
import sys

# サーバーの設定
HOST = "0.0.0.0"
PORT = 8000

class CoordinateHandler(BaseHTTPRequestHandler):
    """HTTPリクエストを処理するハンドラクラス"""
    
    def _set_headers(self):
        """HTTPレスポンスヘッダーを設定"""
        self.send_response(200)
        self.send_header('Content-type', 'application/json')
        self.send_header('Access-Control-Allow-Origin', '*')  # CORSを許可
        self.send_header('Access-Control-Allow-Methods', 'POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type')
        self.end_headers()
    
    def do_OPTIONS(self):
        """OPTIONSリクエスト（プリフライトリクエスト）に対応"""
        self._set_headers()
    
    def do_POST(self):
        """POSTリクエストを処理し、座標データを標準出力に表示"""
        content_length = int(self.headers['Content-Length'])
        post_data = self.rfile.read(content_length)
        
        try:
            # JSON形式のデータを解析
            data = json.loads(post_data.decode('utf-8'))
            
            # 座標データを取得して標準出力に表示
            x = data.get('x')
            y = data.get('y')
            note_id = data.get('noteId')
            
            print(f"Received coordinate: Note ID: {note_id}, X: {x}, Y: {y}")
            sys.stdout.flush()  # 確実に標準出力に表示されるようにする
            
            # クライアントに応答
            self._set_headers()
            response = {
                'status': 'success',
                'message': f'Received coordinate: ({x}, {y}) for note {note_id}'
            }
            self.wfile.write(json.dumps(response).encode('utf-8'))
            
        except json.JSONDecodeError:
            # JSON解析エラー時の処理
            print("Error: Failed to parse JSON data")
            self._set_headers()
            response = {
                'status': 'error',
                'message': 'Invalid JSON data'
            }
            self.wfile.write(json.dumps(response).encode('utf-8'))
        except Exception as e:
            # その他のエラー時の処理
            print(f"Error: {str(e)}")
            self._set_headers()
            response = {
                'status': 'error',
                'message': str(e)
            }
            self.wfile.write(json.dumps(response).encode('utf-8'))

def run_server():
    """サーバーを起動する関数"""
    server_address = (HOST, PORT)
    httpd = HTTPServer(server_address, CoordinateHandler)
    print(f"Starting server on {HOST}:{PORT}")
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("Server stopped.")
        httpd.server_close()

if __name__ == "__main__":
    run_server()