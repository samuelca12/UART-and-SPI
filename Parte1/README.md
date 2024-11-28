#  Laboratorio 3 / Parte 1 / Interfaz SPI Maestro - Genérica


## 1. Abreviaturas y definiciones
- **FPGA**: Field Programmable Gate Arrays.
- **Switch**: dsipositivo que enlaza o abre el circuito entre dos posiciones.
- **SPI**: Serial Peripheral Interface.
- **MOSI**: Master output, slave input.
- **MISO**: Master input, slave out.

## 2. Referencias
[0] David Harris y Sarah Harris. *Digital Design and Computer Architecture. RISC-V Edition.* Morgan Kaufmann, 2022. ISBN: 978-0-12-820064-3

## 3. Desarrollo


### 3.1 Módulo "top_interfaz_periferico_spi "
#### 1. Encabezado del módulo
```
module top_interfaz_periferico_spi #(
    parameter N = 7,
    parameter switches = 16
)(
    input logic         clk_fpga,
    input logic         rst,

    // Generador de datos y control de prueba
    input logic         wr_btn,
    input logic         reg_sel_i,
    input logic  [switches-2:0] switches_in,

    output logic [15:0] salida_o_leds,

    // Puertos SPI
    //input logic i_SPI_MISO,
    output logic o_SPI_Clk,
    output logic o_SPI_MOSI,
    output logic C_Select
); 
```
Son las entradas y salidas que se asignarán en la FPGA para la generación de pruebas 



#### 2. Entradas y salidas:
- `clk_fpga`: Reloj de la FPGA.
- `rst`: Señal de reset del SPI, se asigna a un push button.
- `wr_btn`: Señal de enable para los registros, se asigna a un push button.
- `reg_sel_i`: Señal para seleccionar el registro sobre el que se quiere escribir los datos, se asgina a un switch.
- `[switches-2:0] switches_in`: Señal se switches, son los datos que se van a escribir en los registros.
- `[15:0] salida_o_leds`: Señal de los leds para mostrar la salida de forma binaria, se muestra lo almacenado en el registro de datos.
- `i_SPI_MISO`: Señal de MISO para el SPI.
- `o_SPI_Clk`: Señal de SPI clk para el SPI slave.
- `o_SPI_MOSI`: Señal de MOSI para el SPI.
- `C_Select`: Señal del Chip Selcet.

#### 3. Criterios de diseño
El modulo es el encargado de hacer el llamado de todos los demás y enlazarlos 



### 3.2 Módulo "SPI_Master"
#### 1. Encabezado del módulo
```
module SPI_Master
  #(
    parameter CLKS_PER_HALF_BIT = 500)
  (
   
   input        rst,     //Reset
   input        Clk,       //Clock
   
   // TX se�ales para mosi
   input [7:0]  i_TX_Byte,        // Byte a transmitir en MOSI
   input logic inicio,          // Pulso de Datos V�lidos con i_TX_Byte
        
   
   input logic All_in1, All_in0,cs_ctrl,
   
   // RX se�ales para miso
   output logic       o_RX_DV,     // Pulso de Datos V�lidos (1 ciclo de reloj)
   output logic [7:0] o_RX_Byte,   // Byte recibido en MISO

   // SPI 
   output logic o_SPI_Clk,
   input  logic i_SPI_MISO,
   output logic o_SPI_MOSI,
   output logic CSelect          //Se�al Chip Select
   ); 

```



#### 2. Entradas y salidas:
- `Clk`: Reloj del sistema.
- `rst`: Señal de reset del SPI.
- `i_TX_Byte`: Byte de 8 bits que se desea transmitir a través de la línea MOSI.
- `inicio`: Señal de entrada que indica el inicio de una nueva transmisión.
- `All_in1`: Señal de entrada que habilita enviar todos los datos en 1.
- `All_in0`: Señal de entrada que habilita enviar todos los datos en 0.
- `cs_ctrl`: Señal de control que determina la lógica de la señal de Chip Select
- `o_RX_DV`: Señal de salida que indica que un nuevo byte de datos ha sido recibido a través de la línea MISO. 
- `o_RX_Byte`: Byte de 8 bits que contiene los datos recibidos a través de la línea MISO.
- `o_SPI_Clk`: Señal de reloj SPI generada por el módulo, utilizada para sincronizar la comunicación con el dispositivo esclavo.
- `i_SPI_MOSI`: Señal de entrada que recibe los datos del dispositivo esclavo a través de la línea MISO.
- `o_SPI_MOSI`: Señal de salida que transmite los datos al dispositivo esclavo a través de la línea MOSI
- `C_Select`: Señal del Chip Select.

#### 3. Criterios de diseño
EL modulo implemente un controlador maestro para una comunicación SPI, se presenta un resumen de sus funciones:

1. **Generación de señal de reloj SPI**: El módulo genera una señal de reloj SPI (`o_SPI_Clk`) con una frecuencia determinada por el parámetro `CLKS_PER_HALF_BIT`. La generación de la señal de reloj se realiza contando los ciclos de reloj del sistema y alternando la señal de reloj SPI en los flancos ascendente y descendente.

2. **Transmisión de datos (MOSI)**: El módulo permite transmitir un byte de datos (`i_TX_Byte`) a través de la línea MOSI (Master Output, Slave Input).

3. **Recepción de datos (MISO)**: El módulo puede recibir un byte de datos (`o_RX_Byte`) a través de la línea MISO (Master Input, Slave Output). 
4. **Generación de señal de Chip Select**: El módulo genera una señal de Chip Select (`CSelect`) para seleccionar el dispositivo esclavo con el que se desea comunicar. Esta señal se activa cuando se inicia una transmisión y se desactiva cuando se completa la recepción de los datos, la logica, ya sea activa en bajo o activa en alto es controlado por la entrada (`cs_ctrl`).

5. **Entradas y salidas adicionales**: El módulo tiene entradas adicionales como `All_in1` y `All_in0` que permiten controlar el comportamiento de la línea MOSI, ya sea que todos los datos a transmitir sean 1 o 0.






### 3.3 Módulo "registro_datos"
#### 1. Encabezado del módulo
```
module registro_datos #(parameter N = 5)
(
    input logic clk,         
    input logic rst,
    input logic hold_ctrl,

    input logic [N:0]addr1,
    input logic [7:0] in1, //entrada externa
    input logic wr1,        //habilitaciÃ³n para in1
    
    input logic [N:0] addr2, 
    input logic wr2,        //habilitacion para in2
    input logic [7:0] in2,

    output logic [31:0] out_data  // sale hacia el modulo de control externo
    
);

```



#### 2. Entradas y salidas:
- `clk`:  Señal de reloj del sistema.
- `rst`: Señal de reset para inicializar todos los registros en 0.
- `hold_ctrl`: Señal de control que determina si se utiliza addr1 o addr2 como dirección de los registros.
- `addr1`: Direccion de los registros.
- `in1`: Entrada de 8 bits para escribir datos en los registros.
- `wr1`: Señal de habilitación para escribir in1 en los registros.
- `addr2`: Direccion de los registros.
- `wr2`: Señal de habilitación para escribir in2 en los registros.
- `in2`: Entrada de 8 bits para escribir datos en los registros.
- `out_data`: Salida de 32 bits que contiene el valor almacenado en el registro direccionado.

#### 3. Criterios de diseño
El módulo contiene un banco de registros de 32 bits, donde cada registro tiene una dirección única de N+1 bits. Tiene la capacidad de escritura y lectura de datos a través de direcciones específicas, permite la escritura de datos de 8 bits o 32 bits en los registros, dependiendo de las señales de habilitación wr1 y wr2.



### 3.4 Módulo "registro_control"
#### 1. Encabezado del módulo
```
module registro_control #(
    parameter N = 5 // Debe ser menor o igual que 11
)(
    input clk,       // Reloj
    input rst,       // Reset
    input [14:0] i_data,
    input wr2_c,
    input send_sign, // Permite limpiar el registro 'send'
    input wr1_c,     // Enable para la escritura del dato de entrada
    input logic hold_ctrl,
    output send,     // Puerto de salida "send"
    output cs_ctrl,  // Puerto de control de salida CS
    output all_1s,   // Puerto de control "all_1s"
    output all_0s,   // Puerto de control "all_0s"
    output [N:0] n_tx_end, // Puerto de control "n_tx_end"
    input [N+1:0] n_rx_end, // Puerto de control "n_rx_end"
    output logic [31:0] out_ctrl
);

```


#### 2. Entradas y salidas:
- `clk`:  Señal de reloj del sistema.
- `clk`: Reloj del sistema.
- `rst`: Señal de reset.
- `i_data`: Datos de entrada de 15 bits.
- `wr2_c`: Señal de entrada para limpiar el registro 'send'.
- `send_sign`: Señal de entrada que permite limpiar el registro 'send'.
- `wr1_c`: Señal de entrada que habilita la escritura de los datos de entrada en el registro de control.
- `hold_ctrl`: Señal de entrada que controla la actualización del registro de control con n_rx_end.
- `send`: Señal de salida del registro 'send'.
- `cs_ctrl`: Señal de salida de control de Chip Select.
- `all_1s`: Señal de salida de control "all_1s".
- `all_0s`: Señal de salida de control "all_0s".
- `n_tx_end`: Señal de salida de control "n_tx_end" de N bits.
- `n_rx_end`: Señal de entrada de control "n_rx_end" de N+1 bits.
- `out_ctrl`: Señal de salida que contiene el valor completo del registro de control de 32 bits.

#### 3. Criterios de diseño
El módulo registro_control implementa un registro de control de 32 bits que se utiliza para gestionar varias señales de control y datos de entrada/salida. A continuación, se presenta un resumen de sus funciones:

1. **Registro de control de 32 bits:** El módulo contiene un registro de control de 32 bits (control_register) que se actualiza con diferentes señales de entrada.
2. **Escritura de datos de entrada:** El módulo permite escribir los bits [0:3] y [4:4+N] del registro de control con los datos de entrada i_data cuando la señal wr1_c está activa.
3. **Control de la señal 'send':** El módulo permite controlar la señal 'send' (bit 0 del registro de control) mediante la señal send_sign y wr2_c. Cuando wr2_c está activo, la señal 'send' se invierte.
4. **Señales de control de salida:** El módulo proporciona varias señales de control de salida (cs_ctrl, all_1s, all_0s, n_tx_end) que se asignan a diferentes bits del registro de control.
5. **Actualización del registro con n_rx_end:** El módulo permite actualizar los bits [16:16+N+1] del registro de control con la señal de entrada n_rx_end cuando la señal hold_ctrl está activa.
6. **Salida del registro de control:** El módulo proporciona la salida out_ctrl que contiene el valor completo del registro de control de 32 bits.





### 3.5 Módulo "Contador"
#### 1. Encabezado del módulo
```
module contador #(
    parameter N = 5
)(
    input clk,
    input rst,
    input cont_trans,
    input [N:0] n_tx_end,
    output logic [N+1:0] n_rx_end,
    output logic [N:0] addr2,
    output logic trans_ready
);

```

#### 2. Entradas y salidas:
- `clk`:  Señal de reloj del sistema.
- `rst`: Señal de reset.
- `cont_trans`: Señal de entrada que controla el contador.
- `n_tx_end`: Señal de entrada de N+1 bits que indica el valor máximo del contador.
- `n_rx_end`: Señal de salida de N+2 bits que representa el valor actual del contador.
- `addr2`: Señal de salida de N+1 bits que representa el valor actual del contador.
- `trans_ready`: Señal de salida que indica cuando el contador ha alcanzado el valor máximo.

#### 3. Criterios de diseño
El módulo contador implementa un contador que se incrementa hasta alcanzar un valor máximo especificado por n_tx_end. A continuación, se presenta un resumen de sus funciones:

1. **Contador de N+2 bits**: El módulo contiene un contador de N+2 bits (cuenta_trans) que se incrementa en cada ciclo de reloj cuando la señal cont_trans está activa.
2. **Valor máximo del contador**: El valor máximo del contador está determinado por la señal de entrada n_tx_end de N+1 bits.
3. **Señal de salida n_rx_end**: La señal de salida n_rx_end de N+2 bits representa el valor actual del contador.
4. **Señal de salida addr2**: La señal de salida addr2 de N+1 bits también representa el valor actual del contador.
5. **Señal de salida trans_ready**: La señal de salida trans_ready se activa cuando el contador alcanza el valor máximo especificado por n_tx_end.
6. **Reinicio del contador**: Después de alcanzar el valor máximo, el contador se reinicia a cero en el siguiente ciclo de reloj si la señal cont_trans sigue activa.

EL objetivo del presente contador, es para llevar control de que se hagan las n_tx_end transacciones de datos que se quieran hacer en el SPI.




### 3.6 Módulo "fsm_control_spi"
#### 1. Encabezado del módulo
```
module fsm_control_spi (
    // ENTRADAS
    input logic clk, rst,
    input logic send,
    input logic trans_ready, // Cuando se envian los = n tx end en diagrama
    input logic i_RX_DV,

    // SALIDAS
    output logic inicio,
    output logic cont_trans,
    output logic wr2,
    output logic hold_ctrl,
    output logic wr2_c
);

```



#### 2. Entradas y salidas:
- `clk`:  Señal de reloj del sistema.
- `rst`: Señal de reset.
- `send`: Señal de entrada que indica el inicio de una nueva transmisión.
- `trans_ready`: Señal de entrada que indica cuando se han enviado todos los datos (n_tx_end) en el diagrama.
- `i_RX_DV`: Señal de entrada que indica que se ha recibido un nuevo byte de datos.
- `inicio`: Señal de salida que indica el inicio de una nueva transmisión.
- `cont_trans`: Señal de salida que controla el contador de transmisión.
- `wr2`: Señal de salida que habilita la escritura en el registro de control.
- `hold_ctrl`: Señal de salida que controla la actualización del registro de control con n_rx_end.
- `wr2_c`: Señal de salida que limpia el registro 'send'.

#### 3. Criterios de diseño
El módulo fsm_control_spi implementa una máquina de estados finita (FSM) que controla el flujo dela comunicación SPI. A continuación, se presenta un resumen de sus funciones:

1. **Máquina de estados finita**: El módulo implementa una FSM con tres estados: manda_hold, manda_inicio e inicia_trans.
2. **Lógica de siguiente estado combinacional**: La lógica combinacional determina el siguiente estado de la FSM en función de las entradas (send, trans_ready, i_RX_DV) y el estado actual.
3. **Memoria secuencial**: La memoria secuencial almacena el estado actual de la FSM y se actualiza en cada ciclo de reloj.
4. **Lógica de salida combinacional**: La lógica combinacional determina los valores de las señales de salida (inicio, cont_trans, wr2, hold_ctrl, wr2_c) en función del estado actual y las entradas.
5. **Control de transmisión**: La FSM controla el inicio de una nueva transmisión, la habilitación del contador de transmisión y la actualización del registro de control según el estado y las entradas.
5. **Recepción de datos**: La FSM también maneja la recepción de datos a través de la señal i_RX_DV, actualizando el estado y las señales de salida en consecuencia.

Se muestra el diagrama de estados para la maquina de estados implementada:
![Texto alternativo](/Parte1/fig/diagramadeestados.png)


## 4. Testbench:

En la siguiente imagen se muestra la simulación final en icarus verilog donde se observa un correcto funcionamiento, ya que se recorren todos los registros indicados por n_tx_end, se hacen 2 envios idénticos con datos llenados en el registro de datos al inicio de la simulación.

![image](https://github.com/EL3313/laboratorio3-equipo-4/assets/124948957/6b9c6c40-be5f-4e0e-b56c-bf7e697acec4)
