/* -------------------------------------------------------------------------------
 * (C)2007 Robert Mullins
 * Computer Architecture Group, Computer Laboratory
 * University of Cambridge, UK.
 * -------------------------------------------------------------------------------
 *
 * Simple/useful components
 * 
 */


module LAG_data_reg (data_in, data_out, clk, rst_n);

   input     flit_t data_in;
   output    flit_t data_out;
   input     clk, rst_n;

   always@(posedge clk) begin
      if (!rst_n) begin
	 data_out <= '0;
      end else begin
	 data_out <= data_in;
      end
   end
   
endmodule 

module LAG_ctrl_reg (ctrl_in, ctrl_out, clk, rst_n);

   input     chan_cntrl_t ctrl_in;
   output    chan_cntrl_t ctrl_out;
   input     clk, rst_n;

   always@(posedge clk) begin
      if (!rst_n) begin
	 ctrl_out <= '0;
      end else begin
	 ctrl_out <= ctrl_in;
      end
   end
   
endmodule 

module LAG_pipelined_channel (data_in, ctrl_in, data_out, ctrl_out, clk, rst_n);
    
   parameter stages = 0;
   parameter nPC = 1; // Number of physical channels per trunk

   input     flit_t data_in[nPC-1:0];
   input     [nPC-1:0] ctrl_in;
   output    flit_t data_out[nPC-1:0];
   output    [nPC-1:0] ctrl_out;
   input     clk, rst_n;

   genvar    st, pc;

   flit_t ch_reg[stages-1:0][nPC-1:0];
   chan_cntrl_t ctrl_reg[stages-1:0];
   
   generate
      if (stages==0) begin
	 // no registers in channel
	 assign data_out = data_in;
	 assign ctrl_out = ctrl_in;
      end else begin
	 for (st=0; st<stages; st++) begin:eachstage
	    if (st==0) begin
	       
	       for (pc = 0; pc < nPC; pc++) begin:eachPC1
            LAG_data_reg data_rg (.data_in(data_in[pc]), .data_out(ch_reg[0][pc]), .clk, .rst_n);
         end  
      
         //LAG_ctrl_reg ctrl_rg (.ctrl_in(ctrl_in), .ctrl_out(ctrl_reg[0]), .clk, .rst_n);
	    
      end else begin
	       for (pc = 0; pc < nPC; pc++) begin:eachPC2
	         LAG_data_reg data_rg (.data_in(ch_reg[st-1][pc]), .data_out(ch_reg[st][pc]), .clk, .rst_n);
	       end
	       
	       //LAG_ctrl_reg ctrl_rg (.ctrl_in(ctrl_reg[st-1]), .ctrl_out(ctrl_reg[st]), .clk, .rst_n);
	       
      end
	 end


   assign data_out = ch_reg[stages-1];
   //assign ctrl_out = ctrl_reg[stages-1];
	 assign ctrl_out = ctrl_in;
	 
      end
endgenerate   

endmodule

//
// Multiplexer with one-hot encoded select input
//
// - output is '0 if no select input is asserted
//
module LAG_mux_oh_select (data_in, select, data_out);

   parameter np = 4;
   parameter max_links_num = 2;
   parameter integer links[np][2] = '{'{2,2}, '{2,2}, '{2,2}, '{2,2}, '{2,2} };

   input flit_t data_in [np*max_links_num-1:0];
   input [np*max_links_num-1:0] select;
   output flit_t data_out;

   integer i,j;
   
   always_comb
     begin
	data_out='0;
	for (i=0; i<np; i++)
	 for (j=0; j < links[i][IN];j++)
	   if (select[i*max_links_num+j]) data_out = data_in[i*max_links_num+j];
	
     end

endmodule // LAG_mux_oh_select

//
// Crossbar built from multiplexers, one-hot encoded select input
//
module LAG_crossbar_oh_select (data_in, select, data_out);

   parameter np = 5;
   parameter max_links_num = 2;
   parameter integer links[np][2] = '{'{2,2}, '{2,2}, '{2,2}, '{2,2}, '{2,2} };

   input flit_t data_in [np*max_links_num-1:0];
   input [np*max_links_num-1:0][np*max_links_num-1:0] select;   // n one-hot encoded select signals per output
   output flit_t data_out [np*max_links_num-1:0];

   genvar i,j;
   
   generate
      for (i=0; i<np; i++) begin:out_ports_1
        for (j=0; j < links[i][OUT];j++) begin:out_links_1
          LAG_mux_oh_select #(.np(np), 
                              .max_links_num(max_links_num), 
                              .links(links) ) xbarmux (data_in, select[i*max_links_num+j], data_out[i*max_links_num+j]);
        end
      end
   endgenerate
   
endmodule // LAG_crossbar_oh_select

