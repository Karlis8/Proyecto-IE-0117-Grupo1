#include <linux/module.h>
#include <linux/fs.h>
#include <linux/uaccess.h>
#include <linux/gpio.h>
#include <linux/init.h>
#include <linux/device.h>

#define DEVICE_NAME "led_control"
#define CLASS_NAME  "led"

#define GPIO_NUM 27  // Número del pin GPIO conectado al LED

static int majorNumber;
static struct class*  ledClass  = NULL;
static struct device* ledDevice = NULL;

// Función que se ejecuta cuando se escribe en el archivo /dev/led_control
static ssize_t dev_write(struct file *filep, const char *buffer, size_t len, loff_t *offset) {
    char command;

    if (copy_from_user(&command, buffer, 1)) {
        return -EFAULT;
    }

    if (command == '1') {
        gpio_set_value(GPIO_NUM, 1);
        printk(KERN_INFO "LED encendido\n");
    } else if (command == '0') {
        gpio_set_value(GPIO_NUM, 0);
        printk(KERN_INFO "LED apagado\n");
    } else {
        printk(KERN_WARNING "Comando no válido. Use '1' o '0'\n");
    }

    return len;
}

// Estructura de operaciones del archivo
static struct file_operations fops = {
    .write = dev_write,
};

// Función de inicialización del módulo
static int __init led_init(void) {
    printk(KERN_INFO "Iniciando módulo LED para Raspberry Pi\n");

    if (!gpio_is_valid(GPIO_NUM)) {
        printk(KERN_ALERT "GPIO %d no es válido\n", GPIO_NUM);
        return -ENODEV;
    }

    gpio_request(GPIO_NUM, "sysfs");
    gpio_direction_output(GPIO_NUM, 0);
    gpio_export(GPIO_NUM, false);

    majorNumber = register_chrdev(0, DEVICE_NAME, &fops);
    if (majorNumber < 0) {
        printk(KERN_ALERT "Fallo al registrar el número mayor\n");
        return majorNumber;
    }

    ledClass = class_create(THIS_MODULE, CLASS_NAME);
    if (IS_ERR(ledClass)) {
        unregister_chrdev(majorNumber, DEVICE_NAME);
        return PTR_ERR(ledClass);
    }

    ledDevice = device_create(ledClass, NULL, MKDEV(majorNumber, 0), NULL, DEVICE_NAME);
    if (IS_ERR(ledDevice)) {
        class_destroy(ledClass);
        unregister_chrdev(majorNumber, DEVICE_NAME);
        return PTR_ERR(ledDevice);
    }

    printk(KERN_INFO "/dev/%s creado correctamente\n", DEVICE_NAME);
    return 0;
}

// Función de salida del módulo
static void __exit led_exit(void) {
    gpio_set_value(GPIO_NUM, 0);
    gpio_unexport(GPIO_NUM);
    gpio_free(GPIO_NUM);
    device_destroy(ledClass, MKDEV(majorNumber, 0));
    class_unregister(ledClass);
    class_destroy(ledClass);
    unregister_chrdev(majorNumber, DEVICE_NAME);
    printk(KERN_INFO "Módulo LED descargado\n");
}

module_init(led_init);
module_exit(led_exit);

MODULE_LICENSE("GPL");
MODULE_AUTHOR("Karla Méndez");
MODULE_DESCRIPTION("Módulo de kernel para controlar LED desde /dev/led_control en Raspberry Pi 4");
