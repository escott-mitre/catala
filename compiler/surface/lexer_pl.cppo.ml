(* -*- coding: iso-latin-1 -*- *)

(* This file is part of the Catala compiler, a specification language for tax and social benefits
   computation rules. Copyright (C) 2020 Inria, contributors: Denis Merigoux
   <denis.merigoux@inria.fr>, Emile Rolley <emile.rolley@tuta.io>

   Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except
   in compliance with the License. You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software distributed under the License
   is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express
   or implied. See the License for the specific language governing permissions and limitations under
   the License. *)

(* Defining the lexer macros for Polish *)

(* Tokens and their corresponding sedlex regexps *)

#define MS_SCOPE "zakres"
#define MS_CONSEQUENCE "konsekwencja"
#define MS_DATA "data"
#define MS_DEPENDS "zalezy od"
#define MR_DEPENDS "zalezy", space_plus, "od"
#define MS_DECLARATION "deklaracja"
#define MS_CONTEXT "kontekst"
#define MS_DECREASING "malejacy"
#define MS_INCREASING "rosnacy"
#define MS_OF "z"
#define MS_COLLECTION "kolekcja"
#define MS_CONTAINS "zawiera"
#define MS_ENUM "enumeracja"
#define MS_INTEGER "calkowita"
#define MS_MONEY "pieniądze"
#define MR_MONEY "pieni", 0x0105, "dze"
#define MS_TEXT "tekst"
#define MS_DECIMAL "dziesiętny"
#define MR_DECIMAL "dziesi", 0x0119, "tny"
#define MS_DATE "czas"
#define MS_DURATION "czas trwania"
#define MR_DURATION "czas", space_plus, "trwania"
#define MS_BOOLEAN "zerojedynkowy"
#define MS_SUM "suma"
#define MS_FILLED "spelnione"
#define MS_DEFINITION "definicja"
#define MS_STATE "stan"
#define MS_LABEL "etykieta"
#define MS_EXCEPTION "wyjątek"
#define MR_EXCEPTION "wyj", 0x0105, "tek"
#define MS_DEFINED_AS "wynosi"
#define MS_MATCH "pasuje"
#define MS_WILDCARD "cokolwiek"
#define MS_WITH "ze wzorem"
#define MR_WITH "ze", space_plus, "wzorem"
#define MS_UNDER_CONDITION "pod warunkiem"
#define MR_UNDER_CONDITION "pod", space_plus, "warunkiem"
#define MS_IF "jezeli"
#define MS_THEN "wtedy"
#define MS_ELSE "inaczej"
#define MS_CONDITION "warunek"
#define MS_CONTENT "typu"
#define MS_STRUCT "struktura"
#define MS_ASSERTION "asercja"
#define MS_VARIES "rozna"
#define MS_WITH_V "wraz z"
#define MR_WITH_V "wraz", space_plus, "z"
#define MS_FOR "dla"
#define MS_ALL "wszystkie"
#define MS_WE_HAVE "mamy"
#define MS_FIXED "staloprzecinkowa"
#define MS_BY "przez"
#define MS_RULE "zasada"
#define MS_LET "niech"
#define MS_EXISTS "istnieje"
(* "in" or "w" ? *)
#define MS_IN "in"
#define MS_AMONG "wśród"
#define MR_AMONG "w", 0x15B,"r", 0xf3,"d"
#define MS_SUCH "takie ze"
#define MR_SUCH "takie", space_plus, "ze"
#define MS_THAT "to"
#define MS_AND "i"
#define MS_OR "lub"
#define MS_XOR "xor"
#define MS_NOT "nie"
#define MS_MAXIMUM "maximum"
#define MS_MINIMUM "minimum"
#define MS_IS "jest"
#define MS_EMPTY "pusty"
#define MS_CARDINAL "liczba"
#define MS_YEAR "rok"
#define MS_MONTH "miesiac"
#define MS_DAY "dzien"
#define MS_TRUE "prawda"
#define MS_FALSE "falsz"
#define MS_INPUT "wejście"
#define MR_INPUT "wej", 0x15B, "cie"
#define MS_OUTPUT "wyjście"
#define MR_OUTPUT "wyj", 0x15B, "cie"
#define MS_INTERNAL "wewnętrzny"
#define MR_INTERNAL "wewn", 0x0119, "trzny"

(* Specific delimiters *)

#define MS_MONEY_OP_SUFFIX "$"
#define MC_DECIMAL_SEPARATOR '.'
#define MR_MONEY_PREFIX ""
#define MR_MONEY_DELIM ','
#define MR_MONEY_SUFFIX Star hspace, "PLN"

(* Builtins *)

#define MS_Round "zaokrąglony"
#define MR_Round "zaokr",0x0105,"glony"
#define MS_GetDay "dostęp_dzień"
#define MR_GetDay "dost", 0x0119, "p_dzie", 0x144
#define MS_GetMonth "dostęp_miesiąc"
#define MR_GetMonth "dost", 0x0119, "p_miesi", 0x0105, "c"
#define MS_GetYear "dostęp_rok"
#define MR_GetYear "dost", 0x0119, "p_rok"
#define MS_FirstDayOfMonth "pierwszy_dzień_miesiąca"
#define MR_FirstDayOfMonth "pierwszy_dzie", 0x144, "_miesi", 0x0105, "ca"
#define MS_LastDayOfMonth "ostatni_dzień_miesiąca"
#define MR_LastDayOfMonth "ostatni_dzie", 0x144, "_miesi", 0x0105, "ca"

(* Directives *)

#define MR_LAW_INCLUDE "Include"
#define MX_AT_PAGE \
   '@', Star hspace, "p.", Star hspace, Plus digit -> \
      let s = Utf8.lexeme lexbuf in \
      let i = String.index s '.' in \
      AT_PAGE (int_of_string (String.trim (String.sub s i (String.length s - i))))
