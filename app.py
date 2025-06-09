from flask import Flask, render_template, request, redirect, url_for, session, jsonify
from flask_sqlalchemy import SQLAlchemy
from werkzeug.security import generate_password_hash, check_password_hash
import os

app = Flask(__name__)
app.secret_key = os.urandom(24)  # Protezione sessione
app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///users.db'
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False

db = SQLAlchemy(app)

# MODELLO UTENTE
class User(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(50), unique=True, nullable=False)
    password = db.Column(db.String(150), nullable=False)

with app.app_context():
    db.create_all()

# 🔽 FUNZIONE PER RECUPERARE FILE ORDINATI
def get_all_files():
    folder = "uploads/"
    files = []

    if not os.path.exists(folder):
        os.makedirs(folder)

    for fname in os.listdir(folder):
        path = os.path.join(folder, fname)
        if os.path.isfile(path):
            created = os.path.getmtime(path)
            ext = fname.lower()
            ftype = 'image' if ext.endswith(('.png', '.jpg', '.jpeg', '.gif')) else (
                    'video' if ext.endswith(('.mp4', '.mov', '.avi')) else 'other')
            files.append({
                'path': fname,
                'type': ftype,
                'created': created,
                'size_kb': os.path.getsize(path) // 1024
            })

    files.sort(key=lambda x: x['created'], reverse=True)
    return files

# HOME
@app.route('/')
def home():
    return render_template('home.html')

# LOGIN
@app.route('/login', methods=['GET', 'POST'])
def login():
    if request.method == 'POST':
        username = request.form['username']
        password = request.form['password']

        user = User.query.filter_by(username=username).first()
        if user and check_password_hash(user.password, password):
            session['user_id'] = user.id
            return redirect(url_for('upload_advanced_ui'))
        else:
            return "❌ Credenziali errate", 401

    return render_template('login.html')

# REGISTRAZIONE
@app.route('/register', methods=['GET', 'POST'])
def register():
    if request.method == 'POST':
        username = request.form['username']
        password = request.form['password']
        confirm = request.form['confirm_password']

        if password != confirm:
            return "❌ Le password non coincidono", 400
        if User.query.filter_by(username=username).first():
            return "❌ Username già registrato", 400

        hashed_pw = generate_password_hash(password)
        new_user = User(username=username, password=hashed_pw)
        db.session.add(new_user)
        db.session.commit()
        return redirect(url_for('login'))

    return render_template('register.html')

# UPLOAD avanzato
@app.route('/upload', methods=['GET', 'POST'])
def upload_advanced_ui():
    if 'user_id' not in session:
        return redirect(url_for('login'))

    user = User.query.get(session['user_id'])
    if not user:
        session.clear()
        return redirect(url_for('login'))

    if request.method == 'POST':
        # Puoi gestire l'upload dei file qui
        return jsonify({"status": "success", "message": "File ricevuto!"})

    return render_template('upload_advanced_ui.html', user=user)

# BROWSE
@app.route('/browse')
def browse():
    if 'user_id' not in session:
        return redirect(url_for('login'))

    user = User.query.get(session['user_id'])
    files = get_all_files()
    return render_template('browse.html', images=files, user=user)

# LOGOUT
@app.route('/logout')
def logout():
    session.clear()
    return redirect(url_for('login'))

