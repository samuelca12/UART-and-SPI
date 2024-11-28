`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
module fsm_regcontrol_TB;

    // Par�metros de prueba
    parameter CLK_PERIOD = 10; // Periodo del reloj en unidades de tiempo
    parameter SIM_TIME   = 100; // Tiempo total de simulaci�n en unidades de tiempo
    
    // Se�ales de entrada
    logic clk = 0;
    logic rst = 0;
    logic wr_i = 0;
    logic reg_sel_i = 0;
    logic [31:0] entrada_i = 0;
    
    
    logic trans_ready = 0;
    // Se�al de salida
    logic [31:0] salida_o;
    
    // Instancia de la interfaz perif�rica SPI
    top_fsm_regcontrol #(
        .N(5)
    ) uut (
        .clk(clk),
        .rst(rst),
        .wr_i(wr_i),
        .reg_sel_i(reg_sel_i),
        .entrada_i(entrada_i),
        .t_trans_ready(trans_ready),
        .salida_o(salida_o)
    );
    
    // Generaci�n del reloj
    always #(CLK_PERIOD/2) clk = ~clk;
    
    // Est�mulos
    initial begin
        $dumpfile("fsm_regcontrol_TB.vcd");
        $dumpvars(0, fsm_regcontrol_TB);
        
        // Simulaci�n
        // Aplicar reset
        rst = 1;
        #20;
        rst = 0;
        #20
        // Enviar datos al registro de control
        reg_sel_i = 1;
        entrada_i = 32'b00000000000000000000000000000001;
        wr_i = 1;
        #20;
        wr_i = 0;
        #80
        trans_ready=1;
        #20
        trans_ready=0;
        #3000;
        
        // Cambiar la selecci�n de registro y enviar datos al registro de datos
        reg_sel_i = 0;
        entrada_i = 32'b00000000000000000000000000000001;
        wr_i = 1;
        #20;
        wr_i = 0;
        #30;
        
        // Finalizar simulaci�n
        #20;
        $finish;
    end
    
endmodule
