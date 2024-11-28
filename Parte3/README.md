#  Laboratorio 3 / Parte 3 / Lectura de un sensor de luminosidad


## 1. Abreviaturas y definiciones
- **FPGA**: Field Programmable Gate Arrays.
- **SPI**: Serial Peripheral Interface
- **UART**: Universal Asynchronous Receiver-Transmitter.
- **ALS**: Ambient Light Sensor

## 2. Referencias
[0] David Harris y Sarah Harris. *Digital Design and Computer Architecture. RISC-V Edition.* Morgan Kaufmann, 2022. ISBN: 978-0-12-820064-3

## 3. Criterios de diseño

Para el diseño de este sistema es necesario juntar las interfaces SPI e UART dentro de un solo bloque, además del uso de un PMOD-ALS que realizará las mediciones correspondientes.
Ambas interfaces deben estar funcionando correctamente, con el SPI se recibe el dato capturado por el sensor y con el UART se envia a la computadora, por lo que se deben realizar ciertos ajustes a los bloques desarrollados en las primeras partes del laboratorio, pero estos son mínimos.
Es necesaria la implementación de una máquina de estados que lleve el control de todo este proceso, ya que este debe ser automático y debe tomar muestras de luz cada segundo, por lo que un contador será necesario también.

La implementación del sistema se resume en el siguiente diagrama de bloques.

![bloques_sensor](https://github.com/EL3313/laboratorio3-equipo-4/assets/112665832/f5d437d8-cab5-40ca-9943-cb24875e4e4d)

Al sistema se le añadirán también los bloques necesarios para que el dato capturado por el sensor sea mostrado tanto en leds, para saber su valor binario, como en el display de 7 segmentos de la FPGA, utilizando un convertidor BCD para observar el dato en decimal.

## 4. Desarrollo

### 4.1 Módulo "fsm_sensor"
#### 1. Encabezado del módulo
```
module fsm_sensor (
    input logic clk,
    input logic rst,
    input logic conto1,  

    output logic send_spi,       
    output logic send_uart,   
    output logic cuente1,     
    output logic lab3
);
```

#### 2. Entradas y salidas:
- `clk`: Reloj de la FPGA.
- `rst`: Señal de reset.
- `conto1`: Señal que le indica a la máquina cuando el contador haya contado un segundo.
- `send_spi`: Señal que habilita la interfaz SPI.
- `send_uart`: Señal que habilita la transmisión UART.
- `cuente1`: Señal que le indica al contador que empiece la cuenta de un segundo.
- `lab3`: Señal que le indica al SPI que registro utilizará para el dato del sensor.

#### 3. Criterios de diseño

Se realizó un diagrama de estados para la máquina correspondiente, la cual no representa una alta complejidad, consta de una sola entrada que es será una señal proveniente del contador que le indicará cuando haya pasado el segundo necesario para la siguiente muestra.
Con respecto a las salidas, se tendrá una salida llamada *send_spi* que le indicará a la interfaz SPI cuando tomar el dato capturado por el PMOD-ALS, una señal *send_uart* que le indica a la interfaz UART cuando mandar el dato correspondiente, una señal *cuente1* que le indicará al contador de 1 segundo cuando debe realizar la cuenta y otra señal llamada *lab3* que se utiliza para indicarle al registro de datos de la interfaz SPI que siempre apunte al registro 00 ya que solo se trabajará con este.
El diagrama de estados es el siguiente.

![fsm_sensor](https://github.com/EL3313/laboratorio3-equipo-4/assets/112665832/000d821b-339e-4c08-8dd0-610ccec5d1de)

El hecho de tener como entrada solamente la señal *conto1* del contador es lo que le permite al sistema trabajar de manera automática y realizar la toma de los datos cada segundo, las interfaces SPI y UART se ajustaron ligeramente para que todo se haga automáticamente. La interfaz SPI recibe el dato del sensor cada vez que la máquina de estados habilite la señal *send_spi*, por su parte la transmisión se realiza cuando *send_uart* se activa en 1 y durará solo un ciclo de reloj, ya que esta señal debe trabajar como si fuera un botón.

### 4.2 Módulo "top_sensor"
#### 1. Encabezado del módulo
```
module top_sensor (
    input logic i_clk,
    input logic rst,
    
    output logic [7:0] salida_o_leds,
    
    // Puertos SPI
    input logic i_SPI_MISO,
    output logic o_SPI_Clk,
    output logic o_SPI_MOSI,
    output logic C_Select,
    
    //del uart :
    input logic rx,
    output logic tx,
    output logic [7:0] leds_uart,

    // Del Display

    output logic a, b, c, d, e, f, g,
    output logic [7:0] AN 

);
```

#### 2. Entradas y salidas:
- `i_clk`: Reloj de la FPGA.
- `rst`: Señal de reset.
- `salida_o_leds`: Dato proveniente del PMOS-ALS.
- `i_SPI_MISO`: Señal de MISO para el SPI.
- `o_SPI_Clk`: Señal de SPI clk para el SPI slave.
- `o_SPI_MOSI`: Señal de MOSI para el SPI.
- `C_Select`: Señal del Chip Selcet.
- `rx`: Señal de un bit que recibe el dato de la computadora bit por bit.
- `tx`: Señal de salida que envia bit por bit el dato deseado por el usuario.
- `leds_uart`: Señal de 8 bits que almacena el dato recibido.
- `a, b, c, d, e, f, g`: Salidas para el 7 segmentos.
- `AN`: Puertos para controlar los nodos comunes

#### 3. Criterios de diseño

Para el diseño de este módulo se realizó las instancias de las interfaces UART y SPI, así como el módulo de la máquina de estados explicado anteriormente. También, se realizaron las instancias de los bloques necesarios para utilizar el display de 7 segmentos, el contador de 1 segundo y el convertidor BCD.
Este módulo se encarga de conectar el valor obtenido del PMOD-ALS, el cual se captura con la interfaz SPI y así enviarlo através de la interfaz UART hacia la computadora, también se utilizan variables locales para pasar el dato del sensor por el convertidor BCD, con el fin de no modificar erroneamente este valor. La instancia de la máquina de estados le permite al contador de 1 segundo estar realizando la cuenta continuamente y así indicarle al sistema cuando debe capturar y mostrar un nuevo dato, así todo el proceso se realiza de manera automática.

```
top unidad_top_uart_DUT (
    .rst(rst),
    .clk(clk),
    .boton_send(send_uart),
    .dato(salida_o_leds),
    .rx(rx),
    .tx(tx),
    .leds(leds_uart)
);

top_interfaz_periferico_spi #(.N(7),.switches(16)
) top_spi_inst(
    .clk(clk),
    .rst(rst),

    // Generador de datos y control de prueba
//    .wr_btn(wr_btn),
//    .reg_sel_i(reg_sel_i),
//    .switches_in(switches_in),
    .t_out_data_7(salida_o_leds),
    
    // Puertos SPI
    .i_SPI_MISO(i_SPI_MISO),
    .o_SPI_Clk(o_SPI_Clk),
    .o_SPI_MOSI(o_SPI_MOSI),
    .C_Select(C_Select),

    // Para el lab 3
    .send_spi(send_spi),
    .lab3(lab3)
);


fsm_sensor unidad_fsm_sensor_DUT( 
    .clk(clk),
    .rst(rst),
    .conto1(conto1),  //             <<-- viene del detector de pulso
    .send_spi(send_spi),
    .send_uart(send_uart),
    //.cuente1(cuente1),            <<-- no hace falta, siempre está contando
    .lab3(lab3)
);
```

