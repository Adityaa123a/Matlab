Ns = 10;%Number of  stations (Max 1 station per sq Km)
sizex = 500; %X Dimension of city in Km
sizey = 500; %Y Dimension of city in Km
evnum = 500; %Total number of EVs
batt_crit = 20; %Critical Battery percentage
evrange = 207; %Max distance(Km) covered at full charge
towcount = 0; %Number of EVs that stopped dead on the road

%Charging Station Generator
cs_xloc=randi(sizex,Ns,1);
cs_yloc=randi(sizey,Ns,1);
csnum = linspace(1,Ns,Ns);
CS_loc = [csnum', cs_xloc, cs_yloc]; %Coordinates of Charging station (Randomly generated)

%Charging Station log
cs_log = zeros(evnum, 3); %cs_log[charging station number, charge time of EV, {(1-4) = values for lambda , 5=slot book}]

%Probaility slabs
timprob = [0.28,0.09,0.08,0.51]; %Probability at 5 different times of the day
chprob = linspace(0.05,0.9,10); %Probability slab based on SOC
slabsize = (100-batt_crit)/(length(chprob));

% EV generator
ev_dat = zeros(evnum, 5);
for i = 1:evnum,
  fl = 0;
  ev_dat(i,1) = batt_crit+randi(100-batt_crit); %Battery percentage
  ev_dat(i,2) = (100-ev_dat(i,1))*(25+randi(10))/(10*(94+randi(6))); %Charge time (Hrs) {94+randi(6)  represents charging efficiency}
  ev_dat(i,3) = randi(sizex); %Start position x
  ev_dat(i,4) = randi(sizey); %Start position y
  ev_dat(i,5) = randi(sizex); %Destination x
  ev_dat(i,6) = randi(sizey); %Destination y
  %If in definite need of charge
  while (distancePoints([ev_dat(i,3),ev_dat(i,4)],[ev_dat(i,5),ev_dat(i,6)] )< evrange*(ev_dat(i,1)-batt_crit)/100 )
    md = inf;
    %Find closest charging station
    for j =1:Ns,
      csdist = distancePointEdge([CS_loc(j,2),CS_loc(j,3)],[ev_dat(i,3), ev_dat(i,4), ev_dat(i,5), ev_dat(i,6)]);
      if ( csdist< md)
        closest_cs = j;
        md = csdist;
      endif
    endfor
    if(distancePoints([ev_dat(i,3),ev_dat(i,4)], [CS_loc(j,2),CS_loc(j,3)])>csdist)
      towcount = towcount + 1;
      fl = Ns;
      break
    endif
    if(fl != Ns)
      cs_log(i,1)=closest_cs;
      cs_log(i,2)=ev_dat(i,2);
      cs_log(i,3)=randi(4);
      fl = fl+1;
      ev_dat(i,1) = 100;
      ev_dat(i,3) = CS_loc(j,2);
      ev_dat(i,4) = CS_loc(j,3);
    else
      towcount = towcount + 1;
      break
    endif  
  endwhile
  %Charging station slot booking
  for k = 1: length(chprob),
    if (ev_dat(i,1)>=(100-(slabsize*k)))
      if (chprob(k)*timprob(2) > (0.4))
        md = inf;
        %Find closest charging station
        for j =1:Ns,
          csdist = distancePointEdge([CS_loc(j,2),CS_loc(j,3)],[ev_dat(i,3), ev_dat(i,4), ev_dat(i,5), ev_dat(i,6)]);
          if ( csdist< md)
            closest_cs = j;
            md = csdist;
          endif
        endfor
        if(distancePoints([ev_dat(i,3),ev_dat(i,4)], [CS_loc(j,2),CS_loc(j,3)])>csdist) % To check if EV can reach the spot
          break
        endif
        cs_log(i,1)=closest_cs;
        cs_log(i,2)=ev_dat(i,3);
        cs_log(i,3)=5;
      endif      
      break
    endif
  endfor
endfor

cs_log
towcount
xlswrite('Data.xlsx',cs_log);