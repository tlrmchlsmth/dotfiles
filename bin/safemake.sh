#!/bin/bash                                                       
#                                                            
# Wrapper around make that fixes naked -j arguments or limits -j arguments to                      
# a maximum value.                                                    
#                                                            
if [ -z "${J_LIMIT}" ]; then                                               
  J_LIMIT=56                                                      
fi                                                            
#echo "Safe make, -j limit = ${J_LIMIT}"                                         
OPTIND=1                                                         
for OPT in $@; do                                                    
  if [ "${OPT}" = "-j" ]; then                                             
    OPTARG=${@:$((OPTIND+1)):1}                                           
    if [[ "$OPTARG" =~ ^[0-9]+$ ]]; then                                       
      if [[ $((OPTARG)) -gt $((J_LIMIT)) ]]; then                                 
        echo "Safe make: -j too high ${OPTARG}, setting to ${J_LIMIT}"                      
        set -- "${@:1:$((OPTIND))}" ${J_LIMIT} "${@:$((OPTIND+2))}"                       
      fi                                                      
    else                                                       
      echo "Safe make: no limit found for -j, setting to ${J_LIMIT}"                        
      set -- "${@:1:$((OPTIND))}" ${J_LIMIT} "${@:$((OPTIND+1))}"                         
    fi                                                        
  fi                                                          
  ((OPTIND++))                                                     
done                                                           
REAL_MAKE="$(command -v make 2>/dev/null || echo /usr/bin/make)"
exec "$REAL_MAKE" "$@"
