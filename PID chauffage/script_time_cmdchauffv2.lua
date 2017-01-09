-- script_time_cmdchauffv2.lua ---------------------------------------
-- G PETREMENT -------------------------------------------------------
----------------------------------------------------------------------
-- Permet de commander relais de pilotage de chaudiere à gaz ---------
-- Le cycle fait 900s / 15min  ---------------------------------------
-- La commande est un nombre de 0 à 100 ------------------------------
-- Le cycle minimum de la chaudière est de 3min pour réduire l'usure -
----------------------------------------------------------------------

local InterOnOff = 'Chauffage On/Off'     --Interrupteur général de mise en route du chauffage
local VarCmdChauff = 'CmdChauff'          --Variable de commande de chauffage définie par script_device_thermostat
local CycleMini = 180                     --Durée de chauffe minimum en secondes (fonction de la chaudière)
local InterRelais = 'Piface RelayChaud'   --Sortie vers relais chaudière
local domoticz_url = '192.168.0.4:8080'   --Adresse IP:port de Domoticz

-- Fonction retourant la differrence de temps en secondes
function timedifference(s)
   year = string.sub(s, 1, 4)
   month = string.sub(s, 6, 7)
   day = string.sub(s, 9, 10)
   hour = string.sub(s, 12, 13)
   minutes = string.sub(s, 15, 16)
   seconds = string.sub(s, 18, 19)
   t1 = os.time()
   t2 = os.time{year=year, month=month, day=day, hour=hour, min=minutes, sec=seconds}
   difference = os.difftime (t1, t2)
   return difference
end

commandArray = {}
--  Recuperation des variables
local CmdChauff = uservariables[VarCmdChauff]
local OnOff = otherdevices[InterOnOff]

--  Recuperation des minutes
time=os.time()
minutes=tonumber(os.date('%M',time))
hours=tonumber(os.date('%H',time))

-- Execution de cette partie du script toutes les 15 minutes
-- Contacte la chaudière et modifie la variable domoticz Cycle
if( (minutes==15) or (minutes==0) or (minutes==30) or (minutes==45) ) then
   print('-- Lancement du script à '..hours..'h'..minutes)
   print('-- OnOff ='..OnOff..' / CmdChauff ='..CmdChauff)
   
   if  OnOff == 'On' then  --Si l'inter général est ON
      local Cycle = CmdChauff * 9  --Calcul du temps de cycle en seconde
        
      if Cycle < CycleMini then --Si le cycle est trop court on coupe
         commandArray[InterRelais]='Off'
         commandArray['Variable:'..VarCycle]= tostring('0')
      print('Cycle :'..Cycle..'s >> Chaudière Off')
      
    elseif Cycle > 870 then --Si le cycle est trop long (> 14min30) on allume sans coupure
      commandArray[InterRelais]='On'
         commandArray['Variable:'..VarCycle]= tostring(Cycle)
      print('Cycle :'..Cycle..'s >> Chaudière On')
    
    else --Enfin on lance pour X seconde
         print('Cycle lancé pour : '..Cycle..'secondes')
         commandArray[1]={[InterRelais]='On'}
      commandArray[2]={[InterRelais]='Off AFTER '..tostring(Cycle)}
      end
   else
      commandArray[InterRelais]='Off'
      commandArray['Variable:'..VarCycle]= tostring('0')
      print('Chaudière Off')    
   end
end

return commandArray