# Usa l'immagine ufficiale di Flutter come base
FROM cirrusci/flutter:stable

# Crea un utente non root
RUN useradd -ms /bin/bash flutteruser
USER flutteruser

# Imposta la directory di lavoro dentro il container
WORKDIR /home/flutteruser/app

# Copia tutti i file del progetto Flutter nel container
COPY --chown=flutteruser . .

# Aggiungi l'eccezione per la directory di Flutter in Git
RUN git config --global --add safe.directory /sdks/flutter

# Impostiamo una directory di cache personalizzata
ENV PUB_CACHE="/home/flutteruser/.pub-cache"

# Crea la directory .pub-cache e imposta i permessi
RUN mkdir -p /home/flutteruser/.pub-cache && chmod -R 777 /home/flutteruser/.pub-cache

# Installa le dipendenze di Flutter senza usare la cache predefinita
RUN flutter pub get --no-cache

# Esegui la build del progetto per il web
RUN flutter build web

# Esponi la porta su cui il server sarà in ascolto
EXPOSE 5000

# Avvia l'app Flutter come server web sulla porta 5000
CMD ["flutter", "run", "--release", "--web-server", "0.0.0.0:5000"]
