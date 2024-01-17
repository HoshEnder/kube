FROM python:3.9

WORKDIR /code

# Copie des dépendances
COPY ./requirements.txt /code/requirements.txt

# Installation des dépendances
RUN pip install --no-cache-dir --upgrade -r /code/requirements.txt

# Copie des fichiers de l'application
COPY ./app /code/app

# Commande pour démarrer l'application
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "80"]
