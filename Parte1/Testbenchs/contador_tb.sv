`timescale 1ns/1ns

module contador_tb;

    // Par�metros
    localparam N = 5;

    // Definici�n de se�ales
    reg clk;
    reg rst;
    reg cont_trans;
    reg [N:0] n_tx_end;
    
    wire [N+1:0] n_rx_end;
    wire trans_ready;
    wire [N:0] addr2;

    // Instancia del contador
    contador #(N) dut (
        .clk(clk),
        .rst(rst),
        .cont_trans(cont_trans),
        .n_tx_end(n_tx_end),
        .n_rx_end(n_rx_end),
        .trans_ready(trans_ready),
        .addr2(addr2)
    );

    // Generaci�n de clock
    always #5 clk = ~clk;

    // Inicializaci�n de se�ales
    initial begin
        clk = 0;
        rst =1;
        cont_trans = 0;
        n_tx_end = 6'd5; // Por ejemplo, un valor de 10 para n_tx_end
        repeat (2) begin
        @(posedge clk);
        end 
        rst = 0;
        cont_trans = 1; // Iniciar la se�al de conteo despu�s de 50 unidades de tiempo
        repeat (6) begin
        @(posedge clk);
        end
        //cont_trans = 0; // Detener la se�al de conteo despu�s de 100 unidades de tiempo
        repeat (6) begin
        @(posedge clk);
        end
        cont_trans = 1;
        repeat (6) begin
        @(posedge clk);
        end
        $finish; // Finalizar la simulaci�n despu�s de 10 unidades de tiempo adicionales
    end

//    // Monitoreo de las se�ales de salida
//    always @(n_rx_end, trans_ready, addr2) begin
//        $display("n_rx_end = %b, trans_ready = %b, addr2 = %b", n_rx_end, trans_ready, addr2);
//    end

endmodule
