#include <zephyr/init.h>
#include <zephyr/device.h>
#include <zephyr/devicetree.h>
#include <zephyr/drivers/gpio.h>

#include <zephyr/logging/log.h>
LOG_MODULE_DECLARE(zmk, CONFIG_ZMK_LOG_LEVEL);

#include <zmk/keymap.h>
#include <zmk/event_manager.h>
#include <zmk/events/layer_state_changed.h>

/* LED aliases from the board devicetree */
#define LED1_NODE DT_ALIAS(led1)
#define LED2_NODE DT_ALIAS(led2)
#define LED3_NODE DT_ALIAS(led3)

/* Zephyr 3.5 gpio_dt_spec API replaces device_get_binding + DT_GPIO_LABEL */
static const struct gpio_dt_spec led1 = GPIO_DT_SPEC_GET(LED1_NODE, gpios);
static const struct gpio_dt_spec led2 = GPIO_DT_SPEC_GET(LED2_NODE, gpios);
static const struct gpio_dt_spec led3 = GPIO_DT_SPEC_GET(LED3_NODE, gpios);

/* Layer indices — update these to match your keymap */
#define LAYER_NAV 1
#define LAYER_NUM 2
#define LAYER_SYM 3

static int led_event_handler(const zmk_event_t *eh)
{
    const uint8_t layer = zmk_keymap_highest_layer_active();
    gpio_pin_set_dt(&led1, layer == LAYER_NUM);
    gpio_pin_set_dt(&led2, layer == LAYER_SYM);
    gpio_pin_set_dt(&led3, layer == LAYER_NAV);
    return 0;
}

static int led_init(const struct device *dev)
{
    ARG_UNUSED(dev);

    if (!gpio_is_ready_dt(&led1) || !gpio_is_ready_dt(&led2) || !gpio_is_ready_dt(&led3))
    {
        return -ENODEV;
    }

    gpio_pin_configure_dt(&led1, GPIO_OUTPUT_INACTIVE);
    gpio_pin_configure_dt(&led2, GPIO_OUTPUT_INACTIVE);
    gpio_pin_configure_dt(&led3, GPIO_OUTPUT_INACTIVE);

    return 0;
}

ZMK_LISTENER(led, led_event_handler);

#ifdef CONFIG_ZMK_SPLIT_BLE_ROLE_CENTRAL
ZMK_SUBSCRIPTION(led, zmk_layer_state_changed);
#endif

SYS_INIT(led_init, APPLICATION, CONFIG_APPLICATION_INIT_PRIORITY);
