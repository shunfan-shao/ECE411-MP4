package cache_types;

typedef enum bit [1:0] {
    noload    = 2'b00
    , loadall = 2'b01
    , loaden  = 2'b10 
} load_data_sel_t;


typedef enum bit  {
    raddr    = 1'b0
    , waddr  = 1'b1
} pmem_addr_sel_t;

endpackage : cache_types