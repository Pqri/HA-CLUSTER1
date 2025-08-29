from flask import Flask
import socket
app = Flask(__name__)

@app.get("/")
def index():
    h = socket.gethostname()
    return f"<h1>HA Frontend</h1><p>Aktif di node: <b>{h}</b></p>"

@app.get("/healthz")
def healthz():
    return "ok", 200
