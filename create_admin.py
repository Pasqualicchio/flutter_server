import sqlite3
from werkzeug.security import generate_password_hash

DB_PATH = "users.db"

def init_db():
    with sqlite3.connect(DB_PATH) as conn:
        conn.execute('''CREATE TABLE IF NOT EXISTS users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            username TEXT UNIQUE NOT NULL,
            password TEXT NOT NULL
        )''')
        conn.commit()

def create_admin_user():
    username = "admin"
    password = "password123"
    hashed_pw = generate_password_hash(password)

    with sqlite3.connect(DB_PATH) as conn:
        try:
            conn.execute("INSERT INTO users (username, password) VALUES (?, ?)", (username, hashed_pw))
            conn.commit()
            print(f"✅ Utente '{username}' creato con successo.")
        except sqlite3.IntegrityError:
            print(f"⚠️ L'utente '{username}' esiste già.")

if __name__ == '__main__':
    init_db()
    create_admin_user()
