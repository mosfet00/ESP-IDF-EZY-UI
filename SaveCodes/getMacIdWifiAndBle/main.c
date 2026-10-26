/* Standalone production program. This file is not part of the RootIQ firmware build. */
#include <stdio.h>
#include "sdkconfig.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "esp_system.h"
#include "esp_mac.h"
#include "esp_flash.h"

static void print_mac(const char *label, esp_mac_type_t type)
{
    uint8_t mac[6] = {0};

    if (esp_read_mac(mac, type) != ESP_OK) {
        printf("%s: read failed\n", label);
        return;
    }

    printf("%s: %02X:%02X:%02X:%02X:%02X:%02X\n",
           label, mac[0], mac[1], mac[2], mac[3], mac[4], mac[5]);
}

void app_main(void)
{
    esp_chip_info_t chip_info;
    uint32_t flash_size = 0;

    printf("Hello world!\n");

    esp_chip_info(&chip_info);
    printf("This is %s chip with %d CPU core(s), WiFi%s%s, ",
           CONFIG_IDF_TARGET,
           chip_info.cores,
           (chip_info.features & CHIP_FEATURE_BT) ? "/BT" : "",
           (chip_info.features & CHIP_FEATURE_BLE) ? "/BLE" : "");

    printf("silicon revision v%d.%d, ",
           chip_info.revision / 100,
           chip_info.revision % 100);

    esp_flash_get_size(NULL, &flash_size);
    printf("%luMB %s flash\n",
           (unsigned long)(flash_size / (1024 * 1024)),
           (chip_info.features & CHIP_FEATURE_EMB_FLASH) ? "embedded" : "external");

    print_mac("WiFi MAC", ESP_MAC_WIFI_STA);
    print_mac("Bluetooth MAC", ESP_MAC_BT);
}
