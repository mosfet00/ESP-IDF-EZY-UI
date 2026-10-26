#include <stdio.h>
#include <stdint.h>
#include <string.h>

#include "freertos/FreeRTOS.h"
#include "freertos/task.h"

#include "driver/uart.h"
#include "esp_log.h"
#include "esp_err.h"

#define TAG "SLAVE_SCAN"

// ============================================================
// Slave scan Code for Soil Sensor on esp23s3 modbus
// ============================================================

// ============================================================
// UART CONFIG
// ============================================================

#define MB_PORT_NUM       UART_NUM_1

#define MB_UART_TXD       17
#define MB_UART_RXD       18

#define MB_BAUDRATE       9600

#define UART_BUF_SIZE     256

// ============================================================
// MODBUS CRC16
// ============================================================

static uint16_t modbus_crc16(const uint8_t *data, uint16_t length)
{
    uint16_t crc = 0xFFFF;

    for (uint16_t pos = 0; pos < length; pos++)
    {
        crc ^= data[pos];

        for (uint8_t i = 0; i < 8; i++)
        {
            if (crc & 0x0001)
            {
                crc >>= 1;
                crc ^= 0xA001;
            }
            else
            {
                crc >>= 1;
            }
        }
    }

    return crc;
}


// ============================================================
// UART INIT
// ============================================================

static esp_err_t modbus_uart_init(void)
{
    uart_config_t config = {
        .baud_rate = MB_BAUDRATE,
        .data_bits = UART_DATA_8_BITS,
        .parity = UART_PARITY_DISABLE,
        .stop_bits = UART_STOP_BITS_1,
        .flow_ctrl = UART_HW_FLOWCTRL_DISABLE,
        // .source_clk = UART_SCLK_DEFAULT,
    };

    ESP_ERROR_CHECK(
        uart_driver_install(
            MB_PORT_NUM,
            UART_BUF_SIZE,
            UART_BUF_SIZE,
            0,
            NULL,
            0
        )
    );

    ESP_ERROR_CHECK(
        uart_param_config(
            MB_PORT_NUM,
            &config
        )
    );

    ESP_ERROR_CHECK(
        uart_set_pin(
            MB_PORT_NUM,
            MB_UART_TXD,
            MB_UART_RXD,
            UART_PIN_NO_CHANGE,
            UART_PIN_NO_CHANGE
        )
    );

    ESP_LOGI(TAG, "UART Initialized");
    ESP_LOGI(TAG, "TX = GPIO%d", MB_UART_TXD);
    ESP_LOGI(TAG, "RX = GPIO%d", MB_UART_RXD);
    ESP_LOGI(TAG, "Baud = %d", MB_BAUDRATE);

    return ESP_OK;
}


// ============================================================
// CHECK RESPONSE CRC
// ============================================================

static bool check_crc(
    uint8_t *data,
    int len
)
{
    if (len < 5)
    {
        return false;
    }

    uint16_t received_crc =
        data[len - 2] |
        ((uint16_t)data[len - 1] << 8);

    uint16_t calculated_crc =
        modbus_crc16(
            data,
            len - 2
        );

    return (
        received_crc ==
        calculated_crc
    );
}


// ============================================================
// SCAN ONE SLAVE ID
// ============================================================

static bool scan_slave(
    uint8_t slave_id
)
{
    uint8_t frame[8];

    /*
     * MODBUS READ:
     *
     * Slave ID
     * Function = 0x03
     * Start Register = 0x0000
     * Register Count = 0x0001
     *
     * Read only ONE register
     */

    frame[0] = slave_id;
    frame[1] = 0x03;

    // Start Register
    frame[2] = 0x00;
    frame[3] = 0x00;

    // Number of registers
    frame[4] = 0x00;
    frame[5] = 0x01;

    // CRC
    uint16_t crc =
        modbus_crc16(
            frame,
            6
        );

    frame[6] = crc & 0xFF;
    frame[7] = (crc >> 8) & 0xFF;


    // Clear old RX data
    uart_flush_input(
        MB_PORT_NUM
    );


    // Send request
    int written =
        uart_write_bytes(
            MB_PORT_NUM,
            (const char *)frame,
            sizeof(frame)
        );

    if (written != sizeof(frame))
    {
        return false;
    }


    // Wait TX complete
    uart_wait_tx_done(
        MB_PORT_NUM,
        pdMS_TO_TICKS(100)
    );


    // Wait sensor response
    uint8_t response[32];

    int len =
        uart_read_bytes(
            MB_PORT_NUM,
            response,
            sizeof(response),
            pdMS_TO_TICKS(80)
        );


    // No response
    if (len <= 0)
    {
        return false;
    }


    // Minimum Modbus response:
    //
    // ID + Function + Byte Count
    // + Data(2) + CRC(2)
    //
    // Total = 7 bytes

    if (len < 7)
    {
        return false;
    }


    // Check Slave ID
    if (response[0] != slave_id)
    {
        return false;
    }


    // Check Function Code
    if (response[1] != 0x03)
    {
        return false;
    }


    // CRC Check
    if (!check_crc(response, len))
    {
        ESP_LOGW(
            TAG,
            "ID %d responded but CRC invalid",
            slave_id
        );

        return false;
    }


    // ========================================================
    // SENSOR FOUND
    // ========================================================

    ESP_LOGI(
        TAG,
        "****************************************"
    );

    ESP_LOGI(
        TAG,
        "SENSOR FOUND!"
    );

    ESP_LOGI(
        TAG,
        "SLAVE ID = %d",
        slave_id
    );

    ESP_LOGI(
        TAG,
        "RESPONSE LENGTH = %d",
        len
    );


    printf("RX: ");

    for (int i = 0; i < len; i++)
    {
        printf(
            "%02X ",
            response[i]
        );
    }

    printf("\n");


    ESP_LOGI(
        TAG,
        "****************************************"
    );

    return true;
}


// ============================================================
// MAIN
// ============================================================

void app_main(void)
{
    ESP_LOGI(TAG, "=================================");
    ESP_LOGI(TAG, "MODBUS SLAVE ID SCANNER");
    ESP_LOGI(TAG, "HONDE 8-IN-1 SOIL SENSOR");
    ESP_LOGI(TAG, "=================================");


    // Initialize UART

    if (
        modbus_uart_init()
        != ESP_OK
    )
    {
        ESP_LOGE(
            TAG,
            "UART INIT FAILED!"
        );

        return;
    }


    // Wait after sensor power ON

    ESP_LOGI(
        TAG,
        "Waiting for sensor..."
    );

    vTaskDelay(
        pdMS_TO_TICKS(3000)
    );


    // ========================================================
    // SCAN SLAVE IDS
    // ========================================================

    ESP_LOGI(
        TAG,
        "Starting Slave ID Scan..."
    );


    bool found = false;


    for (
        uint16_t id = 1;
        id <= 254;
        id++
    )
    {
        if (
            scan_slave(
                (uint8_t)id
            )
        )
        {
            found = true;

            ESP_LOGI(
                TAG,
                "FOUND ID = %d",
                id
            );

            // Agar sirf aik sensor connected hai
            // to scan yahan stop kar do

            break;
        }


        // Small delay between requests

        vTaskDelay(
            pdMS_TO_TICKS(20)
        );
    }


    // ========================================================
    // RESULT
    // ========================================================

    if (found)
    {
        ESP_LOGI(
            TAG,
            "================================="
        );

        ESP_LOGI(
            TAG,
            "SCAN COMPLETE"
        );

        ESP_LOGI(
            TAG,
            "SENSOR FOUND SUCCESSFULLY"
        );

        ESP_LOGI(
            TAG,
            "================================="
        );
    }
    else
    {
        ESP_LOGE(
            TAG,
            "================================="
        );

        ESP_LOGE(
            TAG,
            "NO SENSOR FOUND!"
        );

        ESP_LOGE(
            TAG,
            "Check:"
        );

        ESP_LOGE(
            TAG,
            "1. RS485 A/B wiring"
        );

        ESP_LOGE(
            TAG,
            "2. Sensor power"
        );

        ESP_LOGE(
            TAG,
            "3. Baud rate"
        );

        ESP_LOGE(
            TAG,
            "4. DE/RE control"
        );

        ESP_LOGE(
            TAG,
            "5. TX/RX wiring"
        );

        ESP_LOGE(
            TAG,
            "================================="
        );
    }
}

 