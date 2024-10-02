String memCal(int mem){
  if(mem<=0){
    return "No members";
  }
  if(mem==1){
    return "1 member";
  }
  else{
    return "$mem members";
  }
  
}