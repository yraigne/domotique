-- script_device_thermostatv3.lua ------------------------------------
----------------------------------------------------------------------
-- G PETREMENT 2015 --------------------------------------------------
-- This script is a heating regulation use to maintain temperatur ----
-- at a specific value. ----------------------------------------------
----------------------------------------------------------------------

--------------------------------
--- Variables utilisateur ------
--------------------------------
local VarConsigne =  "ConsigneThermostat" --Température de consigne
local sonde = 'Sonde salon'               --Nom de la sonde de température
local IDerreur = '62'                     --IDX de l'afficheur d'erreur
local IDSomerreur = '77'                  --IDX de l'afficheur Somme d'erreur
local IDDeltaErreur = '90'                --IDX de l'afficheur Différence d'erreur
local IDCmdChauff = '78'                  --IDX de l'afficheur Proportionnel Commande Chauffage
local domoticz_url = '192.168.0.4:8080'   --Adresse IP:port de Domoticz
local VarKp = "Kp"                        --Variable Domoticz : Gain proportinnel
local VarKi = "Ki"                        --Variable Domoticz : Gain intégral
local VarKd = "Kd"                        --Variable Domoticz : Gain dérivé
local VarTempErr = 'TemperatureErreur'    --Variable domoticz pour l'erreur de temperature
local VarSomErr = 'SommeErreur'           --Variable domoticz pour la somme des erreurs
local VarDeltaErr = 'DeltaErreur'         --Variable domoticz pour la différences des erreurs
local VarCmdChauff = 'CmdChauff'          --Variable Domoticz de commande du chauffage : permet de passer la commande à script_time_chauff.lua
local VarCmdImax = 'CmdImax'              --Variable domoticz qui défini le gain intégral maximum
local fichier = '/var/tmp/dom_tmperr.txt' --Chemin d'acces du fichier sur un RAMdisque pour réduire l'usure de la carte SD
local nbr_stk = 22                        --Quantité de valeurs utilisées pour le calcul de la dérivée de l'erreur (ne pas mettre 0!!)

--------------------------------------------------------------
-- Fonction pour arrondir un nombre à la décimale souhaitée --
--------------------------------------------------------------
math.round = function(number, precision)
   precision = precision or 0
   local decimal = string.find(tostring(number), ".", nil, true);
   
   if ( decimal ) then   
      local power = 10 ^ precision;  
      if ( number >= 0 ) then 
         number = math.floor(number * power + 0.5) / power;
      else 
         number = math.ceil(number * power - 0.5) / power;      
      end
      
      -- convert number to string for formatting
      number = tostring(number);         
      -- set cutoff
      local cutoff = number:sub(decimal + 1 + precision);
      -- delete everything after the cutoff
      number = number:gsub(cutoff, "");
   else
      -- number is an integer
      if ( precision > 0 ) then
         number = tostring(number);
         number = number .. ".";
         for i = 1,precision
         do
            number = number .. "0";
         end
      end
   end      
   return number;
end

---------------------------------------------------------
---  Fonction pour calculer la commande de chauffage  ---
---------------------------------------------------------
Chauff = function(Kp, Err, Ki, SomErr, Kd, DifErr)
   local cmd = Kp*Err + Ki*SomErr + Kd*DifErr
   -- La commande de chauffage est un nombre entier compris entre 0 et 100
   if cmd < 0 then 
      cmd = 0
   elseif cmd > 100 then
      cmd = 100
   else
      cmd = math.round(cmd, 0)
   end
   return cmd
end

-----------------------------
---- Programme principal ----
-----------------------------
commandArray = {}
--La sonde Oregon 'Salon' emet toutes les 40 secondes. Ce sera approximativement la fréquence d'exécution de ce script.

if (devicechanged[sonde]) then
  
  -- Initialisation des variables
  local t = {} --Table buffer avec le fichier texte
  local SomErreur = tonumber(uservariables[VarSomErr]) --Somme des erreurs
  local Kp = tonumber(uservariables[VarKp])
  local Ki = tonumber(uservariables[VarKi])
  local Kd = tonumber(uservariables[VarKd])
  local CmdImax = tonumber(uservariables[VarCmdImax])  --Limitation de l'action intégrale (debug)
  local consigne = otherdevices_svalues[VarConsigne]   --Température de consigne
    
  ---------------------------------
  ---  Calcul du proportionnel  ---
  ---------------------------------
  --Temperature relevée dans le salon
  local temperature = devicechanged[sonde..'_Temperature'] 
  temperature = tonumber(math.round(temperature,2))

  -- Update de la sonde d'erreur
  local TmpErreur = consigne - temperature
  local url = domoticz_url..'/json.htm?type=command&param=udevice&idx='..IDerreur..'&nvalue=0&svalue='..TmpErreur
  commandArray[1]={['OpenURL']=url }
  
  ------------------------------
  ---  Calcul de la dérivée  ---
  ------------------------------
  --Creation si le ficher n'existe pas
  local f = io.open(fichier, "a+")
  f:close()
  --Lecture du fichier et remplissage de la table t
  f = io.open(fichier, "r")
  for line in f:lines() do
    if line ~= nil then
      table.insert(t,line)
    end
  end
  f:close()
  --Ajout de la nouvelle ligne a la table
  table.insert(t,tostring(os.time()..";"..math.round(TmpErreur,2)))  
  --Suppression de l'élement le plus vieux
  while #t > nbr_stk do
    table.remove(t,1)
  end
  --Ecriture dans fichier'
  f = io.open(fichier,"w")
  for key,value in pairs(t) do
    f:write(value.."\n")
  end
  f:close()
  -- Calcul Difference entre deux erreurs à 15min d'interval + calibration
  local MoyErr1 = 0
  local MoyErr2 = 0
  for i=1,#t/2 do
    MoyErr1 = MoyErr1 + tostring(string.sub(t[i],string.find(t[i], ";")+1))
    MoyErr2 = MoyErr2 + tostring(string.sub(t[#t+1-i],string.find(t[#t+1-i], ";")+1))
  end
  --Le delta erreur est calculé sur la moyenne de 22 erreurs ce qui permet de 'lisser' la variation
  local DeltaErreur = tonumber(math.round(((MoyErr2 / (#t/2)) - (MoyErr1 / (#t/2)))*8, 2)) --Delta en d°/heure
  print('--DeltaErreur = ('..MoyErr2..'/'..(#t/2)..') - ('..MoyErr1..'/'..(#t/2)..') * 8= '..DeltaErreur)
  -- Update de la sonde DeltaErreur
  url = domoticz_url..'/json.htm?type=command&param=udevice&idx='..IDDeltaErreur..'&nvalue=0&svalue='..DeltaErreur
  commandArray[2]={['OpenURL']=url }
  
  -------------------------------
  ---  Calcul de l'intégrale  ---
  -------------------------------
  -- Calcul de la somme des erreurs + Update de la sonde Somme d'erreur
  -- Si la l'erreur est supérieure à +-1° on ne somme pas pour limiter l'impact des changements de consigne
  if ((TmpErreur > -1) and (TmpErreur < 1) and (Ki ~= 0)) then
    SomErreur = tonumber(math.round(TmpErreur + SomErreur,2))
    if (SomErreur > (CmdImax/Ki)) then
        SomErreur = CmdImax/Ki
    elseif (SomErreur < 0) then
      SomErreur = 0
    end
  end
  url = domoticz_url..'/json.htm?type=command&param=udevice&idx='..IDSomerreur..'&nvalue=0&svalue='..SomErreur
  commandArray[3]={['OpenURL']=url }

  ------------------------------------------
  --- Calcul de la commande de chauffage ---
  ------------------------------------------
  print('Consigne = '..consigne..' Temperature = '..temperature)
  local CmdChauff = Chauff(Kp, TmpErreur, Ki, SomErreur, Kd, DeltaErreur)
  -- Update de la mesure Commande
  url = domoticz_url..'/json.htm?type=command&param=udevice&idx='..IDCmdChauff..'&nvalue=0&svalue='..CmdChauff
  commandArray[4]={['OpenURL']=url }
  print('--Commande de chauffage : '..CmdChauff..' / Kp ='..tostring(Kp*TmpErreur)..' / Ki ='..tostring(Ki*SomErreur)..' / Kd ='..tostring(Kd*DeltaErreur))
  --Passage des variables à domoticz
  commandArray['Variable:'..VarTempErr]= tostring(TmpErreur)
  commandArray['Variable:'..VarSomErr]= tostring(SomErreur)
  commandArray['Variable:'..VarDeltaErr]= tostring(DeltaErreur)
  commandArray['Variable:'..VarCmdChauff]= tostring(CmdChauff)
  
end
return commandArray