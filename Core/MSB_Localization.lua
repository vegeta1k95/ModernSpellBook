--[[
	Multi-language locale strings.
	Supported: enUS, frFR, deDE, esES, esMX, ruRU (ZamestoTV)
--]]

class "CLocalization"
{
	__init = function(self)
		self.locales = {}

		self.locales["enUS"] = {
			ShowPassive = "Show passives",
			SearchAbilities = "Search abilities, keywords",
			NoResults = "No results. Try a different search term.|nFor example, '",
			NoPetSpells = "No pet spells available.",
		}

		self.locales["frFR"] = {
			ShowPassive = "Afficher les passifs",
			SearchAbilities = "Capacités de recherche, mots-clés",
			NoResults = "Aucun résultat. Essayez un autre terme de recherche.|nPar exemple, '",
			NoPetSpells = "Aucune compétence de familier disponible.",
		}

		self.locales["deDE"] = {
			ShowPassive = "Passive anzeigen",
			SearchAbilities = "Suchfunktionen, Schlüsselwörter",
			NoResults = "Keine Ergebnisse. Versuchen Sie es mit einem anderen Suchbegriff.|nZum Beispiel, '",
			NoPetSpells = "Keine Begleiterfähigkeiten verfügbar.",
		}

		self.locales["esES"] = {
			ShowPassive = "Mostrar pasivos",
			SearchAbilities = "Capacidades de búsqueda, palabras clave",
			NoResults = "Sin resultados. Pruebe con un término de búsqueda diferente.|nPor ejemplo, '",
			NoPetSpells = "No hay hechizos de mascota disponibles.",
		}

		self.locales["esMX"] = {
			ShowPassive = "Mostrar pasivas",
			SearchAbilities = "Buscar habilidades, palabras clave",
			NoResults = "Sin resultados. Intenta con otro término de búsqueda.|nPor ejemplo, '",
			NoPetSpells = "No hay hechizos de mascota disponibles.",
		}

		self.locales["ruRU"] = {
			ShowPassive = "Показать пассивные",
			SearchAbilities = "Поиск способностей, ключевые слова",
			NoResults = "Нет результатов. Попробуйте другой поисковый запрос.|nНапример, '",
			NoPetSpells = "Нет доступных заклинаний питомца.",
		}

		self.current = self.locales[GetLocale()] or self.locales["enUS"]
	end;

	Get = function(self, key)
		return self.current[key]
	end;
}

Localization = CLocalization()
