# -*- coding: utf-8 -*-
"""Charge `paramètres.xlsx` dans `parametres_legaux`, clé = colonne `Abrege`.

    python tools/charger_parametres.py                    # constate
    python tools/charger_parametres.py --ecrire           # écrit la migration

Le classeur est la source. Sa structure, relevée et non supposée :

* ligne 1  : une date d'effet par colonne ;
* ligne 2  : les en-têtes `Abrege` et `Description` ;
* colonne A: `Abrege` — l'identifiant court, qui devient `cle_parametre` ;
* colonne B: la description, ou un **titre de section** quand `Abrege` est vide ;
* colonnes C à G : les deux colonnes de travail, valeur calculée et formule ;
* colonnes H et suivantes : les relevés historiques, du plus récent au plus ancien.

Trois pièges, tous rencontrés :

1. **Une cellule vide ne vaut pas zéro.** Dans les colonnes historiques, les
   valeurs dérivées ne sont pas recopiées : le SSM au 1er janvier 2025 est vide
   parce qu'il se calcule de `ssm_100` et de l'indice. Une cellule vide n'est
   donc pas chargée — surtout pas comme 0.
2. **Les titres de section donnent la famille.** « 4) ASSURANCE PENSION »,
   « Risque Part Employeur », « Mutualité » : la famille se lit dans le classeur
   au lieu d'être devinée clé par clé.
3. **Un `Abrege` en double est un défaut de la source.** `REVISE` désigne deux
   montants différents. Charger l'un des deux au hasard produirait un calcul faux
   et silencieux : la clé est refusée et signalée.

L'horizon de chargement s'arrête au 2025-01-01. Les colonnes 2025-05-01 et
2026-06-01 existent déjà dans le classeur mais ne sont pas chargées : le socle de
calcul et les tests sont arrêtés à cette date.
"""
from __future__ import annotations

import argparse
import datetime as dt
import io
import re
import sys
from pathlib import Path

# Envelopper stdout une seule fois : deux modules qui le font à l'import se
# marchent dessus, le second détachant le tampon du premier — d'où un
# « I/O operation on closed file » au premier print du module appelant.
if (sys.stdout.encoding or "").lower().replace("-", "") != "utf8":
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")

RACINE = Path(__file__).resolve().parent.parent
CLASSEUR = RACINE / "lois_et_règlements" / "paramètres.xlsx"
MIGRATIONS = RACINE / "luxrh" / "supabase" / "migrations"

HORIZON = dt.date(2025, 1, 1)
SENTINELLE_DEBUT = dt.date(1970, 1, 1)
SENTINELLE_FIN = dt.date(2037, 12, 31)

# Les deux colonnes de travail du classeur : valeur courante et formule. Elles
# doublonnent les colonnes datées et ne se chargent pas.
COLONNES_DE_TRAVAIL = {"C", "D", "E", "F", "G"}

# Titre de section -> famille de `parametres_legaux`. Le classeur groupe ses
# lignes ; on suit son découpage plutôt que d'inventer le nôtre.
FAMILLE_PAR_SECTION = {
    "MINIMA ET MAXIMA COTISABLES": "social",
    "2) ASSURANCE MALADIE": "ccss",
    "3) ASSURANCE DEPENDANCE": "ccss",
    "4) ASSURANCE PENSION": "ccss",
    "5) PRESTATIONS FAMILIALES": "social",
    "6) REVENU D’INCLUSION SOCIALE (REVIS) ET AUTRES PRESTATIONS MIXTES": "social",
    "Risque Part Assuré": "ccss",
    "Risque Part Employeur": "ccss",
    "Assurance accident": "ccss",
    "Mutualité": "ccss",
    "Bail": "fiscal",
    "PARAMÈTRES SOCIAUX": "social",
}

# Le bloc final du classeur ne porte pas de titre de section. Chaque clé y reçoit
# sa famille explicitement : une famille fausse range un paramètre là où personne
# ne le cherchera.
FAMILLE_PAR_CLE = {
    "HEURS_MOIS": "temps_travail",
    "VAL_PER_ESS_1_AN": "contrat",
    "H_SUP_PCT": "temps_travail",
    "H_DIM_PCT": "temps_travail",
    "H_NUI_PCT": "temps_travail",
    "H_FER_PCT": "temps_travail",
    "H_DIM_U18_PCT": "temps_travail",
    "H_SUP_REPOS": "temps_travail",
    "H_CHOM": "temps_travail",
    "H_NUIT": "temps_travail",
    "H_MATIN": "temps_travail",
    "CONGE_J": "conges",
    "CONGE_MIN": "conges",
    "CONGE_HANDICAP": "conges",
    "JOUR_H": "temps_travail",
    "JOUR_MAX_H": "temps_travail",
    "SEMAINE_H": "temps_travail",
    "SEMAINE_MAX": "temps_travail",
    "HS_3M": "temps_travail",
    "HS_4M": "temps_travail",
    "REPOS_MIN": "temps_travail",
    "REPOS_WE": "temps_travail",
    "REPOS_N_WE_1J": "temps_travail",
    "SUB_INT_1": "aide",
    "SUB_INT_1A_2L": "aide",
    "SUB_PRE_1": "aide",
    "SUB_PRE_1A_2L": "aide",
    "COTISATION_PROFESSIONNELLE": "social",
    "CR_PAR": "fiscal",
    "CR_MAX": "fiscal",
    "CR_NB": "fiscal",
    "indice": "social",
    # Ligne 214, « Bail », porte son intitulé en colonne A : elle n'est donc pas
    # reconnue comme titre de section, et le bloc du logement de fonction héritait
    # de « Mutualité ». Les six clés reçoivent leur famille explicitement.
    "bail_m2": "fiscal", "Bail_charge": "fiscal", "Bail_employeur": "fiscal",
    "bail_salarié": "fiscal", "bail_meublé": "fiscal",
    "ssm_100": "social",
}

# Références légales, reprises du référentiel existant ou relevées dans le XML du
# Code du travail. Les clés absentes d'ici restent sans référence : `fn_referential_gaps`
# les signalera. Une référence inventée serait pire qu'une référence manquante.
REFERENCE_PAR_CLE = {
    "SEMAINE_MAX": "art. L.211-12",
    "JOUR_MAX_H": "art. L.211-12",
    "SEMAINE_H": "art. L.211-5",
    "JOUR_H": "art. L.211-5",
    "REPOS_MIN": "art. L.211-16",
    "REPOS_WE": "art. L.231-2",
    "CONGE_J": "art. L.233-4",
    "H_SUP_PCT": "art. L.211-27",
    "H_SUP_REPOS": "art. L.211-27",
    "H_DIM_PCT": "art. L.231-7",
    # Relevé mot pour mot dans le XML : « le salarié rémunéré au mois touche pour
    # chaque heure travaillée son salaire horaire moyen majoré de cent pour cent ».
    # Le référentiel portait 300 % et citait L.232-5 : deux erreurs.
    "H_FER_PCT": "art. L.232-7, par. (2)",
    # Même article, phrase suivante : « le nombre forfaitaire de cent soixante-treize
    # heures ». Le diviseur mensuel est légal, pas conventionnel.
    "HEURS_MOIS": "art. L.232-7, par. (2)",
    # « Le travail de dimanche est rémunéré avec un supplément de cent pour cent »
    # pour les adolescents.
    "H_DIM_U18_PCT": "art. L.344-14",
    "CONGE_HANDICAP": "art. L.233-4",
    "REPOS_N_WE_1J": "art. L.231-4",
}

# Lignes de mise en page du classeur : un bandeau répété (« PARAMÈTRES SOCIAUX »
# en colonne A, ligne 10) et un marqueur booléen (ligne 9). Elles reprennent des
# valeurs présentes ailleurs et ne sont pas des paramètres. La ligne 9 portant
# « SSM », les écarter lève du même coup la collision avec le vrai SSM, ligne 15.
# La ligne 11 (`dt1er`) porte des dates, pas des montants : c'est la date d'effet
# de l'indice, déjà donnée par l'en-tête de chaque colonne.
LIGNES_DE_MISE_EN_PAGE = {9, 10, 11}

# Unités du bloc final, qui ne porte pas de titre de section. Déduire une unité
# d'un nom de clé marchait pour la moitié des cas et se trompait sur l'autre :
# `HS_3M` vaut 1,125 — un facteur, pas des jours.
UNITE_PAR_CLE = {
    "HEURS_MOIS": "h/mois", "VAL_PER_ESS_1_AN": "EUR à l'indice 100",
    "H_SUP_PCT": "taux", "H_DIM_PCT": "taux", "H_NUI_PCT": "taux",
    "H_FER_PCT": "taux", "H_DIM_U18_PCT": "taux", "H_CHOM": "taux",
    "H_SUP_REPOS": "ratio", "HS_3M": "ratio", "HS_4M": "ratio",
    "H_NUIT": "heure", "H_MATIN": "heure",
    "CONGE_J": "jours ouvrables", "CONGE_MIN": "jours ouvrables",
    "CONGE_HANDICAP": "jours ouvrables",
    "JOUR_H": "h", "JOUR_MAX_H": "h", "SEMAINE_H": "h", "SEMAINE_MAX": "h",
    "REPOS_MIN": "h", "REPOS_WE": "h", "REPOS_N_WE_1J": "h",
    "SUB_INT_1": "EUR", "SUB_INT_1A_2L": "EUR",
    "SUB_PRE_1": "EUR", "SUB_PRE_1A_2L": "EUR",
    "COTISATION_PROFESSIONNELLE": "EUR", "indice": "points",
    "CR_PAR": "EUR", "CR_MAX": "EUR", "CR_NB": "nombre",
}

# Unités déduites de la nature de la valeur, pour que `unite` ne soit pas vide.
def unite_de(cle: str, valeur) -> str | None:
    if cle in UNITE_PAR_CLE:
        return UNITE_PAR_CLE[cle]
    if isinstance(valeur, dt.time):
        return "heure"
    if re.match(r"^(ASS_|EMP_|MUT_)", cle):
        return "taux"
    return "EUR"


def lire_classeur(chemin: Path):
    """Rend (dates par colonne, lignes) sans rien interpréter."""
    import openpyxl

    wb = openpyxl.load_workbook(chemin, data_only=True)
    ws = wb[wb.sheetnames[0]]

    dates: dict[str, dt.date] = {}
    for cellule in ws[1]:
        if isinstance(cellule.value, dt.datetime):
            dates[cellule.column_letter] = cellule.value.date()

    lignes = []
    for ligne in ws.iter_rows(min_row=3):
        abrege = ligne[0].value
        description = ligne[1].value
        valeurs = {c.column_letter: c.value for c in ligne if c.column_letter in dates}
        # Colonne D : la formule, recopiée en texte par l'auteur du classeur.
        # Elle dit si la valeur se calcule ou si elle est posée.
        formule = next((c.value for c in ligne if c.column_letter == "D"), None)
        lignes.append((ligne[0].row, abrege, description, valeurs, formule))
    wb.close()
    return dates, lignes


def normaliser_cle(brut) -> str | None:
    """Nettoie un `Abrege`. Excel préfixe d'une apostrophe ce qu'il prendrait
    pour une formule : « 'IF » est la clé « IF »."""
    if brut is None:
        return None
    cle = str(brut).strip().lstrip("'")
    return cle or None


def collecter(dates, lignes, horizon: dt.date):
    """Les valeurs à charger, les collisions, et ce qui reste inexpliqué."""
    # Les colonnes retenues : datées, hors colonnes de travail, à l'horizon ou
    # avant. Triées du plus ancien au plus récent pour construire les périodes.
    colonnes = sorted(
        ((col, d) for col, d in dates.items()
         if col not in COLONNES_DE_TRAVAIL and d <= horizon),
        key=lambda cd: cd[1],
    )

    vues: dict[str, int] = {}
    collisions: dict[str, list[int]] = {}
    section = None
    entrees: list[dict] = []
    sans_valeur: list[str] = []
    sans_famille: list[str] = []
    derivees: list[str] = []

    for no_ligne, abrege, description, valeurs, formule in lignes:
        cle = normaliser_cle(abrege)
        libelle = str(description).strip() if description else None

        if cle is None:
            # Une ligne sans clé est un intitulé. Seuls ceux que l'on sait
            # rattacher à une famille changent la section courante : les autres
            # sont des sous-titres (« Minimum cotisable actifs… ») qui précisent
            # sans reclasser. Les confondre vidait la section de son sens.
            if libelle and libelle in FAMILLE_PAR_SECTION:
                section = libelle
            continue

        if no_ligne in LIGNES_DE_MISE_EN_PAGE:
            continue

        if cle in vues:
            collisions.setdefault(cle, [vues[cle]]).append(no_ligne)
            continue
        vues[cle] = no_ligne

        famille = FAMILLE_PAR_CLE.get(cle) or FAMILLE_PAR_SECTION.get(section or "")
        if famille is None:
            sans_famille.append(f"{cle} (ligne {no_ligne}, section « {section} »)")
            continue

        # Une période par valeur distincte : deux dates consécutives portant la
        # même valeur ne font qu'une seule ligne en base.
        # Une période par colonne datée où la cellule porte une valeur. Deux
        # colonnes consécutives de même valeur fusionnent. Une cellule vide
        # ferme la série : ni zéro, ni report de la dernière valeur connue.
        # Le classeur laisse le SSM vide là où il se calcule de `ssm_100` et de
        # l'indice ; reconduire 2 570,93 € de 2023 jusqu'en 2037 aurait donné un
        # salaire minimum faux, et personne ne l'aurait vu passer.
        # Le classeur laisse une cellule vide pour deux raisons opposées, et il
        # faut les distinguer sous peine de choisir entre inventer un montant et
        # perdre une constante :
        #
        #   * la valeur se **calcule** — le SSM se dérive de `ssm_100` et de
        #     l'indice, et n'est recopié dans aucune colonne historique ;
        #   * la valeur n'a **pas changé** — 48 h reste 48 h, et l'auteur ne
        #     réinscrit que ce qui bouge.
        #
        # La colonne D tranche : elle porte la formule quand il y en a une, et
        # « #N/A » sinon. Une valeur calculée s'arrête à son dernier relevé ;
        # une constante se reconduit.
        calculee = isinstance(formule, str) and formule.strip().startswith("=")

        # Parcours des colonnes, de la plus ancienne à la plus récente.
        #
        #   constante  : une cellule vide vaut « inchangé » — la période court.
        #                Couper dessus trouait le référentiel : SEMAINE_MAX
        #                perdait [2022-01-01, 2022-04-01) alors que 48 h n'a
        #                jamais bougé, et `fn_param_num` aurait rendu NULL.
        #   calculée   : une cellule vide ferme la série. Le classeur ne recopie
        #                pas ce qu'il dérive, et reconduire 2 570,93 € de 2023
        #                jusqu'en 2037 aurait donné un SSM faux.
        periodes: list[list] = []
        courant = None
        for col, d in colonnes:
            v = valeurs.get(col)
            if isinstance(v, str) and not v.strip():
                v = None
            if isinstance(v, dt.datetime):
                v = v.time() if v.date() == dt.date(1900, 1, 1) else v.date()

            if v is None:
                if calculee and periodes and periodes[-1][2] is None:
                    periodes[-1][2] = d        # la valeur cesse d'être attestée
                    courant = None
                continue

            if v != courant:
                if periodes and periodes[-1][2] is None:
                    periodes[-1][2] = d
                periodes.append([d, v, None])
                courant = v

        if not periodes:
            sans_valeur.append(f"{cle} (ligne {no_ligne})")
            continue

        # Un relevé unique sur toute l'étendue du classeur signale une valeur qui
        # n'a pas varié. Sa borne basse recule à la sentinelle : la première
        # colonne du classeur est une date de relevé, pas une entrée en vigueur,
        # et laisser 2020 rendait NULL pour les 57 contrats antérieurs.
        # Une clé à plusieurs périodes évolue — reculer sa borne affirmerait que
        # le SSM de 2020 valait déjà celui de 1970.
        if len(periodes) == 1 and periodes[0][0] == colonnes[0][1]:
            periodes[0][0] = SENTINELLE_DEBUT

        if periodes[-1][2] is None:
            periodes[-1][2] = SENTINELLE_FIN
        else:
            derivees.append(f"{cle} (ligne {no_ligne}) — dernier relevé au "
                            f"{periodes[-1][0]}, formule « {str(formule).strip()} »")

        for debut, valeur, fin in periodes:
            entrees.append({
                "cle": cle,
                "famille": famille,
                "libelle": libelle or cle,
                "valeur": valeur,
                "unite": unite_de(cle, valeur),
                "reference": REFERENCE_PAR_CLE.get(cle),
                "debut": debut,
                "fin": fin,
                "ligne": no_ligne,
            })

    return entrees, collisions, sans_valeur, sans_famille, derivees, colonnes


def litteral(v) -> str:
    if isinstance(v, dt.time):
        return f"'{v.strftime('%H:%M')}'"
    if isinstance(v, bool):
        return "1" if v else "0"
    if isinstance(v, (int, float)):
        return repr(round(float(v), 6))
    return "null"


def echapper(t: str) -> str:
    return t.replace("'", "''")


def sql(entrees, horizon: dt.date) -> str:
    """La migration : un bloc de définitions, un bloc de valeurs datées.

    Séparer les deux évite de réécrire la famille, le libellé, l'unité et la
    référence légale à chaque période — certaines clés en ont huit, et certains
    libellés font quatre-vingts caractères.
    """
    import json

    definitions: dict[str, list] = {}
    for e in entrees:
        definitions.setdefault(e["cle"], [e["famille"], e["libelle"],
                                          e["unite"], e["reference"]])

    valeurs = []
    for e in entrees:
        v = e["valeur"]
        if isinstance(v, dt.time):
            v = round(v.hour + v.minute / 60, 6)
        elif isinstance(v, bool):
            v = 1 if v else 0
        elif isinstance(v, (int, float)):
            v = round(float(v), 6)
        else:
            v = None
        valeurs.append([e["cle"], v, str(e["debut"]), str(e["fin"]), e["ligne"]])

    def bloc(objet) -> str:
        """Le JSON entre guillemets-dollar.

        « Participation patient au séjour à l'hôpital » : une apostrophe dans un
        libellé referme un littéral SQL ordinaire, et la migration échoue sur le
        mot suivant. Le guillemet-dollar supprime la question — aucun
        échappement, donc aucun échappement oublié.
        """
        texte = json.dumps(objet, ensure_ascii=False, separators=(",", ":"))
        assert "$json$" not in texte, "le délimiteur apparaît dans les données"
        return f"$json${texte}$json$"

    return f"""-- 91 — Les paramètres sociaux du classeur, clés `Abrege`
--
-- Source : `lois_et_règlements/paramètres.xlsx`.
--
-- Généré par `tools/charger_parametres.py`. Ne pas modifier à la main : la
-- source est le classeur, et une correction faite ici serait perdue au
-- prochain chargement.
--
-- La clé est la colonne `Abrege` du classeur, telle quelle. C'est elle que les
-- routines de calcul citent, conformément au cahier des charges.
--
-- Horizon : {horizon}. Le classeur porte déjà les colonnes 2025-05-01 et
-- 2026-06-01 ; elles ne sont volontairement pas chargées, le socle de calcul et
-- les tests étant arrêtés à cette date.
--
-- Deux blocs plutôt qu'une longue liste de tuples : les définitions (famille,
-- libellé, unité, référence légale) d'un côté, les valeurs datées de l'autre.
-- Une clé peut porter huit périodes ; réécrire son libellé huit fois n'apporte
-- rien et cache l'essentiel.
--
-- Ce qui n'est **pas** chargé, et pourquoi :
--
--   * les valeurs que le classeur **dérive** (le SSM se calcule de `ssm_100` et
--     de l'indice) s'arrêtent à leur dernier relevé explicite. Reconduire
--     2 570,93 € de septembre 2023 jusqu'en 2037 aurait donné un salaire minimum
--     faux que rien n'aurait signalé ;
--   * `REVISE` désigne deux montants différents dans le classeur, lignes 92 et
--     101. Un identifiant pour deux grandeurs : la clé est refusée ;
--   * les taux d'accident `ASS_ACC_TAUX_*` n'existent que dans les colonnes de
--     travail, jamais dans l'historique. Ils restent absents et signalés.

-- Rechargement idempotent : on retire le lot avant de le réécrire. Un
-- `on conflict` ne conviendrait pas, la clé d'unicité portant aussi sur la
-- période de validité.
delete from parametres_legaux where source = 'paramètres.xlsx';

with definitions(cle, famille, libelle, unite, reference) as (
  select d.key,
         (d.value->>0)::famille_parametre,
         d.value->>1, d.value->>2, d.value->>3
  from jsonb_each({bloc(definitions)}::jsonb) as d
),
valeurs(cle, valeur, debut, fin, ligne) as (
  select v->>0, (v->>1)::numeric, (v->>2)::date, (v->>3)::date, (v->>4)::int
  from jsonb_array_elements({bloc(valeurs)}::jsonb) as v
)
insert into parametres_legaux
  (famille, cle_parametre, libelle, valeur_num, unite,
   debut_validite, fin_validite, source, reference_legale, note)
select d.famille, d.cle, d.libelle, v.valeur, d.unite,
       v.debut, v.fin, 'paramètres.xlsx', d.reference,
       'ligne ' || v.ligne || ' du classeur'
from valeurs v
join definitions d using (cle);
"""


def main() -> int:
    p = argparse.ArgumentParser(description="Charge le classeur des paramètres.")
    p.add_argument("--ecrire", action="store_true", help="écrit le fichier de migration")
    p.add_argument("--horizon", default=str(HORIZON), help="date de chargement maximale")
    args = p.parse_args()
    horizon = dt.date.fromisoformat(args.horizon)

    if not CLASSEUR.exists():
        print(f"ARRÊT — {CLASSEUR} est introuvable.")
        return 1

    dates, lignes = lire_classeur(CLASSEUR)
    (entrees, collisions, sans_valeur, sans_famille,
     derivees, colonnes) = collecter(dates, lignes, horizon)

    print("=" * 74)
    print("CHARGEMENT DES PARAMÈTRES SOCIAUX")
    print("=" * 74)

    print(f"\nColonnes datées retenues (horizon {horizon}) :")
    for col, d in colonnes:
        print(f"  {col} : {d}")
    ecartees = sorted(d for col, d in dates.items()
                      if col not in COLONNES_DE_TRAVAIL and d > horizon)
    if ecartees:
        print(f"\nÉcartées, au-delà de l'horizon : {', '.join(str(d) for d in ecartees)}")

    cles = {e["cle"] for e in entrees}
    print(f"\n{len(cles)} clés, {len(entrees)} périodes de validité.")

    par_famille: dict[str, set] = {}
    for e in entrees:
        par_famille.setdefault(e["famille"], set()).add(e["cle"])
    print("\n--- Par famille ---")
    for f in sorted(par_famille):
        print(f"  {f:16} {len(par_famille[f]):3} clés")

    if collisions:
        print(f"\n--- REFUSÉES : `Abrege` en double ({len(collisions)}) ---")
        print("  Un même identifiant pour deux grandeurs. Charger l'un des deux")
        print("  au hasard donnerait un calcul faux et silencieux.")
        for cle, ls in collisions.items():
            print(f"  {cle} : lignes {', '.join(map(str, ls))}")

    if sans_famille:
        print(f"\n--- Sans famille ({len(sans_famille)}) ---")
        for s in sans_famille:
            print(f"  {s}")

    if sans_valeur:
        print(f"\n--- Sans aucune valeur à l'horizon ({len(sans_valeur)}) ---")
        for s in sans_valeur:
            print(f"  {s}")

    if derivees:
        print(f"\n--- Sans valeur à l'horizon : dérivées dans le classeur "
              f"({len(derivees)}) ---")
        print("  Le classeur ne les recopie pas dans les colonnes historiques parce")
        print("  qu'elles se calculent. Elles ne sont donc pas chargées au-delà de leur")
        print("  dernier relevé : c'est au moteur de les dériver, pas au chargeur de")
        print("  reconduire une valeur périmée.")
        for d in derivees:
            print(f"  {d}")

    if not args.ecrire:
        print("\nConstat seul. Pour écrire la migration :  --ecrire")
        return 0

    horodatage = dt.datetime.now().strftime("%Y%m%d%H%M%S")
    cible = MIGRATIONS / f"{horodatage}_parametres_du_classeur.sql"
    cible.write_text(sql(entrees, horizon), encoding="utf-8")
    print(f"\nÉcrit : {cible.relative_to(RACINE)}  ({len(entrees)} lignes)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
