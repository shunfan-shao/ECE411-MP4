import rv32i_types::*;

module multicycle_divider
(
      input clk,
      input rst,

      input logic [31:0] dividend,
      input logic [31:0] divisor,

      output logic [31:0] quotient,
      output logic [31:0] remainder,

      input calc,
      output logic done
);

logic [31:0] dvd, dvs, next_dvd, next_dvs;

enum int unsigned {
    idle,
    sub,
    shift,
    fin
} state, next_state;

logic [31:0] ans, next_ans, q, next_q;
logic [31:0] tmpdvs;


always_ff @(posedge clk) begin
    if (rst) begin
        q <= 0;
    end else begin
        dvs <= next_dvs;
        dvd <= next_dvd;
        ans <= next_ans;
        q <= next_q;
    end
end

always_comb
begin : state_actions
    next_dvd = dvd;
    next_dvs = dvs;
    next_q = q;
    next_ans = ans;
    done = 1'b0;

    quotient = q;
    remainder = next_dvd;

    unique case (state)
        idle: begin
            next_dvd = dividend; 
            next_dvs = divisor; 
            next_ans = 1;
            next_q = 0;
        end
        shift: begin
            next_dvs = dvs << 1;
            next_ans = ans << 1;
        end
        sub: begin
            next_dvd = dvd - dvs;
            remainder = dvd - dvs;
            next_dvs = divisor;
            next_ans = 1;
            next_q = q + ans;
        end
        fin: begin
            done = 1'b1;
            quotient = q;
        end 
        default: ;
    endcase
end


always_comb
begin : next_state_logic
    unique case (state) 
        idle: begin
            if (calc) begin
                if ((divisor << 1) < dividend) begin
                    next_state = shift;
                end else if (dividend >= divisor) begin
                    next_state = sub;
                end else begin
                    next_state = fin;
                end
            end else begin
                next_state = idle;  
            end
        end
        shift: begin
            if ((next_dvs << 1) < dvd) begin
                next_state = shift;
            end else begin
                next_state = sub;
            end
        end
        sub: begin
            if (next_dvd >= next_dvs) begin
                if ((next_dvs << 1) < next_dvd) begin
                    next_state = shift;
                end else begin
                    next_state = sub;
                end
            end else begin
                next_state = fin;
            end
        end
        fin: begin
            next_state = idle;
        end
        default: ;
    endcase
end

always_ff @(posedge clk)
begin: next_state_assignment
    /* Assignment of next state on clock edge */
    if (rst) state <= idle;
    else begin
        // $display("seeting next state to ");
        state <= next_state;
    end
end

endmodule : multicycle_divider

