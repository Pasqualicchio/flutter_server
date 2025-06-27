# Usa l'immagine ufficiale di Flutter come base
FROM cirrusci/flutter:stable

# Imposta la directory di lavoro dentro il container
WORKDIR /app

# Copia tutti i file del progetto Flutter nel container
COPY . .

# Installa le dipendenze di Flutter
RUN flutter pub get

# Esegui la build del progetto per il web
RUN flutter build web

# Esponi la porta su cui il server sarà in ascolto
EXPOSE 5000

# Avvia l'app Flutter come server web sulla porta 5000
CMD ["flutter", "run", "--release", "--web-server", "0.0.0.0:5000"]
