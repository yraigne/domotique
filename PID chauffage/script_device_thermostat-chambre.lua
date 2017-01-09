-- Alexandre DUBOIS - 2014
-- Ce script permet de maintenir la température de 'Chambre' entre 19°C et 21°C quand l'interrupteur
-- virtuel 'Thermostat Chambre' est activé.

--------------------------------
------ Variables à éditer ------
--------------------------------
local consigne = 20  --Température de consigne par défaut
local hysteresis = 0.5 --Valeur seuil pour éviter que le relai ne cesse de commuter dans les 2 sens
local sonde = 'Chambre' --Nom de la sonde de température
local thermostat = 'Consigne Chambre' --Nom de l'interrupteur virtuel du thermostat
local radiateur = 'Radiateur Chambre' --Nom du radiateur à allumer/éteindre
--------------------------------
-- Fin des variables à éditer --
--------------------------------

commandArray = {}
-- La sonde Oregon emet toutes les 40 secondes. Ce sera approximativement la fréquence d'exécution de ce script.
if (devicechanged[sonde]) then
    local temperature = devicechanged[string.format('%s_Temperature', sonde)] --Temperature relevée dans la chambre
    -- On n'agit que si le "Thermostat" est actif
    if (otherdevices[thermostat]~='Off') then
        print('-- Gestion du thermostat pour la chambre --')

        if (temperature < (consigne - hysteresis) ) then
            print('Allumage du chauffage dans la chambre')
            commandArray[radiateur]='Off'

        elseif (temperature > (consigne + hysteresis)) then
            print('Extinction du chauffage dans la chambre')
            commandArray[radiateur]='On'

        end
    end
end
return commandArray