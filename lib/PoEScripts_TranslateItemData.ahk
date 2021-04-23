﻿/*
	Unfinished, will wait until after 3.1.0 release, there are chances to get support from GGG. 
	Current data files are insufficient.
*/

PoEScripts_TranslateItemData(data, langData, locale, ByRef retObj = "", ByRef status = "") {
	If (not StrLen(locale) or locale = "en") {
		status := "Translation aborted"
		Return data
	}
					; ["en", "de", "fr", "pt", "ru", "th", "es", "ko"]
	rarityTags		:= ["Rarity", "Seltenheit", "Rareté", "Raridade", "Редкость", "ความหายาก", "Rareza", "아이템 희귀도"]	; hardcoded, no reliable translation source
	
	rareTranslation	:= ["Rare", "Selten", "Rare", "Raro", "Редкий", "แรร์", "Raro", "희귀"]					; hardcoded, at least the german term for "rare" is "wrong" and differently translated elsewhere
	superiorTag		:= ["Superior", "(hochwertig)", "de qualité", "Superior", "качества", "Superior", "Superior", "상급"]
	itemQuantity		:= ["Item Quantity", "Gegenstandsmenge", "Quantité d'objets", "Quantidade de Itens", "Количество предметов", "จำนวนไอเท็ม", "Cantidad de Ítems", "아이템 수량"]
	itemRarity		:= ["Item Rarity", "Gegenstandsseltenheit", "Rareté des objets", "Raridade de Itens", "Редкость предметов", "ระดับความหายากของไอเทม", "Rareza de Ítem", "아이템 희귀도"]
	packSize			:= ["Monster Packsize", "Monstergruppengröße", "Taille des groupes de monstres", "Tamanho do Grupo de Monstros", "Размер групп монстров", "ขนาดบรรจุมอนสเตอร์", "Tamaño de Grupos de Monstruos", "몬스터 팩 크기"]
	weaponRange		:= ["Weapon Range", "Waffenreichweite", "", "", "", "", "", "무기 공격 범위"]
	physicalDamage		:= ["Physical Damage", "Physischer Schaden", "", "", "", "", "", "물리 피해"]
	elementalDamage	:= ["Elemental Damage", "Elementarschaden", "", "", "", "", "", "원소 피해"]
	chanceToBlock		:= ["Chance to Block", "Chance auf Blocken", "", "", "", "", "", "막아낼 확률"]
	manaCost			:= ["Mana Cost", "Manakosten", "", "", "", "", "", "총 마나"]
	castTime			:= ["Cast Time", "Zauberzeit", "", "", "", "", "", "시전 시간"]
	cooldownTime		:= ["Cooldown Time", "Abklingzeit", "", "", "", "", "쿨다운 시간"]
	damageEffectiveness	:= ["Damage Effectiveness", "Effektivität zusätzlichen Schadens", "", "", "", "", "", "Damage Effectiveness"]
	manaReserved		:= ["Mana Reserved", "Mana reserviert", "", "", "", "", "", "점유 마나"]
	manaMultiplier		:= ["Mana Multiplier", "Manamultiplikator", "", "", "", "", "", "마나 배율"]
	evasionRating		:= ["Evasion Rating", "Ausweichwert", "", "", "", "", "", "회피"]
	limitedTo			:= ["Limited to", "Begrenzt auf", "", "", "", "", "", "Limited to"]
	radius			:= ["Radius", "Radius", "", "", "", "", "", "반경"]
	
	regex 			:= {}
	regex.superior		:= ["^Superior(.*)", "(.*)\(hochwertig\)$", "(.*)de qualité$", "(.*)Superior$", "(.*)качества$", "^Superior(.*)", "(.*)Superior$", "(.*)상급$"]
	regex.map			:= ["(.*)Map", "Karte.*'(.*)'", "Carte:(.*)","Mapa:(.*)", "Карта(.*)", "(.*)Map", "Mapa de(.*)", "(.*)지도"]
	
	regex.magicItem	:= {}
	regex.magicItem.en	:= "im).*?([^ ]+\s+[^ ]+)(?:\sof.*)|([^ ]+\s+[^ ]+)$"
	regex.magicItem.de	:= "im).*?([^ ]+\s+[^ ]+)(?:\s(?:der|des).*)|([^ ]+\s+[^ ]+)$"
	regex.magicItem.fr	:= "(.*?)(?:\s(?:de la\s|de l'|du\s))(?:.*)"
	regex.magicItem.pt	:= "(.*?)(?:\s(?:do\s|da\s))(?:.*)"
	regex.magicItem.ru	:= "(.*)"
	regex.magicItem.th	:= "im).*?([^ ]+\s+[^ ]+)(?:\sof.*)|([^ ]+\s+[^ ]+)$"
	regex.magicItem.es	:= "im)(?:de la|del)\s[\w]+(.*)|([\w]+\sde\s[\w]+.*)|(.*)(?:de la|del)"
	
	If (locale == "ko") {
		regex.magicItem.ko	:= "(.*)"
	}
	
	lang := new TranslationHelpers(langData, regex)
	
	;---- Not every item has every section,  depending on BaseType and Corruption/Enchantment
	; Section01 = NamePlate (Rarity, ItemName, ItemBaseType)
	; Section02 = Armour/Weapon innate stats like EV, ES, AR, Quality, PhysDmg, EleDmg, APs, CritChance AND Flask Charges/Duration etc
	; Section03 = Requirements (dex, int, str, level)
	; Section04 = Implicit Mod / Enchantment
	; Section05 = Explicit Mods
	; Section06 = Corruption tag
	; Section07+ = Descriptions/Flavour Texts
	
	; push all sections to array
	sections	:= []
	sectionsT := []
	Pos		:= 0

	_data := data "--------"
	While Pos := RegExMatch(_data, "is)(.*?)(?:\r\n-{8})|(.*?)(?:\n-{8})", section, Pos + (StrLen(section) ? StrLen(section) : 1)) {
		sectionLines := []
		cLine := StrLen(section1) ? section1 : section2
		Loop, parse, cLine, `n, `r   
		{
			If (StrLen(Trim(A_LoopField))) {
				sectionLines.push(Trim(A_LoopField))
			}
		}
		sections.push(sectionLines)
	}

	; 2021-04-20
	; [결전 리그] '아이템 종류' 상단 위치에 신규 추가로, 파싱 오류
	; - 번역할때는 '아이템 종류' 삭제
	; - 번역이 완료되고, '아이템 종류' 재추가
	itemClass :=  sections[1][1]
	sections[1].RemoveAt(1)
	
	_specialTypes := ["Currency", "Divination Card"]
	_ItemBaseType := ""
	_item := {}

	For key, section in sections {
		sectionsT[key] := []
		
		/*
			nameplate section, look for ItemBaseType which is important for further parsing.
		*/
		If (key = 1) {
			/*
				rarity
			*/
			RegExMatch(section[1], "i)(.*?):(.*)", keyValuePair)
			If (lang.IsInArray(keyValuePair1, rarityTags, posFound)) {
				_item.default_rarity:= lang.GetBasicInfo(Trim(keyValuePair2))
				_item.local_rarity	:= Trim(keyValuePair2)			
				
				; TODO: improve this, only works for "rare", not sure if needed
				If (not _item.default_rarity) {
					_item.default_rarity := lang.GetBasicInfo(rareTranslation[posFound])						
				}				
				sectionsT[key][1] := "Rarity: " _item.default_rarity
			}
			
			/*
				name and basetype
			*/
			sectionLength := section.MaxIndex()
			; remove "superior" when using name as search needle
			needleName := Trim(RegExReplace(section[2], "" regex.superior[posFound] "", "$1", replacedSuperiorTag))			
			
			_obj := lang.GetItemInfo(section[3], needleName, _item.default_rarity, _item.rarityLocal)
			sectionsT[key][2] := _obj.default_name ? _obj.default_name : Trim(section[2])
			If (replacedSuperiorTag) {
				sectionsT[key][2] := "Superior " sectionsT[key][2]
			}
			
			sectionsT[key][3] := _obj.default_baseType ? _obj.default_baseType : Trim(section[3])
			lang.AddPropertiesToObj(_item, _obj)
			
			; don't set third line if name and baseType are the same (currency, cards etc)
			If (_item.default_name == _item.default_baseType or RegExMatch(_item.default_baseType, "" regex.map[posFound] "")) {			
				sectionsT[key][3] := ""
			}
			
			_ItemBaseType := sectionsT[key][3]
		}
		
		/*
			Armour/Weapon innate stats like EV, ES, AR, Quality, PhysDmg, EleDmg, APS, CritChance
			Flask Charges/Duration
			Map PackSize, Rarity, Quantity etc
		*/		
		If (key = 2) {
			For k, line in section {
				RegExMatch(line, "i)(.*?)(:):?(.*)|(.*)", part)
				part1 := StrLen(part4) ? part4 : part1

				If "무기 범위" = part1
					_p1 := "Weapon Range"
				Else
					_p1 := lang.GetBasicInfo(Trim(part1))
				
				If (not _p1) {
					; TODO: find alternative to this hardcoded shit
					
					; maps
					If (_item.default_type = "map") {
						_p1 := (lang.IsInArray(Trim(part1), itemRarity, foundPos)) ? itemRarity[1] : _p1
						_p1 := (lang.IsInArray(Trim(part1), itemQuantity, foundPos)) ? itemQuantity[1] : _p1
						_p1 := (lang.IsInArray(Trim(part1), packSize, foundPos)) ? packSize[1] : _p1
					}
					
					If (RegExMatch(_item.default_type, "i)armour|weapon")) {
						; weapons / shields
						_p1 := (lang.IsInArray(Trim(part1), physicalDamage, foundPos)) ? physicalDamage[1] : _p1
						_p1 := (lang.IsInArray(Trim(part1), elementalDamage, foundPos)) ? elementalDamage[1] : _p1
						_p1 := (lang.IsInArray(Trim(part1), weaponRange, foundPos)) ? weaponRange[1] : _p1
						_p1 := (lang.IsInArray(Trim(part1), chanceToBlock, foundPos)) ? chanceToBlock[1] : _p1
						
						; armour
						_p1 := (lang.IsInArray(Trim(part1), evasionRating, foundPos)) ? evasionRating[1] : _p1
					}
					
					; TODO: Flasks
					If (_item.default_type = "flask") {
						
					}
					
					; Gems
					If (_item.default_type = "gem") {					
						_p1 := (lang.IsInArray(Trim(part1), manaCost, foundPos)) ? manaCost[1] : _p1
						_p1 := (lang.IsInArray(Trim(part1), castTime, foundPos)) ? castTime[1] : _p1
						_p1 := (lang.IsInArray(Trim(part1), cooldownTime, foundPos)) ? cooldownTime[1] : _p1
						_p1 := (lang.IsInArray(Trim(part1), damageEffectiveness, foundPos)) ? damageEffectiveness[1] : _p1
						_p1 := (lang.IsInArray(Trim(part1), manaReserved, foundPos)) ? manaReserved[1] : _p1
						; TODO: Gem tags?
					}
					
					; Jewels
					If (_item.default_type = "jewel") {					
						_p1 := (lang.IsInArray(Trim(part1), limitedTo, foundPos)) ? limitedTo[1] : _p1						
					}
				}
				
				If (_p1 != "")
					sectionsT[key][k] := _p1 . part2 . part3
			}
		}
		
		/*
			Requirements
			Item Level
			Sockets
			Implicit/Corruption (Amulet without requirements for example)
			
			Affixes/Enchantments/Corruptions
		*/
		If (key >= 3) {
			For k, line in section {
				; requirements etc
				RegExMatch(line, "i)(.*?)(:):?(.*)|(.*)", part)
				part1 := StrLen(part4) ? part4 : part1
				
				_p1 := lang.GetBasicInfo(Trim(part1))
				
				If (_p1) {
					sectionsT[key][k] := _p1 . part2 . part3	
				} Else {
					_p1 := lang.GetItemAffix(line)
					If (_p1) {
						sectionsT[key][k] := _p1
					} Else {
						sectionsT[key][k] := "ERROR, NOT FOUND: " line
					}
				}
			}			
		}

	}

	sectionsT[1].InsertAt(1, itemClass)

	; debugprintarray(sectionsT)
	retObj := sectionsT
	
	data := ""
	spacer := "--------"
	For key, sectionT in sectionsT {
		For k, lineT in sectionT {
			If (not InStr(lineT, "ERROR, NOT FOUND:")) {			
				data .= lineT "`n"
			}
		}
		
		If (locale == "ko") {
			If (not key = sectionsT.MaxIndex()) {
				data .= spacer "`n"
			}
		} Else {
			If (not k = sectionsT.MaxIndex()) {
				data .= spacer "`n"
			}
		}
	}
	
	Return data
}

class TranslationHelpers {
	__New(dataObj, regExObj)
	{
		this.data	:= dataObj
		this.regEx := regExObj
	}
	
	GetBasicInfo(needle, reverse = false) {
		basic := this.data.localized.basic

		For key, val in basic {
			If (not reverse) {
				If (needle = val.localized and StrLen(needle)) {
					Return val.default
				}	
			}
			Else {
				If (needle = val.default and StrLen(needle)) {
					Return val.localized
				}				
			}
		}
	}
	
	GetItemAffix(affixLine) {
		; TODO : Enchantments/some League stone mods are missing
		localized	:= this.data.localized.stats
		default 	:= this.data.default.stats

		_m		:= {}
		For k, types in localized {
			typeLocal := types.label
			If (not typeLocal = "pseudo") {
				For i, stat in types.entries {
					;replace strings in parentheses with regex, can be optional like (local) and hidden on the item or an actual mod having parentheses
					;search_stat := RegExReplace(stat.text, "(?:\s)?\((.*)\)", "(\s?\($1\))?")

					; kyan (...) 괄호도 체크하도록 수정
					search_stat := RegExReplace(stat.text, "(?:\s)?\((.*)\)", "(\s?\($1\))")

					search_stat := RegExReplace(search_stat, "(X|Y)(\%)?", "[0-9.]+$2")

					; kyan
					If (true) {
						search_stat := RegExReplace(search_stat, "총 \+", "+")
						search_stat := RegExReplace(search_stat, "\+", "\+")
						search_stat := RegExReplace(search_stat, "#", "\d*")
					}

					If (RegExMatch(affixLine, "i)" search_stat "", match)) {
						_m.local_match := match
						_m.local_text  := stat.text
						_m.local_line	:= affixLine
						_m.stat_id	:= stat.id
						_m.default_type:= stat.type
						found := true
						Break
					}
				}
			}
			If (found) {
				Break
			}
		} 
		
		; get english affix name
		If (_m.stat_id) {
			For k, types in default {			
				If (types.label = _m.default_type) {
					For i, stat in types.entries {
						If (stat.id = _m.stat_id) {
							_m.default_text := stat.text
							Break
						}
					}
				}
				If (_m.default_text) {
					Break
				}
			}			
		}
		
		values_local := this.GetAllMatches(_m.local_line, "((?:\+|-)?[0-9.]+\%?)")
		
		If (true) {
			_m.default_line := this.ReplaceAllMatches(_m.default_text, values_local, "(?:(?:\+|-)?#+\%?)")
		} Else {
			_m.default_line := this.ReplaceAllMatches(_m.default_text, values_local, "(?:(?:\+|-)?[0-9.XY]+\%?)")
		}
		_m.default_line := RegExReplace(_m.default_line, "(\s\(Local|Map|Staves|Shields\))")
		
		;DebugPrintArray(_m)	
		
		Return _m.default_line
	}
	
	GetAllMatches(s, regex) {
		m := []
		Pos := 0
		While Pos := RegExMatch(s, "" regex "", value, Pos + (StrLen(value) ? StrLen(value) : 1)) {
			m.push(value)
		}
		Return m
	}
	
	ReplaceAllMatches(s, r, reg) {
		If (not r.MaxIndex()) {
			Return s
		}
		regex	:= "(.*?)"
		replaceWith := ""
		
		i := 0		
		For k, val in r {
			If (k = r.MaxIndex()) {
				regex .= reg "(.*)"
			} Else {
				regex .= reg "(.*?)"	
			}
			i++
			replaceWith .= "$" i "" val 
		}
		replaceWith .= "$" i + 1		
		
		Regexmatch(s, "" regex "", match)
		s := RegExReplace(s, "" regex "", replaceWith)
		
		;debugprintarray([s, regex, replaceWith, match])
		Return s
	}
	
	GetItemInfo(needleType, needleName = "", needleRarity = "", needleRarityLocal = "") {
		localized	:= this.data.localized.items
		default 	:= this.data.default.items
		
		currentLocale := this.data.currentLocale
		
		local	:= this.data.localized.static
		def	 	:= this.data.default.static	

		
		; magic items have only a name, containing pre- and suffix, try to match the type agaisnt a substring of the name
		If (needleRarity = "magic") {
			RegExMatch(needleName, "" this.regEx.magicItem[currentLocale] "", match)		
			magic_capturegroups := []
			; TODO = improve this
			Loop, 20 {
				If (StrLen(match%A_Index%)) {
					magic_capturegroups.push(match%A_Index%)	
				}
			}						
		}
		
		isUnique := needleRarity = "Unique"	
		
		_arr := {}
		found := false
		Loop, % localized.MaxIndex() {
			i := A_Index
			For key, val in localized[i] {			
				label := localized[i].label
				If (key = "entries") {
					For k, v in val {
						If (isUnique and not v.flags.unique) {
							continue
						}
						
						; currency, gems, cards and other similiar items use their name as type 
						If (not StrLen(needleType)) {							 
							If (needleRarity = "magic") {		
								For c, capturegroup in magic_capturegroups {
									If (InStr(capturegroup, v.type, 0)) {
										foundType := v.type										
									}	
								}
							} Else {
								foundType := v.type = Trim(needleName) and Strlen(v.type) ? true : false	
							}
						} Else {							
							foundType := v.type = Trim(needleType) and Strlen(v.type) ? true : false
						}
						
						If (isUnique) {
							foundName := v.name = Trim(needleName) and Strlen(v.name) ? true : false							
						}
						
						If (foundType and isUnique and not foundName) {
							continue
						}
						
						If (foundName and foundType) {
							_arr.local_name		:= v.name
							_arr.lcoal_baseType		:= v.type
							_arr.local_type		:= label
							_arr.default_name		:= default[i][key][k].name
							_arr.default_baseType	:= default[i][key][k].type
							_arr.default_type		:= default[i].label
							found := true
							Break
						}
						Else If (foundType) {
							_arr.local_name		:= needleName
							_arr.local_baseType		:= v.type
							_arr.local_type		:= label
							_arr.default_baseType	:= default[i][key][k].type
							_arr.default_type		:= default[i].label
							If (not StrLen(needleType) and not needleRarity = "magic") {
								_arr.default_name	:= default[i][key][k].type
							}
							found := true
							Break
						}
					}
				}
				If (found) {
					Break
				}
			}
			If (found) {
				Break
			}
		}	

		; backup check for static items (div cards, currency, maps, leaguestones, fragments, essences etc)
		If (not found) {			
			id := ""
			index := ""
			
			For k, v in local {
				For key, val in local[k] {
					If (val.text = needleName or val.text = needleType) {
						id := val.id
						index := k
						Break
					}
				}	
			}			

			For key, val in def[index] {				
				If (val.id = id) {
					_arr.local_name		:= needleName					
					_arr.default_name		:= val.text
					
					If (RegExMatch(index, "i)maps")) {
						_arr.local_baseType		:= needleName				
						_arr.local_type		:= RegExReplace(needleName, "" this.regEx.map "", "$1")
						_arr.default_baseType	:= val.text
						_arr.default_type		:= "Map"
					} Else {
						_arr.local_baseType		:= ""
						_arr.local_type		:= needleRarityLocal
						_arr.default_baseType	:= ""
						_arr.default_type		:= needleRarity
					}
					found := true
					Break					
				}
				If (found) {
					Break
				}
			}			
		}
		
		; replace the type with it's singular form
		typePlural	:= ["Weapons", "Armour", "Accessories", "Gems", "Jewels", "Flasks", "Maps", "Leaguestones", "Prophecies", "Cards", "Currency"]
		typeSingular	:= ["Weapon", "Armour", "Accessory", "Gem", "Jewel", "Flask", "Map", "Leaguestone", "Prophecy", "Card", "Currency"]		
		_arr.default_type := (replaced := this.IsInArray(_arr.default_type, typePlural, posFound)) ? typeSingular[posFound] : _arr.default_type
		
		If (replaced) {			
			_arr.local_type := (StrLen(_tempType := this.GetBasicInfo(_arr.default_type, true))) ? _tempType : _arr.local_type
		}		
		;debugprintarray(_arr)
		
		Return _arr
	}
	
	AddPropertiesToObj(ByRef target, source) {
		For key, val in source {
			target[key] := val
		}
	}
	
	IsArray(obj) {
		Return !!obj.MaxIndex()
	}
	
	CaptureGroupsToArray(match) {
		; TODO = improve this
		
		Return
	}

	; Trim trailing zeros from numbers
	ZeroTrim(number) {
		RegExMatch(number, "(\d+)\.?(.+)?", match)
		If (StrLen(match2) < 1) {
			Return number
		} Else {
			trail := RegExReplace(match2, "0+$", "")
			number := (StrLen(trail) > 0) ? match1 "." trail : match1
			Return number
		}
	}

	IsInArray(el, array, ByRef i) {
		For i, element in array {
			If (el = "") {
				Return false
			}
			If (element = el) {
				Return true
			}
		}
		Return false
	}

	CleanUp(in) {
		StringReplace, in, in, `n,, All
		StringReplace, in, in, `r,, All
		Return Trim(in)
	}


	Arr_concatenate(p*) {
		res := Object()
		For each, obj in p
			For each, value in obj
				res.Insert(value)
		return res
	}
}