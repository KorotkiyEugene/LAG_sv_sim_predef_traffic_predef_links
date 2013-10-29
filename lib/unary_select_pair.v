
// USED ONLY TO SELECT VC BLOCKED STATUS
// OPTIMISE FOR XY ROUTING

/* autovdoc@
 *
 * component@ unary_select_pair
 * what@ A sort of mux!
 * authors@ Robert Mullins
 * date@ 5.3.04
 * revised@ 5.3.04
 * description@
 * 
 * Takes two unary (one-hot) encoded select signals and selects one bit of the input.
 * 
 * Implements the following:
 * 
 * {\tt selectedbit=datain[binary(sela)*WB+binary(selb)]}
 * 
 * pin@ sel_a, WA, in, select signal A (unary encoded)
 * pin@ sel_b, WB, in, select signal B (unary encoded)
 * pin@ data_in, WA*WB, in, input data 
 * pin@ selected_bit, 1, out, selected data bit (see above)
 * 
 * param@ WA, >1, width of select signal A
 * param@ WB, >1, width of select signal B
 * 
 * autovdoc@
 */

module unary_select_pair (sel_a, sel_b, data_in, selected_bit);

   parameter input_port = 0; // from 'input_port' to 'sel_a' output port
   parameter WA = 5; //trunk number
   parameter WB = 2; //max. number of links per trunk
   parameter integer links[WA][2] = '{'{2,2}, '{2,2}, '{2,2}, '{2,2}, '{2,2} };

   input [WA-1:0] sel_a;
   input [WB-1:0] sel_b;
   input [WA*WB-1:0] data_in;
   output selected_bit;

   integer i,j;

   logic [WA*WB-1:0]  selected;
   
    always_comb begin
   
    selected = '0;
    
    for (i=0; i<WA; i=i+1)
      for (j=0; j<links[i][OUT]; j=j+1)
        selected[i*WB+j] = (LAG_route_valid_turn(input_port, i)) ?
				      data_in[i*WB+j] & sel_a[i] & sel_b[j] : 1'b0;
	      
    end //always_comb

   assign selected_bit=|selected;
   
endmodule // unary_select_pair
