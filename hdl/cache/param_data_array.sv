module param_data_array #(
    parameter s_offset = 5,
    parameter s_index  = 3,
    parameter num_ways = 2
)
(
    clk,
    read,
    write_en,
    rindex,
    windex,
    datain,
    dataout
);

localparam s_mask   = 2**s_offset;
localparam s_line   = 8*s_mask;
localparam num_sets = 2**s_index;

input clk;
input [num_ways-1:0] read;
input [num_ways-1:0][s_mask-1:0] write_en;
input [s_index-1:0] rindex;
input [s_index-1:0] windex;
input [num_ways-1:0][s_line-1:0] datain;
output logic [num_ways-1:0][s_line-1:0] dataout;

logic [s_line-1:0] data [num_ways-1:0][num_sets-1:0] /* synthesis ramstyle = "logic" */;
logic [num_ways-1:0][s_line-1:0] _dataout;
assign dataout = _dataout;

always_comb begin
    for (int w = 0; w < num_ways; w++) begin
        if (read[w])
            for (int i = 0; i < s_mask; i++)
                _dataout[w][8*i +: 8] <= (write_en[w][i] & (rindex == windex)) ?
                                    datain[w][8*i +: 8] : data[w][rindex][8*i +: 8];

        for (int i = 0; i < s_mask; i++)
        begin
            data[w][windex][8*i +: 8] <= write_en[w][i] ? datain[w][8*i +: 8] :
                                                    data[w][windex][8*i +: 8];
        end
    end
end

endmodule : param_data_array
