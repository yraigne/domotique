-- script_device_conschauf.lua ---------------------------------------
-- G PETREMENT -----------------------------------------------2015----
----------------------------------------------------------------------
-- Pilotage d'un Thermostat setpoint Consigne pour pilotage regul ----
-- en fonction d'une programation journaliere ------------------------
----------------------------------------------------------------------
-- Le programme est basé sur l'action de 2 switchs (virtuels ou non) -
-- Le Switch EcoConfort dispose d'une programation mais peut aussi ---
-- être actionné manuellement. ---------------------------------------
-- Le switch HorsGel est un mode vacance qui stope la programmation --
-- Les temperatures de consignes sont stockées en variable direct ----
-- dans domoticz pour être modifiées par l'interface web. ------------
----------------------------------------------------------------------

----------------------------------------------------------------------
-- VARIABLES UTILISATEUR : mettre les nom des dispositifs ici --------
----------------------------------------------------------------------
local VarConsJour = 'ConsigneJour'       --Variable consigne jour
local VarConsNuit = 'ConsigneNuit'       --Variable consigne nuit
local VarConsVac = 'ConsigneVacance'     --Variable consigne vacances
local VarSomErr = 'SommeErreur'          --Variable Somme des erreurs
local SondeCons = 'ConsigneChauffage'    --Sonde de temperature
local InterEcoConfort = 'EcoConfort'     --Interrupteur programmé Off:eco On:confort
local InterHorsGel = 'HorsGel'           --Interrupteur On:mode hors gel>> plus de programmation, consigne vacance ou manuelle
local domoticz_url = '192.168.0.4:8080'  --Adresse IP:port de Domoticz
local IDXcons = '96'                     --IDx de l'afficheur de consigne
----------------------------------------------------------------------

-- Fonction retourant la differrence de temps en secondes ------------
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
--  Recuperation des variables ---------------------------------------
local ConsJour = uservariables[VarConsJour]
local ConsNuit = uservariables[VarConsNuit]
local ConsVac = uservariables[VarConsVac]
local Consigne = otherdevices_temperature[SondeCons]
local t1 = os.date("%H:%M")

-- Lorsqu'un interrupteur est manipulé on modifie la temperature de consigne.
-- La variable SommeErreur utilisée pour calculer le gain intégral est aussi remise à 0 >> Gain intégral=0
if (((devicechanged[InterEcoConfort] == 'On') and (otherdevices[InterHorsGel] == 'Off')) or ((devicechanged[InterHorsGel] == 'Off') and (otherdevices[InterEcoConfort] == 'On'))) then
   print("-------------- Temperature modifiée vers Confort à "..t1)
   -- Mise a jour de l'afficheur via JSON -----------------------------
   local url = domoticz_url..'/json.htm?type=command&param=udevice&idx='..IDXcons..'&nvalue=0&svalue='..ConsJour
   commandArray[1]={['OpenURL']=url }
   commandArray['Variable:'..VarSomErr]='0'

elseif (((devicechanged[InterEcoConfort] == 'Off') and (otherdevices[InterHorsGel] == 'Off')) or ((devicechanged[InterHorsGel] == 'Off') and (otherdevices[InterEcoConfort]=='Off' ))) then
   print("-------------- Temperature modifiée vers Eco à "..t1)
   -- Mise a jour de l'afficheur via JSON -----------------------------
   local url = domoticz_url..'/json.htm?type=command&param=udevice&idx='..IDXcons..'&nvalue=0&svalue='..ConsNuit
   commandArray[1]={['OpenURL']=url }
   commandArray['Variable:'..VarSomErr]='0'
  
elseif (devicechanged[InterHorsGel] == 'On') then
   print("-------------- Temperature modifiée vers HorsGel à "..t1)
   -- Mise a jour de l'afficheur via JSON -----------------------------
   local url = domoticz_url..'/json.htm?type=command&param=udevice&idx='..IDXcons..'&nvalue=0&svalue='..ConsVac
   commandArray[1]={['OpenURL']=url }
   commandArray['Variable:'..VarSomErr]='0'
end
return commandArray