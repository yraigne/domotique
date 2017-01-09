--------------------------------------------------------------------------------
-- Source : http://domoticz.blogspot.fr/2014/07/un-exemple-de-script-lua-time-coherence.html
-- Permet de renvoyer la commande actuelle sensée etre appliquée aux modules en 433 ( sans retour d'etat ) toutes les 15 minutes
--------------------------------------------------------------------------------

commandArray = {}

-- Recupere les minutes
time = os.time()
minutes = tonumber(os.date('%M',time))
hours = tonumber(os.date('%H',time))

print('!*!*!*!*!*!*!*!*!Lancement du check à '..hours..'h'..minutes)

-- On s'assure que le check ne se lance bien que toutes les 15 minutes
--------------------------------------------------------------------------------

if ( (minutes == 15) or (minutes == 0) or (minutes == 30) or (minutes == 45) ) then
  -- Renforcement des envois de signal
  ------------------------------------------------------------------------------
  print('- Check de tous les materiels rfxcom (sans retour d\'etat)');

  local check = {}
  -- Chauffage
  check['0'] = 'Radiateur Mathilde'
  check['1'] = 'Radiateur Parents'
  check['2'] = 'Radiateur Salle De Bain'
  -- VMC
  check['3'] = 'VMC'
  -- Lumieres
  check['4'] = 'Lumiere TV'
  check['5'] = 'Lumiere Salle De Jeu'
  -- Piscine
  check['6'] = 'Filtration Piscine Temp'

  -- Parcours le Tableau
  for key, valeur in pairs(check) do
    print ('CHECK : ' .. valeur .. ' -> ' .. otherdevices[valeur])
    commandArray[valeur] = otherdevices[valeur]
  end
  -- FIN Renforcement des envois de signal
  ------------------------------------------------------------------------------
end 
-- FIN Toutes les 15 minutes
--------------------------------------------------------------------------------

-- Une fois par heure, verifie l'age des mesures
if ( (minutes == 0) or (minutes == 1) ) then
  local temp = {}
  -- Temperatures
  temp['0'] = 'Mathilde'
  temp['1'] = 'Parents'
  temp['2'] = 'Salle De Bain'
  temp['3'] = 'Salon'
  temp['4'] = 'Meteo'
  --temp['4'] = 'Entree'

  -- Delai au dela duquel on alerte en secondes
  local alerte = 3600

  local mail = 'Alerte sur sonde temperature'
  local trigger = 0

  -- Parcours le Tableau de stemperatures
  for key, valeur in pairs(temp) do
    s = otherdevices_lastupdate[valeur]
    -- returns a date time like 2013-07-11 17:23:12
    
    t1 = os.time()
    year = string.sub(s, 1, 4)
    month = string.sub(s, 6, 7)
    day = string.sub(s, 9, 10)
    hour = string.sub(s, 12, 13)
    minutes = string.sub(s, 15, 16)
    seconds = string.sub(s, 18, 19)

    commandArray = {}
    t2 = os.time{year=year, month=month, day=day, hour=hour, min=minutes, sec=seconds}
    difference = (os.difftime (t1, t2))

    print ('CHECK Temperature: ' .. valeur .. ' -> ' .. otherdevices[valeur] .. ' age = ' .. difference .. ' secondes')

    if (difference > alerte) then
      mail = mail .. 'Age de ' .. valeur .. '-> ' .. difference .. ' secondes !!
'
      trigger = trigger + 1  
    end
  end

  if (trigger > 0) then
    commandArray['SendEmail'] = 'Alerte Age Sonde Temperature #Attention aux sondes suivantes :

' .. mail .. ' #naerleth@gmail.com'
  end
end

return commandArray