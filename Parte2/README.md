#  Laboratorio 3 / Parte 2 / Interfaz UART


## 1. Abreviaturas y definiciones
- **FPGA**: Field Programmable Gate Arrays.
- **UART**: Universal Asynchronous Receiver-Transmitter.

## 2. Referencias
[0] David Harris y Sarah Harris. *Digital Design and Computer Architecture. RISC-V Edition.* Morgan Kaufmann, 2022. ISBN: 978-0-12-820064-3

## 3. Criterios de diseño
Para el diseño del sistema UART completo se realizaron dos grandes sub-bloques, la parte relacionada con toda la interfaz del protocolo UART, llamada IPU, la cual se encarga de realizar las transmisiones y recepciones al sistema externo que en este caso es una computadora personal, y una sección llamada generador de pruebas la cual se encarga de crear el dato que el usuario desea transmitir al computador mediante el uso de switches en la FPGA, así como ser capaz de mostrar el dato recibido utilizando los leds de la FPGA. Teniendo estos dos bloques se unirán en un módulo top que se encargará de conectarlos adecuadamente para que el sistema completo funcione correctamente. Estos dos bloques cuentan cada uno con una máquina de estados, las cuales se detallan a continuación.

La máquina de estados del bloque IPU se encarga de monitorear las señales *tx_rdy* y *rx_data_rdy*, las cuales son señales propias de los bloques del UART que indican que la transmisión y la recepción se han realizado correctamente, al mismo tiempo monitorea el registro de control que se encarga de las señales *new_rx* que indica cuando se recibió un dato y *send* que se encarga de enviar un dato a la computadora, al mismo tiempo estas son salidas de la máquina de estados para que sean ajustadas de acuerdo al procedimiento realizado durante el protocolo. También cuenta con señales de habilitación de escritura tanto para el registro de control como para el registro de datos, una señal de dirección *addr2* que indica a cual registro el sistema debe almacenar el dato recibido y la señal *tx_start* que indica que la transmisión a la computadora debe iniciar. El diagrama de esta máquina de estados es el siguiente.

![fsm](https://github.com/EL3313/laboratorio3-equipo-4/assets/112665832/5becc041-35c8-4bca-87a8-1876fc5eb472)

Por su parte, la máquina de estados del generador de pruebas se encarga de monitorear un botón llamado *Boton_send* el cual es el que el usuario utiliza cuando quiere realizar la transmisión de un dato a la computadora, también monitorea las señales *new_rx* y *send* para llevar un control en el cuando se recibió un dato o se está transmitiendo. Las salidas de esta máquina de estados contienen un habilitador de escritura *wr_i* y una señal de selección *reg_sel_i*, estas se utilizarán para indicarle al sistema cuando y donde debe escribir, además de permitir observar el valor del dato recibido que debe ser mostrado en los leds de la FPGA, una señal llamada *addr_i* que le indicará al sistema si se trabajará sobre el registro que tiene el dato recibido o el registro con el dato por transmitir y una señal de dos bits *selec*, esta se utiliza para indicarle a un mux si debe dejar pasar el dato que el usuario desea transmitir o una cierta configuración para el registro de control, dependiendo del estado en el que se encuentre. El diagrama es el siguiente.

![fsm_pruebas](https://github.com/EL3313/laboratorio3-equipo-4/assets/112665832/2035931b-b46f-4d2d-88dd-7b7e928ca687)


## 4. Desarrollo

### 4.1 Módulo "top "
#### 1. Encabezado del módulo
```
module top (
    input logic clk, rst,
    input logic boton_send,

    input logic [7:0] dato,

    input logic rx,
    output logic tx,

    output logic [7:0] leds

);
```

#### 2. Entradas y salidas:
- `clk`: Reloj de la FPGA.
- `rst`: Señal de reset del UART, se asigna a un push button.
- `boton_send`: Señal para que el sistema transmita el dato deseado, se asigna a un push button.
- `dato`: Dato de 8 bits que el usuario desea transmitir, se le asignan 8 switches de la FPGA.
- `rx`: Señal de un bit que recibe el dato de la computadora bit por bit.
- `tx`: Señal de salida que envia bit por bit el dato deseado por el usuario.
- `leds`: Señal de 8 bits que almacena el dato recibido, se le asignan 8 leds de la FPGA para que sea mostrado.

#### 3. Criterios de diseño

Este módulo top se diseñó realizando las instancias correspondientes de los dos bloques principales del sistema, el bloque IPU y el generador de pruebas.

```
gen_pruebas unidad_pruebas (
    .clk(clk),
    .rst(rst),
    .salida_o(salida_o_in), 
    .boton_send(boton_send),
    .dato(dato),

    .wr_i(wr_i_in),
    .reg_sel_i(reg_sel_i_in), 
    .addr_i(addr_i_in), 
    .entrada_i(entrada_i_in),
    .leds(leds)
);

IPU unidad_IPU (

    .clk(clk),
    .rst(rst),
    
    .wr_i(wr_i_in),
    .reg_sel_i(reg_sel_i_in),
    .entrada_i(entrada_i_in), 
    .addr_i(addr_i_in),

    .salida_o(salida_o_in),
    
    .rx(rx),
    .tx(tx)
);
```

### 4.2 Módulo "fsm "
#### 1. Encabezado del módulo
```
module fsm (
    input logic clk,
    input logic rst,
    input logic [31:0] out_c,
    input logic rx_data_rdy, 
    input logic tx_rdy,     

    output logic [1:0] new_rx_send, 
    output logic we_c, we_d,   
    output logic addr2,  
    output logic tx_start  
);
```

#### 2. Entradas y salidas:
- `clk`: Señal de reloj
- `rst`: Señal de reset
- `out_c`: Salida del registro de control
- `rx_data_rdy`: Señal que indica que la recepción finalización
- `tx_rdy`: Señal que indica que la transmisión finalización
- `new_rx_send`: Señales del registro de control
- `we_c y we_d`:Señales de habilitación de escritura en control y datos respectivos
- `addr2`: Dirección de escritura registro de datos
- `tx_start`: Señal para comenzar la transmisión


#### 3. Criterios de diseño
Esta máquina de estados se diseñó mediante dos estados, uno llamado 'sin comunicación' o IDLE y otro estado de 'transmisión'. El diseño se realizó contemplando la capacidad de poder recibir un dato a la vez de poder recibir una petición de transmisión, para ello, cuando undato ha sido recibido satisfactoriamente se puede capturar el dato y actualizar el valor del registro de control únicamente mediante un ciclo de reloj, sin afectar el proceso de transmisión, de modo que es posible controlar la comunicación UART únicamente mediante 2 estados con una maquina de MEALEY. 

### 4.3 Módulo "fsm_pruebas "
#### 1. Encabezado del módulo
```
module fsm_pruebas (
    input logic clk,
    input logic rst,
    input logic boton_send,         
    input logic [31:0] salida_o,   

    output logic wr_i,        
    output logic reg_sel_i,   
    output logic addr_i,      
    output logic [1:0] selec  
);
```

#### 2. Entradas y salidas:
- `clk`: Señal de reloj.
- `rst`: Señal de reset.
- `boton_send`: Señal del botón presionado por el usuario, proveniente del módulo top.
- `salida_o`: Entrada que puede ser el valor del registro de control o el valor del dato recibido de la computadora.
- `wr_i`: Señal habilitadora de escritura.
- `reg_sel_i`: Señal que permite escoger entre registro de control o registro de datos.
- `addr_i`: Señal de dirección para el registro de datos.
- `selec`: Señal selectora de un mux para ajustar el registro de control o dejar pasar el dato por transmitir.

#### 3. Criterios de diseño

Para el diseño de esta máquina de estados se decidió utilizar la estructura de una máquina de Mealy, de esta manera se consideran los cambios necesarios en las transiciones de estado para aquellas señales que se necesitan en un cierto valor durante un solo ciclo de reloj, se implementó la máquina del segundo diagrama mostrado anteriormente.

Es importante destacar la señal de entrada *salida_o*, esta es una señal de 32 bits que puede tomar el valor del registro de control o del dato recibido de la computadora, por lo que se decidió tomar en cuenta dos señales intermedias que consideraran los 2 bits menos significativos para los casos en que esta sea el valor del registro de control ya que estos corresponden al new_rx y send, para esto se define con el *reg_sel_i*, el cual en su mayoría estará en 0 ya que se deben monitorear estas señales.

```
logic send;
assign send = salida_o [0];
logic new_rx;
assign new_rx = salida_o [1];
```

Cuando la señal *reg_sel_i* se encuentre en 1 la máquina de estados le permitirá a un registro específico para los leds capturar el dato que ahora si se mostrará en la señal *salida_o*, permitiendo así mostrarlo en los leds de la FPGA.

#### 5. Testbench

Se realizó un testbench que permitierá observar la transmisión y recepción de datos, el sistema realiza todo el proceso de manera correcta y muestra en los leds de la FPGA el dato recibido, además de capturar correctamente el dato que se enviará de los switches de la FPGA.

![simulacion_top](https://github.com/EL3313/laboratorio3-equipo-4/assets/112665832/c60868f0-92ef-4d67-9230-6a52977b2bb1)
