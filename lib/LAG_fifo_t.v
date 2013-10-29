
/* -------------------------------------------------------------------------------
 * (C)2007 Robert Mullins
 * Computer Architecture Group, Computer Laboratory
 * University of Cambridge, UK.
 * -------------------------------------------------------------------------------
 *
 * FIFO Package
 * 
 *   fifo_v_flags_t 
 * 
 */

typedef struct packed
{
 logic full, empty, nearly_full, nearly_empty;
} fifov_flags_t;

  
