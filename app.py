from flask import Flask, render_template, request, redirect, url_for, jsonify

app = Flask(__name__)

@app.route('/')
def home():
    return "✅ Server Flask attivo su Render!"

@app.route('/login', methods=['GET', 'POST'])
def login():
    if request.method == 'POST':
        username = request.form.get('username')
        password = request.form.get('password')
        
        # Sostituisci con il tuo controllo reale
        if username == 'admin' and password == '1234':
            return "✅ Login riuscito!"
        else:
            return "❌ Credenziali non valide", 401

    # Metodo GET → mostra il form HTML
    return render_template('login.html')