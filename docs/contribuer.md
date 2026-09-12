# Contribuer

Ce document rassemble les conventions du dépôt et les pièges déjà rencontrés. Il s'adresse à toute
personne qui va écrire du code, une migration ou de la documentation ici. Les règles qui suivent ne
sont pas des préférences de style : chacune répond à un incident réel ou à un invariant du projet.

Le résumé exécutif tient dans `../CLAUDE.md`. Ce document en donne les raisons et les détails.

---

## 1. Ce dépôt est public

`github.com/lanfr144/TestClaudeCode`.

**Aucun identifiant, aucune clé, aucune référence de projet ne doit y être commité.** Les secrets
vivent dans `luxrh/.env.local`, ignoré par Git, et sont lus par les deux applications.

Conséquences pratiques :

- les suites de tests lisent les mots de passe depuis l'environnement et **refusent de démarrer**
  s'ils manquent ;
- les exemples de documentation utilisent des valeurs manifestement fictives — `<reference-du-projet>`,
  jamais une vraie ;
- aucun matricule national réel, dans le code comme dans la documentation.

---

## 2. Aucune valeur légale en dur

**La règle.** Aucun seuil, taux ou durée légale n'est écrit dans le code applicatif. Ni en
TypeScript, ni en Python. Tout vient de `parametres_legaux`, daté et sourcé.

**Pourquoi.** Une valeur écrite en dur est fausse dès qu'un paramètre change, et invisible depuis
l'autre application. Elle est un bug **même si elle est juste aujourd'hui**.

**Comment faire à la place.** Le serveur lit le référentiel et renvoie au front la valeur, le
message et la référence d'article. `luxrh/src/lib/engine.ts` ne contient que des types — c'est
délibéré, et cela doit le rester.

**Et si la valeur n'existe pas ?** Elle reste absente, signalée par `fn_referential_gaps`. Un
chiffre plausible mais faux est pire qu'un trou déclaré. Voir
[moteur-de-regles.md](moteur-de-regles.md).

---

## 3. Le serveur calcule, le front affiche

Une règle évaluée côté client serait fausse dès qu'un paramètre change, et invisible depuis l'autre
application. Toute logique de décision — un seuil franchi, une durée applicable, un refus de
publication — s'écrit en PL/pgSQL.

Corollaire : un changement d'architecture se trace dans **toute** la chaîne
`migration → fonction RPC → luxrh/src/lib/ → écran React → vue Streamlit`. Chaque maillon touché
doit être mis à jour, y compris la documentation associée.

---

## 4. Migrations : numérotées, jamais réécrites

Une migration appliquée **ne se modifie plus**. Une correction prend la forme d'une **nouvelle**
migration qui redéfinit la fonction ou altère la table.

C'est pour cela que `fn_validate_schedule` est définie en 06 puis redéfinie en 11, 13 et 38, et que
`fn_compliance_scan` l'est en 07, 35 et 36. L'historique des corrections est lisible dans l'ordre
des fichiers.

**Nom du fichier :** `<horodatage>_<numéro>_<sujet_en_anglais>.sql`. Le numéro suit celui de la
dernière migration. Il y en a 60 fichiers à ce jour, jusqu'au numéro 56 — certains numéros portent
plusieurs suffixes de lettre (`44a`, `44b`, `45b` à `45e`) quand une correction rapprochée n'a pas
mérité un nouveau numéro entier.

**Un en-tête en commentaire** explique ce que la migration apporte et, pour une correction, **ce qui
n'allait pas**. Les migrations 11, 14, 18, 22, 25, 31 et 36 sont de bons modèles : elles décrivent
le symptôme avant le remède.

### Trois pièges PostgreSQL rencontrés

**Une valeur d'énumération ne peut pas être utilisée dans la transaction qui l'ajoute.** Les
migrations 20 (`famille_parametre` → `ccss`) et 28 (`genre_contrat` → `seasonal`, `apprenticeship`,
`interim`) existent **uniquement** pour isoler l'ajout. C'est le cas d'une migration d'une seule
ligne qui est justifiée.

**Une politique RLS qui interroge une table dont la politique interroge la première provoque une
récursion infinie**, et PostgreSQL refuse alors toute lecture. La migration 18 le corrige en passant
par des fonctions `security definer` (`has_shift_in_schedule`, `schedule_is_published`), qui ne
déclenchent pas de nouvelle évaluation de politique.

**Un déclencheur Oracle de niveau ligne qui interroge sa propre table lève ORA-04091** (mutating
table). Le schéma portable génère donc, pour reproduire une contrainte d'exclusion, un déclencheur
**composé** : la section `after each row` collecte les identifiants écrits, la section
`after statement` les vérifie une fois la table sortie de son état mutant. Voir
[bases-de-donnees.md](bases-de-donnees.md).

### pgcrypto vit dans `extensions`

Il faut **qualifier les appels**. `btree_gist`, en revanche, vit dans `public` : il est requis par
les contraintes d'exclusion temporelles, et le déplacer imposerait de toutes les recréer. C'est une
advisory Supabase assumée, pas un oubli.

---

## 5. Requêtes, déclencheurs et index efficaces — et fidèles à un usage réel

Trois conventions posées à l'occasion de la migration 55, en corrigeant un anti-patron qui ne
vivait que dans le schéma portable généré (pas dans le moteur PostgreSQL lui-même — voir
[bases-de-donnees.md](bases-de-donnees.md)) :

- **`exists` plutôt que `count(*)` comme test d'existence.** Un `count(*)` compte tous les
  candidats avant de conclure qu'il y en a au moins un ; `exists` s'arrête au premier. La différence
  n'est pas cosmétique dès que la table grandit.
- **Un déclencheur ne vérifie que les lignes qu'une instruction vient d'écrire**, jamais la table
  entière. Un déclencheur qui reparcourt toutes les lignes pour valider celle qui vient de changer
  coûte le même prix à la centième écriture qu'à la millionième — et grandit avec la table, pas
  avec le trafic.
- **Un index posé doit servir une requête réelle, pas seulement paraître logique.** La migration 55
  pose un index fonctionnel `upper(nom)` (égalité, préfixe) **et** un index trigramme GIN
  (infixe), parce que `fn_employee_rows` cherche avec `ilike '%…%'` : le seul index fonctionnel
  aurait laissé cette requête sans index utile, tout en donnant l'illusion du contraire. Avant de
  poser un index, identifiez la requête qu'il doit servir et vérifiez par `explain` que c'est bien
  celui-là qui est choisi — pas un voisin qui lui ressemble. Voir « Où vivent les règles » dans
  [architecture.md](architecture.md).

Une quatrième convention, propre au domaine du contrat : **une modification d'un élément essentiel
d'un contrat en cours passe par `fn_amend_contract`**, jamais par un `update` direct sur `contrats`.
C'est la fonction qui clôt l'ancien contrat, en crée un nouveau en reprenant toutes ses clauses par
`to_jsonb`, et journalise le motif — un `update` direct contournerait ce cheminement sans que rien,
au niveau du schéma, ne le signale. Voir [moteur-de-regles.md](moteur-de-regles.md).

---

## 6. RLS sur toutes les tables

L'isolation entre organisations est imposée **en base, jamais dans l'interface**. Une nouvelle table
portant des données de société ou de salarié doit :

1. porter `societe_id` (et `salarie_id` le cas échéant) — la dénormalisation est volontaire, elle
   permet à la politique de trancher sans jointure ;
2. activer RLS dans la même migration ;
3. recevoir ses politiques de lecture et d'écriture ;
4. être couverte par `tests/rls.test.mjs` si elle porte des données personnelles.

Une fonction du moteur qui touche une nouvelle table doit vérifier `has_company_access` ou
`can_manage_company` **avant** de calculer.

---

## 7. Aucune erreur silencieuse

Un calcul qui ne peut pas aboutir le dit et explique pourquoi. Pas de valeur par défaut qui masque
une donnée manquante, pas d'exception avalée.

En pratique :

- côté SQL, `raise exception` avec un message qui **nomme** ce qui manque ;
- côté React, `callEngine()` transforme toute erreur en exception ; ne l'attrapez pas pour afficher
  un état vide ;
- côté Python, `app.py` enveloppe chaque vue dans un `try/except` qui affiche l'exception. Ne
  rattrapez pas plus haut sans afficher.

Le contre-modèle à éviter est le `catch` qui retourne `0`, `[]` ou une valeur « raisonnable ».

---

## 8. Français

Commentaires, messages d'erreur, libellés d'interface et documentation sont en français. Les noms
de tables, de colonnes, de fonctions et de fichiers de migration restent en anglais, comme le reste
du schéma.

Ton neutre, tutoiement proscrit.

---

## 9. Écriture de fichiers

**Passer par l'outil d'écriture de fichiers ou par un script Python.** Les heredocs Bash mangent
les antislashs et échouent sur les gros contenus — c'est particulièrement destructeur sur une
migration SQL, où un `\\` perdu change le sens d'une expression régulière.

---

## 10. Pièges `supabase-js`

**L'inférence sature au-delà de deux niveaux de jointure** et retombe silencieusement sur `never`.
Les requêtes de détail portent donc un type de ligne explicite :

```ts
unwrap<CompanyDetailRow>(await supabase.from('societes').select('…').eq('id', id).single())
```

`queries.ts` définit ces types en tête de fichier : `CompanyDetailRow`, `ContractDetailRow`,
`EmployeeDetailRow`, `CompanyListRow`, `EmployeeListRow`, `CompanyCbaLink`.

**`.select()` prend un littéral, jamais une concaténation.** Une chaîne construite dynamiquement
fait perdre le typage entier. Si une requête doit varier, écrivez deux appels.

**Un appel RPC passe par `callEngine()`**, jamais directement par `supabase.rpc()`, pour que la
gestion d'erreur soit uniforme. La seule exception actuelle est `fn_set_employee_sensitive` dans
`ContractWizard.tsx`, qui appelle `supabase.rpc()` directement — c'est une irrégularité, pas un
modèle.

---

## 11. L'environnement Python ne se modifie pas

Le `.venv` de `luxrh-py` est créé avec `--system-site-packages` : l'environnement Python global
héberge l'installation Airflow de l'utilisateur et **ne doit pas être modifié**.

Un paquet nécessaire s'installe **dans le `.venv`**. Avant d'installer un **programme** — et non un
paquet — demandez.

---

## 12. La documentation suit le code

Un changement de code entraîne la mise à jour de toute la documentation associée : `README.md`
racine, `luxrh/README.md`, `luxrh-py/README.md`, `docs/*.md`, et les commentaires en tête de fichier
concernés.

Trois règles s'y ajoutent :

- **rien d'inventé** : chaque affirmation se vérifie dans le dépôt. Comptez les fichiers, lisez les
  migrations, ouvrez les tests. Un point incertain s'écrit comme incertain ;
- **liens entre documents** : chaque page renvoie à ses voisines par des liens relatifs, et
  [index.md](index.md) reste le sommaire de toutes. Pas de page orpheline ;
- **tableaux pour les inventaires**, prose pour les explications de principe.

Le fichier `../PRD_LuxRH.md` est le cahier des charges d'**origine**. Là où il diverge du code, le
code fait foi. Ne documentez pas une intention comme si elle était livrée.

---

## Avant de proposer un changement

- [ ] `cd luxrh && npm run build` — zéro erreur TypeScript
- [ ] `cd luxrh && npm test` — les six suites passent
- [ ] Aucune valeur légale nouvelle dans le code applicatif
- [ ] Toute nouvelle table a RLS et ses politiques, dans la même migration
- [ ] Toute nouvelle fonction du moteur vérifie l'accès de l'appelant avant de calculer
- [ ] Aucune migration existante n'a été modifiée
- [ ] La chaîne complète est à jour : migration → RPC → `lib/` → écran React → vue Streamlit
- [ ] La documentation associée est à jour, et ses chiffres recomptés
- [ ] Aucun secret, aucune référence de projet, aucun matricule réel

---

## Voir aussi

- [index.md](index.md) — sommaire de la documentation
- [ecarts-a-corriger.md](ecarts-a-corriger.md) — ce qui reste à corriger dans le dépôt, et ce
  qui l'a déjà été
- [architecture.md](architecture.md) — l'architecture que ces conventions protègent
- [tests-et-qualite.md](tests-et-qualite.md) — ce que les suites vérifient, et ce qu'elles ne
  vérifient pas
- [modele-de-donnees.md](modele-de-donnees.md) — où ajouter une table, et avec quelles colonnes
- [moteur-de-regles.md](moteur-de-regles.md) — comment ajouter un paramètre légal
