
// 1-st dim. - network x
// 2-st dim. - network y
// 3-d dim. - trunk number: 0 (north) 1 (east) 2 (south) 3 (west) 4 (local)
// 4-th dim. - data direction: 0 (input trunk), 1 - (output trunk); Array contains number of links per particular trunk  

	localparam integer links[][][][] = '{
                                            '{ // x = 0
                                                
                                                '{ // y = 0
                                                  
                                                  '{2, 2} , '{2, 2} , '{4, 4} , '{2, 2} , '{2, 4} 
                                                    
                                                },
                                                '{ // y = 1
                                                
                                                  '{4, 4} , '{3, 3} , '{2, 2} , '{2, 2} , '{2, 4}
                                                  
                                                },
                                                '{ // y = 2
                                                
                                                  '{2, 2} , '{2, 2} , '{2, 2} , '{2, 2} , '{2, 2}
                                                  
                                                },
                                                '{ // y = 3
                                                
                                                  '{2, 2} , '{2, 2} , '{2, 2} , '{2, 2} , '{2, 2}
                                                
                                                }
                                            },
//-----------------------------------------------------------------------------------------------------------------
                                            '{ // x = 1
                                                '{ // y = 0
                                                
                                                  '{2, 2} , '{2, 2} , '{4, 4} , '{2, 2} , '{2, 4} 
                                                    
                                                },
                                                '{ // y = 1
                                                
                                                  '{4, 4} , '{2, 2} , '{2, 2} , '{3, 3} , '{2, 2}
                                                  
                                                },
                                                '{ // y = 2
                                                
                                                  '{2, 2} , '{2, 2} , '{2, 2} , '{2, 2} , '{2, 2}
                                                  
                                                },
                                                '{ // y = 3
                                                  
                                                  '{2, 2} , '{2, 2} , '{2, 2} , '{2, 2} , '{2, 2}
                                                  
                                                }
                                            },
//-----------------------------------------------------------------------------------------------------------------
                                            '{ // x = 2
                                                '{ // y = 0
                                                  
                                                  '{2, 2} , '{2, 2} , '{2, 2} , '{2, 2} , '{2, 2}
                                                  
                                                },
                                                '{ // y = 1
                                                  
                                                  '{2, 2} , '{2, 2} , '{2, 2} , '{2, 2} , '{2, 2}
                                                  
                                                },
                                                '{ // y = 2
                                                  
                                                  '{2, 2} , '{2, 2} , '{2, 2} , '{2, 2} , '{2, 2}
                                                  
                                                },
                                                '{ // y = 3
                                                  
                                                  '{2, 2} , '{2, 2} , '{2, 2} , '{2, 2} , '{2, 2}
                                                  
                                                }
                                            },
//-----------------------------------------------------------------------------------------------------------------
                                            '{ // x = 3
                                                '{ // y = 0
                                                  
                                                  '{2, 2} , '{2, 2} , '{2, 2} , '{2, 2} , '{2, 2}
                                                  
                                                },
                                                '{ // y = 1
                                                  
                                                  '{2, 2} , '{2, 2} , '{2, 2} , '{2, 2} , '{2, 2}
                                                  
                                                },
                                                '{ // y = 2
                                                  
                                                  '{2, 2} , '{2, 2} , '{2, 2} , '{2, 2} , '{2, 2}
                                                  
                                                },
                                                '{ // y = 3
                                                
                                                  '{2, 2} , '{2, 2} , '{2, 2} , '{2, 2} , '{2, 2}
                                                  
                                                }
                                            }
                                            };   
//-----------------------------------------------------------------------------------------------------------------
