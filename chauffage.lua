--------------------------------------------------------------------------------
-- Gestion du chauffage
-- Auteur : naerleth
-- Ce script comporte 2 logiques :
-- - La première permet de mettre à jour le thermostat selon la valeur d'une 
--   consigne et d'un selector (0, -1, -2, -3)
-- - La seconde gère la régulation de température en mode on/off
--
-- Il est nécessaire de définir quelques variables (zones, IDX, ...)
--
-- V1.2 Gestion de N radiateurs par pièce
-- V1.1 Gestion centralisée du chauffage
-- V1.0 Gère 1 radiateur et 1 sonde par pièce
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--                                                                     VARIABLES
--------------------------------------------------------------------------------
-- Definition de Set
function Set (list)
    local set = {}
    for _, l in ipairs(list) do set[l] = true end
    return set
end

-- Variables dépendantes du système (à renseigner)
--------------------------------------------------------------------------------
-- Accès à la plateforme
local domoticzIp = '192.168.2.38'
local domoticzPort = '8080'

-- L'hysteresis du système
-- TODO : A remplacer par une variable utilisateur
local hysteresis = 0.2

-- Nom de la commande générale de chauffage
local modeChauffage = 'Mode chauffage'

-- Structure contenant toutes les informations sur les différentes i/o par pièce
local pieces = {}

pieces['Chambre'] = {}
pieces['Chambre']['idxConsigne'] = 29
pieces['Chambre']['nomConsigne'] = 'Consigne Chambre'
-- pieces['Chambre']['nomConsigne'] = 'ConsigneChambre'
pieces['Chambre']['nomSondes'] = {}
pieces['Chambre']['nomSondes'][1] = 'Chambre'
pieces['Chambre']['nomRadiateurs'] = {}
pieces['Chambre']['nomRadiateurs'][1] = 'Radiateur Chambre'

pieces['Salon'] = {}
pieces['Salon']['idxConsigne'] = 32
pieces['Salon']['nomConsigne'] = 'Consigne Salon'
-- pieces['Salon']['nomConsigne'] = 'ConsigneSalon'
pieces['Salon']['nomSondes'] = {}
pieces['Salon']['nomSondes'][1] = 'Salon'
pieces['Salon']['nomRadiateurs'] = {}
pieces['Salon']['nomRadiateurs'][1] = 'Radiateur Salon 1'
pieces['Salon']['nomRadiateurs'][2] = 'Radiateur Salon 2'

pieces['Salle de bain'] = {}
pieces['Salle de bain']['idxConsigne'] = 33
pieces['Salle de bain']['nomConsigne'] = 'Consigne Salle de bain'
-- pieces['Salle de bain']['nomConsigne'] = 'ConsigneSalleDeBain'
pieces['Salle de bain']['nomSondes'] = {}
pieces['Salle de bain']['nomSondes'][1] = 'Salle de bain'
pieces['Salle de bain']['nomRadiateurs'] = {}
pieces['Salle de bain']['nomRadiateurs'][1] = 'Radiateur Salle de bain'

pieces['Chambre d\'amis'] = {}
pieces['Chambre d\'amis']['idxConsigne'] = 35
pieces['Chambre d\'amis']['nomConsigne'] = 'Consigne Chambre d\'amis'
-- pieces['Chambre d\'amis']['nomConsigne'] = 'ConsigneChambreAmis'
pieces['Chambre d\'amis']['nomSondes'] = {}
pieces['Chambre d\'amis']['nomSondes'][1] = 'Chambre d\'amis'
pieces['Chambre d\'amis']['nomRadiateurs'] = {}
pieces['Chambre d\'amis']['nomRadiateurs'][1] = 'Radiateur Chambre d\'amis'

pieces['Bureau'] = {}
pieces['Bureau']['idxConsigne'] = 34
pieces['Bureau']['nomConsigne'] = 'Consigne Bureau'
-- pieces['Bureau']['nomConsigne'] = 'ConsigneBureau'
pieces['Bureau']['nomSondes'] = {}
pieces['Bureau']['nomSondes'][1] = 'Bureau'
pieces['Bureau']['nomRadiateurs'] = {}
pieces['Bureau']['nomRadiateurs'][1] = 'Radiateur Bureau'

-- Les différentes zones à réguler
local zones = Set {}

-- Les switches de consigne
local switches = Set {}










local nomZone = {}
nomZone['Chambre']         = 'Chambre'
nomZone['Salon']           = 'Salon'
nomZone['Salle de bain']   = 'Salle de bain'
nomZone['Chambre d\'amis'] = 'Chambre d\'amis'
nomZone['Bureau']          = 'Bureau'

-- Les IDX des thermostats
-- local idThermostat = {}
-- idThermostat['Chambre']         = 31
-- idThermostat['Salon']           = 37
-- idThermostat['Salle de bain']   = 52
-- idThermostat['Chambre d\'amis'] = 39
-- idThermostat['Bureau']          = 40

-- Les IDX des selecteurs de consigne
local idConsigne = {}
idConsigne['Chambre']         = 29
idConsigne['Salon']           = 32
idConsigne['Salle de bain']   = 33
idConsigne['Chambre d\'amis'] = 35
idConsigne['Bureau']          = 34

-- Relations
local zoneDeSwitch = {}
local switchDeZone = {}
local thermostatDeSonde = {}
local radiateurDeZone = {}
--local zoneDeSonde = {}

-- Variables générées
--------------------------------------------------------------------------------
-- Génération des tableaux de relations
for k,v in pairs(nomZone) do
    zones[k] = true
    switches['Consigne ' .. v] = true
    zoneDeSwitch['Consigne ' .. v] = k
    switchDeZone[k] = 'Consigne ' .. v
    thermostatDeSonde[k] = 'Thermostat ' .. v
    radiateurDeZone[k] = 'Radiateur ' .. v
--    zoneDeSonde[k] = v
end

-- Si on veut remplacer les thermostats par des variables.
local nomVariable = {}
nomVariable['Chambre']         = 'ConsigneChambre'
nomVariable['Salon']           = 'ConsigneSalon'
nomVariable['Salle de bain']   = 'ConsigneSalleDeBain'
nomVariable['Chambre d\'amis'] = 'ConsigneChambreAmis'
nomVariable['Bureau']          = 'ConsigneBureau'
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--                                                                     FONCTIONS
--------------------------------------------------------------------------------
-- Cette fonction permet de calculer la valeur de la consigne
getConsignePiece = function(switch)
    local consigne = tonumber(otherdevices_svalues['Consigne'])
    local consigne_piece = consigne

    if (otherdevices[switch] == '-3') then
        consigne_piece = consigne - 3
    elseif (otherdevices[switch] == '-2') then
        consigne_piece = consigne - 2
    elseif (otherdevices[switch] == '-1') then
        consigne_piece = consigne - 1
    elseif (otherdevices[switch] == 'Consigne') then
        consigne_piece = consigne
    else
        consigne_piece = consigne
    end
    
    return tostring(consigne_piece)
end
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--                                                                          MAIN
--------------------------------------------------------------------------------
commandArray = {}

if (devicechanged ~= nil) then
    for deviceName,deviceValue in pairs(devicechanged) do

        -- GESTION DE LA MISE A JOUR DES THERMOSTATS / PIECE
        if (zoneDeSwitch[deviceName] ~= nil and zones[zoneDeSwitch[deviceName]] and otherdevices[modeChauffage] ~= 'Off') then
--            print('-- BOUCLE A DETECTE ACTION SUR SWITCH "' .. deviceName .. '"')

            local consigne_piece = getConsignePiece(deviceName)
            -- local url = 'http://' .. domoticzIp .. ':' .. domoticzPort .. '/json.htm?type=command&param=udevice&idx=' .. idThermostat[zoneDeSwitch[deviceName]] .. '&nvalue=0&svalue=' .. consigne_piece

            -- Avec thermostat
            -- commandArray[1] = {['OpenURL'] = url}

            -- Avec variable user
            commandArray['Variable:' .. nomVariable[zoneDeSwitch[deviceName]]] = consigne_piece

            print('-- La consigne de "' .. zoneDeSwitch[deviceName] .. '" passe à ' .. consigne_piece)
        end
        
        -- GESTION DE LA REGULATION DE TEMPERATURE / PIECE
        -- TBD : Ajouter la gestion du mode absence (tout à -3)
        if (nomZone[deviceName] ~= nil and zones[nomZone[deviceName]] and otherdevices[modeChauffage] ~= 'Off' and otherdevices[switchDeZone[nomZone[deviceName]]] ~= 'Off') then
            print('-- Gestion du thermostat pour "' .. deviceName .. '"')

            -- SI Switch ~= 'Off' alors on régule, sinon on fait rien
            local temperature = devicechanged[string.format('%s_Temperature', deviceName)]
            local consigne_piece = uservariables[nomVariable[thermostatDeSonde[deviceName]]]

            -- if (temperature < (otherdevices[thermostatDeSonde[deviceName]]) - hysteresis) then
            if (temperature < (consigne_piece - hysteresis)) then
                -- Activer tous les radiateurs de la piece
                commandArray[radiateurDeZone[nomZone[deviceName]]] = 'Off'
                print('Allumage du chauffage dans la zone "' .. nomZone[deviceName] .. '"')

            -- elseif (temperature > (otherdevices[thermostatDeSonde[deviceName]]) + hysteresis) then
            elseif (temperature > (consigne_piece + hysteresis)) then
                -- Desactiver tous les radiateurs de la pièce
                commandArray[radiateurDeZone[nomZone[deviceName]]] = 'On'
                print('Extinction du chauffage dans la zone "' .. nomZone[deviceName] .. '"')
            end
        end

        -- GESTION DE L'EXTINCTION GENERALE DU CHAUFFAGE
        if (deviceName ~= nil and (deviceName == modeChauffage)) then
            -- SI on coupe le chauffage général, on vient passer tous les selecteurs à Off.
            if (otherdevices[modeChauffage] == 'Off') then
                local i = 0
                for k,v in pairs(idConsigne) do
                    local url = 'http://' .. domoticzIp .. ':' .. domoticzPort .. '/json.htm?type=command&param=udevice&idx=' .. v .. '&nvalue=0&svalue=Off'
                    commandArray[i] = {['OpenURL'] = url}
                    i = i + 1
                end
            end
        end

        -- GESTION DE L'EXTINCTION D'UN RADIATEUR SUITE A EVENT "CONSIGNE_PIECE = Off"
        if (deviceName ~= nil and switches[deviceName]) then
            -- SI un selecteur de consigne de chauffage est à Off, on éteint le radiateur
            if (switches[deviceName] and otherdevices[deviceName] == 'Off') then
                commandArray[radiateurDeZone[nomZone[zoneDeSwitch[deviceName]]]] = 'On'
                print('Extinction du chauffage dans la zone "' .. nomZone[deviceName] .. '"')
            end
        end
    end
end

return commandArray
--------------------------------------------------------------------------------
