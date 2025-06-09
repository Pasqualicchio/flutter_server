from flask import Flask, render_template, request, redirect, url_for, jsonify
from flask_sqlalchemy import SQLAlchemy
import os

app = Flask(__name__)
app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///users.db'
db = SQLAlchemy(app)

# MODELLI
class User(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(50), unique=True, nullable=False)
    password = db.Column(db.String(50), nullable=False)

# CREA DB SE NON ESISTE
with app.app_context():
    db.create_all()

@app.route('/')
def home():
    return "✅ Server Flask attivo su Render!"

@app.route('/login', methods=['GET', 'POST'])
def login():
    if request.method == 'POST':
        username = request.form.get('username')
        password = request.form.get('password')

        user = User.query.filter_by(username=username, password=password).first()
        if user:
            return "✅ Login riuscito!"
        else:
            return "❌ Credenziali errate", 401

    return render_template('login.html')

@app.route('/register', methods=['GET', 'POST'])
def register():
    if request.method == 'POST':
        username = request.form.get('username')
        password = request.form.get('password')
        confirm = request.form.get('confirm_password')

        if password != confirm:
            return "❌ Le password non coincidono", 400

        if User.query.filter_by(username=username).first():
            return "❌ Username già registrato", 400

        new_user = User(username=username, password=password)
        db.session.add(new_user)
        db.session.commit()

        return "✅ Registrazione completata!"

    return render_template('register.html')
