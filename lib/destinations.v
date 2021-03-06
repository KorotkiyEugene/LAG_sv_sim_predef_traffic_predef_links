// This is dynamic array
//
// 1-st dim. - network x
// 2-st dim. - network y
// 3-d dim. - destinations for node pointed by previous two indexes in mesh network
// 4-th dim. - coordinates of particular dest. and applied load to this dest.  

	localparam real destinations[][][][] = '{
                                            '{ // x = 0
                                                
                                                '{ // y = 0
                                                  
                                                  '{3, 0, 0.1} , '{3, 2, 0.1} , '{2, 1, 0.2} , '{3, 2, 0.3}   
                                                    
                                                },
                                                '{ // y = 1
                                                
                                                  '{2, 0, 0.2} , '{1, 0, 0.4}
                                                  
                                                },
                                                '{ // y = 2
                                                
                                                  '{0, 0, 0}
                                                  
                                                },
                                                '{ // y = 3
                                                
                                                  '{0, 0, 0}
                                                
                                                }
                                            },
//-----------------------------------------------------------------------------------------------------------------
                                            '{ // x = 1
                                                '{ // y = 0
                                                
                                                  '{0, 0, 0} 
                                                    
                                                },
                                                '{ // y = 1
                                                
                                                  '{0, 0, 0.2}
                                                  
                                                },
                                                '{ // y = 2
                                                
                                                  '{0, 0, 0}
                                                  
                                                },
                                                '{ // y = 3
                                                  
                                                  '{0, 0, 0}
                                                  
                                                }
                                            },
//-----------------------------------------------------------------------------------------------------------------
                                            '{ // x = 2
                                                '{ // y = 0
                                                  
                                                  '{0, 0, 0}
                                                  
                                                },
                                                '{ // y = 1
                                                  
                                                  '{1, 0, 0.2}, '{0, 1, 0.2}, '{0, 0, 0.5}
                                                  
                                                },
                                                '{ // y = 2
                                                  
                                                  '{0, 0, 0}
                                                  
                                                },
                                                '{ // y = 3
                                                  
                                                  '{0, 0, 0}
                                                  
                                                }
                                            },
//-----------------------------------------------------------------------------------------------------------------
                                            '{ // x = 3
                                                '{ // y = 0
                                                  
                                                  '{0, 0, 0}
                                                  
                                                },
                                                '{ // y = 1
                                                  
                                                  '{0, 0, 0.6}
                                                  
                                                },
                                                '{ // y = 2
                                                  
                                                  '{0, 0, 0}
                                                  
                                                },
                                                '{ // y = 3
                                                
                                                  '{0, 0, 0}
                                                  
                                                }
                                            }
                                            };   
//-----------------------------------------------------------------------------------------------------------------
