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

# Installa le dipendenze di Flutter
RUN flutter pub get

# Esegui la build del progetto per il web
RUN flutter build web

# Esponi la porta su cui il server sarà in ascolto
EXPOSE 5000

# Avvia l'app Flutter come server web sulla porta 5000
CMD ["flutter", "run", "--release", "--web-server", "0.0.0.0:5000"]
