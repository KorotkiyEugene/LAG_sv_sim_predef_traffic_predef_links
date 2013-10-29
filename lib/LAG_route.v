/* -------------------------------------------------------------------------------
 * (C)2007 Robert Mullins
 * Computer Architecture Group, Computer Laboratory
 * University of Cambridge, UK.
 * -------------------------------------------------------------------------------
 * 
 * XY routing
 * 
 * Routing Function
 * ================
 * 
 * Simple XY routing
 *  - Function updates flit with the output port required at next router 
 *    and modifies displacement fields as head flit gets closer to 
 *    destination.
 * 
 * More complex routing algorithms may be implemented by making edits here 
 * and to the flit's control field defn.
 * 
 * Valid Turn?
 * ===========
 * 
 * LAG_route_valid_turn(from, to) 
 * 
 * This function is associated with the routing algorithm and is used to 
 * optimize the synthesis of the implementation by indicating impossible 
 * turns - hence superfluous logic.
 * 
 * Valid Input PL
 * ==============
 * 
 * Does a particular input PL exist. e.g. Tile input port may only contain
 * one PL buffer.
 * 
 */

function automatic bit LAG_route_valid_input_pl;

   input integer port;
   input integer pl;
   
   `include "parameters.v"

   bit valid;
   begin
      valid=1'b1;

      if (port==`TILE) begin
	 if (pl>=router_num_pls_on_entry) valid=1'b0;
      end

      LAG_route_valid_input_pl=valid;
   end
endfunction // automatic 

function automatic bit LAG_route_valid_turn;
   
   input output_port_t from;
   input output_port_t to;
   
   bit valid;
   begin
      valid=1'b1;

      // flits don't leave on the same port as they entered
      if (from==to) valid=1'b0;

`ifdef OPT_MESHXYTURNS
      // Optimise turns for XY routing in a mesh
      if (((from==`NORTH)||(from==`SOUTH))&&((to==`EAST)||(to==`WEST))) valid=1'b0;
`endif      

      LAG_route_valid_turn=valid;
   end
endfunction // bit


module LAG_route (flit_in, flit_out, clk, rst_n);

   input flit_t flit_in; 
   output flit_t flit_out;

   input  clk, rst_n;

   function flit_t next_route;

	  input flit_t flit_in;
	  
      logic [4:0] route;
      flit_t new_flit;
      x_displ_t x_disp;
      y_displ_t y_disp;

      begin

	 new_flit = flit_in;
	 x_disp = x_displ_t ' (flit_in.data[router_radix + `X_ADDR_BITS : router_radix]);
   y_disp = y_displ_t ' (flit_in.data[router_radix + `X_ADDR_BITS + `Y_ADDR_BITS + 1 : router_radix + `X_ADDR_BITS + 1]);
   
	 // Simple XY Routing

	 if (x_disp!=0) begin
	    if (x_disp>0) begin
	       route = `port5id_east;
	       x_disp--;
	    end else begin
	       route = `port5id_west;
	       x_disp++;
	    end
	 end else begin
	    if (y_disp==0) begin
	       route=`port5id_tile;
	    end else if (y_disp>0) begin
	       route=`port5id_south;
	       y_disp--;
	    end else begin
	       route=`port5id_north;
	       y_disp++;
	    end
	 end

	 new_flit.data[router_radix - 1 : 0] = route;
	 new_flit.data[router_radix + `X_ADDR_BITS : router_radix] = x_displ_t ' (x_disp);
	 new_flit.data[router_radix + `X_ADDR_BITS + `Y_ADDR_BITS + 1 : router_radix + `X_ADDR_BITS + 1] = y_displ_t ' (y_disp);
	 
	 next_route = new_flit;

      end
   endfunction // flit_t
   
   assign  flit_out=next_route(flit_in);
  
endmodule // route

