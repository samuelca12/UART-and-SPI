`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
module fsm_tb;

    // Par�metros de prueba
    parameter CLK_PERIOD = 10; // Periodo del reloj en unidades de tiempo
    parameter SIM_TIME   = 100; // Tiempo total de simulaci�n en unidades de tiempo
    
    // Se�ales de la m�quina de estados
    logic clk = 0;
    logic rst = 0;
    logic send = 0;
    logic trans_ready = 0;
    logic i_RX_DV = 0;
    
    // Se�ales de salida
    logic inicio, cont_trans, wr2, hold_ctrl, send_sign, wr2_c;
    
    // Instancia de la FSM
    fsm_control_spi uut (
        .clk(clk),
        .rst(rst),
        .send(send),
        .trans_ready(trans_ready),
        .i_RX_DV(i_RX_DV),
        .inicio(inicio),
        .cont_trans(cont_trans),
        .wr2(wr2),
        .hold_ctrl(hold_ctrl),
        .send_sign(send_sign),
        .wr2_c(wr2_c)
    );
    
    // Generaci�n del reloj
    always #(CLK_PERIOD/2) clk = ~clk;
    
    initial begin
    $dumpfile("fsm_tb.vcd");
    $dumpvars(0, fsm_tb);
    end
    
    // Monitoreo de las se�ales
    initial begin
        
        
        // Simulaci�n de la FSM
        // Cambio de estado y se�ales de entrada para varias pruebas
        send = 1;
        repeat (8)begin
        @(posedge clk);
        end
        i_RX_DV = 1;
        repeat (1)begin
        @(posedge clk);
        end
        i_RX_DV = 0;
        trans_ready = 1;
        repeat (8)begin
        @(posedge clk);
        end
        trans_ready = 0;
        
        // Finalizar simulaci�n
        @(posedge clk);
        $finish;
    end
    
    // Monitor de las se�ales
    always @(clk) begin
        $monitor("Time: %t, Estado: %s, inicio: %b, cont_trans: %b, wr2: %b, hold_ctrl: %b, send_sign: %b, wr2_c: %b", $time, uut.estado.name, inicio, cont_trans, wr2, hold_ctrl, send_sign, wr2_c);
    end

endmodule

