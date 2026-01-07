#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <unistd.h>
#include <sys/stat.h>
#include <sys/types.h>

#define LOG_DIR "/logs"
#define MAX_DEVICE_ID_LEN 32
#define MAX_TIMESTAMP_LEN 64
#define MAX_LOG_LINE_LEN 512

// Configuration
typedef struct {
    int device_count;
    int interval_seconds;
} Config;

// Device data structure
typedef struct {
    char device_id[MAX_DEVICE_ID_LEN];
    float temperature;
    float humidity;
    char status[16];
} DeviceData;

// Generate random float in range [min, max]
float random_float(float min, float max) {
    return min + ((float)rand() / RAND_MAX) * (max - min);
}

// Generate device status
void generate_status(char *status) {
    int status_code = rand() % 100;
    if (status_code < 90) {
        strcpy(status, "OK");
    } else if (status_code < 95) {
        strcpy(status, "WARNING");
    } else {
        strcpy(status, "ERROR");
    }
}

// Get current timestamp in ISO 8601 format
void get_timestamp(char *timestamp) {
    time_t now;
    struct tm *tm_info;
    
    time(&now);
    tm_info = gmtime(&now);
    strftime(timestamp, MAX_TIMESTAMP_LEN, "%Y-%m-%dT%H:%M:%SZ", tm_info);
}

// Generate device data
void generate_device_data(DeviceData *device, const char *device_id) {
    strcpy(device->device_id, device_id);
    device->temperature = random_float(15.0, 35.0);
    device->humidity = random_float(30.0, 90.0);
    generate_status(device->status);
}

// Write JSON log
void write_log(DeviceData *device, FILE *log_file) {
    char timestamp[MAX_TIMESTAMP_LEN];
    get_timestamp(timestamp);
    
    fprintf(log_file, 
            "{\"timestamp\":\"%s\",\"device_id\":\"%s\",\"temp\":%.1f,\"humidity\":%.0f,\"status\":\"%s\"}\n",
            timestamp, device->device_id, device->temperature, device->humidity, device->status);
    fflush(log_file);
}

// Parse environment variable with default value
int get_env_int(const char *name, int default_value) {
    char *value = getenv(name);
    if (value != NULL) {
        return atoi(value);
    }
    return default_value;
}

int main() {
    Config config;
    DeviceData device;
    FILE *log_file;
    char log_path[256];
    
    // Initialize random seed
    srand(time(NULL));
    
    // Read configuration from environment variables
    config.device_count = get_env_int("DEVICE_COUNT", 5);
    config.interval_seconds = get_env_int("INTERVAL_SECONDS", 5);
    
    printf("IoT Simulator starting...\n");
    printf("Device count: %d\n", config.device_count);
    printf("Interval: %d seconds\n", config.interval_seconds);
    
    // Create logs directory if it doesn't exist
    mkdir(LOG_DIR, 0777);
    
    // Open log file
    snprintf(log_path, sizeof(log_path), "%s/iot_logs.json", LOG_DIR);
    log_file = fopen(log_path, "a");
    if (log_file == NULL) {
        fprintf(stderr, "Error: Could not open log file %s\n", log_path);
        return 1;
    }
    
    printf("Logging to: %s\n", log_path);
    printf("Starting data generation...\n");
    printf("Press Ctrl+C to stop\n\n");
    
    // Main loop - generate data continuously
    while (1) {
        for (int i = 0; i < config.device_count; i++) {
            char device_id[MAX_DEVICE_ID_LEN];
            snprintf(device_id, sizeof(device_id), "dev%c%d", 
                     'A' + (i / 10), (i % 10) + 1);
            
            generate_device_data(&device, device_id);
            write_log(&device, log_file);
            
            printf("Generated: %s - Temp: %.1f°C, Humidity: %.0f%%, Status: %s\n",
                   device.device_id, device.temperature, device.humidity, device.status);
        }
        
        printf("\n");
        sleep(config.interval_seconds);
    }
    
    // Note: This code is unreachable due to infinite loop above
    // In a real application, you would handle signals (SIGINT, SIGTERM) to break the loop
    // and close resources properly
    // fclose(log_file);
    // return 0;
}
