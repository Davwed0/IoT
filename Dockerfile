FROM gcc:latest

WORKDIR /app

# Copy source code
COPY src/iot_simulator.c .

# Compile the C program
RUN gcc -o iot_simulator iot_simulator.c

# Create logs directory
RUN mkdir -p /logs

# Set default environment variables
ENV DEVICE_COUNT=5
ENV INTERVAL_SECONDS=5

CMD ["./iot_simulator"]
