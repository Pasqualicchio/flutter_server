import sqlite3

DB_PATH = "users.db"

# Connessione al database (verrà creato se non esiste)
conn = sqlite3.connect(DB_PATH)
cursor = conn.cursor()

# Crea la tabella 'users' se non esiste
cursor.execute('''
CREATE TABLE IF NOT EXISTS users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    username TEXT UNIQUE NOT NULL,
    password TEXT NOT NULL
)
''')

# Commit delle modifiche e chiusura della connessione
conn.commit()
conn.close()

print("Tabella 'users' creata con successo.")
