FROM python:3.12-slim

WORKDIR /app

COPY emulator/requirements.txt /app/emulator/requirements.txt
RUN pip install --no-cache-dir -r /app/emulator/requirements.txt

COPY emulator /app/emulator
COPY .data /app/.data

ENV PYTHONPATH=/app
ENV PYTHONUNBUFFERED=1

CMD ["python", "-m", "emulator.worker"]
