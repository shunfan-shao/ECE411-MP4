module param_array #(
    parameter s_index = 3,
    parameter width = 1,
    parameter num_ways = 2
)
(
    clk,
    rst,
    read,
    load,
    rindex,
    windex,
    datain,
    dataout
);

localparam num_sets = 2**s_index;

input clk;
input rst;
input [num_ways-1:0] read;
input [num_ways-1:0] load;
input [s_index-1:0] rindex;
input [s_index-1:0] windex;
input [width-1:0] datain;
output logic [num_ways-1:0][width-1:0] dataout;

logic [width-1:0] data [num_ways-1:0][num_sets-1:0] /* synthesis ramstyle = "logic" */;
logic [num_ways-1:0][width-1:0] _dataout;
assign dataout = _dataout;

always_comb begin
    for (int w = 0; w < num_ways; w++) begin
        if (read[w])
            _dataout[w] <= (load[w]  & (rindex == windex)) ? datain : data[w][rindex];

        // if (load[w])
        //     data[w][windex] <= datain;
    end
end

always_ff @(posedge clk) begin
    if (rst) begin
        for (int w = 0; w < num_ways; w++) begin
            for (int i = 0; i < num_sets; ++i)
                data[w][i] <= '0;
        end
    end
    else begin
        for (int w = 0; w < num_ways; w++) begin
            if (load[w])
                data[w][windex] <= datain;
        end
    end
end

endmodule : param_array
