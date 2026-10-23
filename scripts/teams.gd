class_name Teams
extends RefCounted

# Original rosters. Ratings: speed, shooting, dunk, defense, steal, pass, power, clutch (1–10).
const DATA = [
 {"city":"CHICAGO", "name":"INFERNO", "abbr":"CHI", "color":"ff623f", "players":["HENNONHOEFER", "GAUCI"], "ratings":[[9,8,10,6,8,7,6,9],[6,7,9,10,7,6,9,7]]},
 {"city":"LOS ANGELES", "name":"AFTERSHOCK", "abbr":"LAX", "color":"b792ff", "players":["WANG", "EKKER"], "ratings":[[8,10,7,7,8,8,5,9],[7,6,10,9,6,5,9,7]]},
 {"city":"NEW YORK", "name":"CONCRETE", "abbr":"NYC", "color":"49b4ff", "players":["GHOST", "STEEL"], "ratings":[[10,8,7,7,9,9,4,8],[6,7,10,10,6,5,10,7]]},
 {"city":"MIAMI", "name":"NEON", "abbr":"MIA", "color":"ff65b3", "players":["FLASH", "VICE"], "ratings":[[10,9,7,6,9,8,5,8],[8,8,9,8,7,7,8,8]]},
 {"city":"SEATTLE", "name":"THUNDER", "abbr":"SEA", "color":"54e0ab", "players":["STORM", "VOLT"], "ratings":[[8,9,8,8,8,7,8,8],[9,7,9,8,9,8,7,8]]},
 {"city":"DETROIT", "name":"MOTOR", "abbr":"DET", "color":"ffca62", "players":["DIESEL", "TORQUE"], "ratings":[[6,7,10,10,6,5,10,7],[8,8,8,8,8,8,7,9]]},
 {"city":"PHOENIX", "name":"SOLAR", "abbr":"PHX", "color":"ff994b", "players":["FLARE", "ORBIT"], "ratings":[[9,10,6,7,8,9,4,9],[8,8,9,8,7,6,9,8]]},
 {"city":"BOSTON", "name":"CLOVER", "abbr":"BOS", "color":"8add70", "players":["LUCKY", "ANCHOR"], "ratings":[[8,10,7,8,8,8,6,9],[6,8,9,10,6,6,9,7]]}
]

static func color_for(team: int) -> Color:
 return Color(DATA[posmod(team, DATA.size())].color)
