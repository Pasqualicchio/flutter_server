from flask import Flask, render_template, request, redirect, url_for, session, jsonify, send_file
from flask_sqlalchemy import SQLAlchemy
from werkzeug.security import generate_password_hash, check_password_hash
from werkzeug.utils import secure_filename
import os, time
from openpyxl import Workbook

app = Flask(__name__)
app.secret_key = os.urandom(24)
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

# 🔽 FUNZIONE: Recupera file nella cartella 'uploads', ordinati per data
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
            if ext.endswith(('.png', '.jpg', '.jpeg', '.gif')):
                ftype = 'image'
            elif ext.endswith(('.mp4', '.mov', '.avi')):
                ftype = 'video'
            elif ext.endswith('.pdf'):
                ftype = 'pdf'
            elif ext.endswith(('.mp3', '.wav')):
                ftype = 'audio'
            elif ext.endswith(('.xls', '.xlsx')):
                ftype = 'excel'
            else:
                ftype = 'other'

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

# UPLOAD (GET + POST)
@app.route('/upload', methods=['GET', 'POST'])
def upload_advanced_ui():
    if 'user_id' not in session:
        return redirect(url_for('login'))

    user = User.query.get(session['user_id'])
    if not user:
        session.clear()
        return redirect(url_for('login'))

    if request.method == 'POST':
        macro = request.form.get('macro')
        commessa = request.form.get('commessa')
        matricola = request.form.get('matricola')
        item = request.form.get('item')
        if not all([macro, commessa, matricola, item]):
            return jsonify({"status": "error", "message": "Compila tutti i campi"}), 400

        files = request.files.getlist('images[]')
        if not files or files == [None] or all(f.filename == '' for f in files):
            single = request.files.get('file')
            if single and single.filename:
                files = [single]

        if not files or all(f.filename == '' for f in files):
            return jsonify({"status": "error", "message": "Nessun file valido selezionato"}), 400

        upload_folder = "uploads"
        os.makedirs(upload_folder, exist_ok=True)

        salvati = []
        for i, file in enumerate(files, start=1):
            if file and file.filename:
                ext = file.filename.rsplit('.', 1)[-1]
                name = f"{macro}_{commessa}_{matricola}_{item}_n{i}.{ext}"
                filename = secure_filename(name)
                path = os.path.join(upload_folder, filename)
                file.save(path)
                salvati.append(filename)

        return jsonify({
            "status": "success",
            "message": f"{len(salvati)} file caricati con successo!",
            "files": salvati
        })

    return render_template('upload_advanced_ui.html', user=user)

# BROWSE
@app.route('/browse')
def browse():
    files = get_all_files()
    images = [f for f in files if f['type'] in ['image', 'video']]
    excels = [f for f in files if f['type'] == 'excel']

    page = int(request.args.get('page', 1))
    per_page = 12
    total_pages = (len(images) + per_page - 1) // per_page

    start = (page - 1) * per_page
    end = start + per_page
    paginated_files = images[start:end]

    return render_template('browse.html', images=paginated_files, excels=excels, page=page, total_pages=total_pages)

# DOWNLOAD GLOBALE EXCEL
@app.route('/download-global-excel')
def download_global_excel():
    wb = Workbook()
    ws = wb.active
    ws.title = "Log Files"
    ws.append(["Filename", "Tipo", "Data creazione", "Dimensione (KB)"])

    for f in get_all_files():
        ws.append([
            f['path'],
            f['type'],
            time.strftime('%Y-%m-%d %H:%M:%S', time.localtime(f['created'])),
            f['size_kb']
        ])

    os.makedirs("exports", exist_ok=True)
    output_path = "exports/global_log.xlsx"
    wb.save(output_path)

    return send_file(output_path, as_attachment=True)

# DOWNLOAD FILE SINGOLO
@app.route('/download/<path:filename>')
def download_file(filename):
    path = os.path.join("uploads", filename)
    if os.path.exists(path):
        return send_file(path, as_attachment=True)
    return "❌ File non trovato", 404

# LOGOUT
@app.route('/logout')
def logout():
    session.clear()
    return redirect(url_for('login'))

if __name__ == '__main__':
    app.run(debug=True)
