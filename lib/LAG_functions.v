
/* -------------------------------------------------------------------------------
 * (C)2007 Robert Mullins
 * Computer Architecture Group, Computer Laboratory
 * University of Cambridge, UK.
 * 
 * (C)2012 Korotkyi Ievgen
 * National Technical University of Ukraine "Kiev Polytechnic Institute"  
 * -------------------------------------------------------------------------------
 *
 * Misc. functions package
 * 
 *   - clogb2(x) - ceiling(log2(x))
 *   - oh2bin(x) - one-hot to binary encoder
 *   - max (x,y) - returns larger of x and y
 *   - min (x,y) - returns smaller of x and y
 *   - abs (x)   - absolute function
 */

 

function automatic integer abs (input integer x);
   begin
      if (x>=0) return (x); else return (-x);
   end
endfunction


function automatic integer min (input integer x, input integer y);
   begin
      min = (x<y) ? x : y;
   end
endfunction

function automatic integer max (input integer x, input integer y);
   begin
      max = (x>y) ? x : y;
   end
endfunction 

// A constant function to return ceil(logb2(x))
// Is this already present in the Systemverilog standard?
function automatic integer clogb2 (input integer depth);
   integer i,x;
   begin
      x=1;
      for (i = 0; 2**i < depth; i = i + 1)
	x = i + 1;

      clogb2=x;
   end
endfunction

// one hot to binary encoder (careful not to produce priority encoder!)
function automatic integer oh2bin (input integer oh);
   
   integer unsigned i,j;
   begin
      oh2bin='0;
      for (i=0; i<5; i++) begin
	 for (j=0; j<32; j++) begin
	    if ((1'b1 << i)&j) begin
	       oh2bin[i] = oh2bin[i] | oh[j] ;
	    end
	 end
      end
   end
endfunction // oh2bin

//------------------------------------------------------------------------
function integer find_max_local_link_num(input integer links[router_radix][2]);   
integer result, i, j;
begin

result = 0;

for(i = 0; i < router_radix; i++) begin
  for(j = 0; j < 2; j++) begin
    result = max(links[i][j], result);
  end    
end

find_max_local_link_num = result;

end

endfunction

//------------------------------------------------------------------------
function integer find_max_global_link_num(input integer links[network_x][network_y][router_radix][2]);   
integer result, i, j, k, l;
begin

result = 0;  

for(i = 0; i < network_x; i++) 
  for(j = 0; j < network_y; j++)
    for(k = 0; k < router_radix; k++) 
      for(l = 0; l < 2; l++) 
        result = max(links[i][j][k][l], result);

find_max_global_link_num = result;

end

endfunction


