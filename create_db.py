import sqlite3

DB_PATH = "users.db"  # Il percorso del tuo database

# Crea una connessione e la tabella 'users' se non esiste
with sqlite3.connect(DB_PATH) as conn:
    c = conn.cursor()
    c.execute('''
    CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE,
        password TEXT
    )
    ''')
    conn.commit()

print("Database creato con successo!")
