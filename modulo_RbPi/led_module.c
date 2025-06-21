#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/fs.h>
#include <linux/init.h>
#include <linux/gpio.h>             // API GPIO antigua
#include <linux/uaccess.h>         // copy_from_user
#include <linux/device.h>          // device class

#define DEVICE_NAME "led_control"
#define CLASS_NAME "led"

// Cambiamos GPIO27 por su mapeo correspondiente en el kernel
#define LED_GPIO 539

static int majorNumber;
static struct class*  ledClass  = NULL;
static struct device* ledDevice = NULL;

static ssize_t dev_write(struct file *filep, const char *buffer, size_t len, loff_t *offset) {
    char command[4] = {0};

    if (len > 3)
        len = 3;

    if (copy_from_user(command, buffer, len)) {
        return -EFAULT;
    }

    if (strncmp(command, "on", 2) == 0) {
        gpio_set_value(LED_GPIO, 1);
    } else if (strncmp(command, "off", 3) == 0) {
        gpio_set_value(LED_GPIO, 0);
    } else {
        printk(KERN_INFO "led_module: Comando inválido. Use 'on' o 'off'.\n");
    }

    return len;
}

static struct file_operations fops = {
    .owner = THIS_MODULE,
    .write = dev_write,
};

static int __init led_init(void) {
    printk(KERN_INFO "led_module: Iniciando módulo GPIO539...\n");

    if (!gpio_is_valid(LED_GPIO)) {
        printk(KERN_ALERT "led_module: GPIO %d no es válido\n", LED_GPIO);
        return -ENODEV;
    }

    if (gpio_request(LED_GPIO, "led_gpio") < 0) {
        printk(KERN_ALERT "led_module: No se pudo solicitar GPIO %d\n", LED_GPIO);
        return -EBUSY;
    }

    gpio_direction_output(LED_GPIO, 0); // LED apagado al iniciar

    majorNumber = register_chrdev(0, DEVICE_NAME, &fops);
    if (majorNumber < 0) {
        gpio_free(LED_GPIO);
        printk(KERN_ALERT "led_module: Falló al registrar major number\n");
        return majorNumber;
    }

    ledClass = class_create(CLASS_NAME);
    if (IS_ERR(ledClass)) {
        unregister_chrdev(majorNumber, DEVICE_NAME);
        gpio_free(LED_GPIO);
        printk(KERN_ALERT "led_module: Falló al crear clase\n");
        return PTR_ERR(ledClass);
    }

    ledDevice = device_create(ledClass, NULL, MKDEV(majorNumber, 0), NULL, DEVICE_NAME);
    if (IS_ERR(ledDevice)) {
        class_destroy(ledClass);
        unregister_chrdev(majorNumber, DEVICE_NAME);
        gpio_free(LED_GPIO);
        printk(KERN_ALERT "led_module: Falló al crear el dispositivo\n");
        return PTR_ERR(ledDevice);
    }

    printk(KERN_INFO "led_module: Dispositivo listo en /dev/%s\n", DEVICE_NAME);
    return 0;
}

static void __exit led_exit(void) {
    gpio_set_value(LED_GPIO, 0);
    gpio_free(LED_GPIO);

    device_destroy(ledClass, MKDEV(majorNumber, 0));
    class_unregister(ledClass);
    class_destroy(ledClass);
    unregister_chrdev(majorNumber, DEVICE_NAME);

    printk(KERN_INFO "led_module: Módulo descargado.\n");
}

module_init(led_init);
module_exit(led_exit);

MODULE_LICENSE("GPL");
MODULE_AUTHOR("EquipoMaravilla");
MODULE_DESCRIPTION("Módulo kernel simple para controlar LED en GPIO27 (remapeado como GPIO539)");
MODULE_VERSION("3.0");
