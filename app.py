from flask import Flask

app = Flask(__name__)

@app.route("/")
def home():
    return "✅ Server Flask attivo su Render!"

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=10000)