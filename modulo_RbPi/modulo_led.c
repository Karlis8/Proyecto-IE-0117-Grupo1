#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/init.h>
#include <linux/fs.h>
#include <linux/uaccess.h>
#include <linux/gpio.h>
#include <linux/device.h>

#define GPIO_NUM 27
#define DEVICE_NAME "led_control"
#define CLASS_NAME "led"

static int majorNumber;
static struct class* ledClass = NULL;
static struct device* ledDevice = NULL;

static int dev_open(struct inode *inodep, struct file *filep) {
    printk(KERN_INFO "LED: Encendiendo LED (GPIO %d)\n", GPIO_NUM);
    gpio_set_value(GPIO_NUM, 1);
    return 0;
}

static int dev_release(struct inode *inodep, struct file *filep) {
    printk(KERN_INFO "LED: Apagando LED (GPIO %d)\n", GPIO_NUM);
    gpio_set_value(GPIO_NUM, 0);
    return 0;
}

static struct file_operations fops = {
    .open = dev_open,
    .release = dev_release,
};

static int __init led_init(void) {
    printk(KERN_INFO "LED: Inicializando módulo...\n");

    // Solicita el GPIO
    if (!gpio_is_valid(GPIO_NUM)) {
        printk(KERN_ALERT "LED: GPIO %d no es válido.\n", GPIO_NUM);
        return -ENODEV;
    }

    gpio_request(GPIO_NUM, "sysfs");
    gpio_direction_output(GPIO_NUM, 0); // Apagado inicialmente
    gpio_export(GPIO_NUM, false);       // Si falla, comentar esta línea

    // Registrar dispositivo de caracteres
    majorNumber = register_chrdev(0, DEVICE_NAME, &fops);
    if (majorNumber < 0) {
        printk(KERN_ALERT "LED: Falló registro de número mayor\n");
        return majorNumber;
    }

    ledClass = class_create(CLASS_NAME);
    if (IS_ERR(ledClass)) {
        unregister_chrdev(majorNumber, DEVICE_NAME);
        printk(KERN_ALERT "LED: Falló creación de clase\n");
        return PTR_ERR(ledClass);
    }

    ledDevice = device_create(ledClass, NULL, MKDEV(majorNumber, 0), NULL, DEVICE_NAME);
    if (IS_ERR(ledDevice)) {
        class_destroy(ledClass);
        unregister_chrdev(majorNumber, DEVICE_NAME);
        printk(KERN_ALERT "LED: Falló creación del dispositivo\n");
        return PTR_ERR(ledDevice);
    }

    printk(KERN_INFO "LED: Módulo cargado correctamente con device /dev/%s\n", DEVICE_NAME);
    return 0;
}

static void __exit led_exit(void) {
    gpio_set_value(GPIO_NUM, 0);
    gpio_unexport(GPIO_NUM); // Si falla, comentar esta línea
    gpio_free(GPIO_NUM);

    device_destroy(ledClass, MKDEV(majorNumber, 0));
    class_unregister(ledClass);
    class_destroy(ledClass);
    unregister_chrdev(majorNumber, DEVICE_NAME);

    printk(KERN_INFO "LED: Módulo descargado correctamente.\n");
}

module_init(led_init);
module_exit(led_exit);

MODULE_LICENSE("GPL");
MODULE_AUTHOR("Karla Méndez");
MODULE_DESCRIPTION("Módulo de kernel que enciende y apaga LED desde user space.");
MODULE_VERSION("0.2");
