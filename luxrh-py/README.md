# LuxRH — application Streamlit

Application Python parallèle au front React. **Mêmes écrans, même moteur de règles** : le serveur
PostgreSQL calcule, valide et décide ; cette interface affiche et saisit. Aucune règle légale n'est
évaluée en Python, pas plus qu'elle ne l'est en TypeScript.

---

## Démarrer

```bash
.venv\Scripts\python -m streamlit run app.py
```

L'application écoute sur http://localhost:8501.

### Environnement

Un environnement virtuel est déjà en place dans `.venv`, adossé aux paquets système
(`--system-site-packages`) : Streamlit, pandas et plotly étaient déjà installés et validés
globalement, seul le client `supabase` a été ajouté dans le venv. **L'environnement Python global,
qui héberge votre installation Airflow, n'a pas été modifié.**

Pour repartir d'un environnement propre ailleurs :

```bash
python -m venv .venv
.venv\Scripts\python -m pip install -r requirements.txt
```

### Configuration

`luxrh/client.py` lit, dans l'ordre :

1. les variables d'environnement `VITE_SUPABASE_URL` et `VITE_SUPABASE_ANON_KEY` ;
2. `luxrh-py/.env` ;
3. `luxrh/.env.local` — le fichier de l'application React.

Rien à configurer si le front React est déjà paramétré.

---

## Écrans

| Groupe | Écrans |
|---|---|
| Pilotage | Tableau de bord · Centre de vigilance · Simulateur de licenciement collectif |
| Exploitation | Planning · Heures supplémentaires · Congés · Maladies · Chèques-repas |
| Dossiers | Employés · Fiche salarié · Contrats · Primes |
| Administration | Sociétés · Fiche société · Référentiel légal |

Chaque écran appelle les mêmes fonctions PostgreSQL que le front React : `fn_compliance_scan`,
`fn_validate_schedule`, `fn_contract_compliance`, `fn_premium_caps`, `fn_company_rates`…

---

## Structure

```
app.py                    connexion, barre latérale, routage
luxrh/client.py           session Supabase, appels au moteur, cache
luxrh/design.py           Design System LuxRH : jetons, badges, bloc « base légale »
luxrh/views_core.py       tableau de bord, sociétés, employés
luxrh/views_time.py       planning, congés, maladies, heures sup., chèques-repas
luxrh/views_compliance.py contrats, vigilance, licenciement collectif, primes, référentiel
.streamlit/config.toml    palette LuxRH (turquoise d'action, fond gris de travail)
```

---

## Ce que l'interface impose

- **Aucune erreur silencieuse.** Toute exception remonte à l'écran avec son message.
- **Date de référence explicite** dans la barre latérale : tout calcul lit les paramètres en vigueur
  à cette date, jamais les actuels.
- **Le refus des attentions de la société**, sur la fiche enfant, désactive les champs d'identité et
  la base efface ce qui aurait été saisi : seule la date de naissance subsiste, pour établir les
  droits à congé.
- **Les heures supplémentaires** ne sont acquises qu'après validation des RH *et* acceptation du
  salarié — la validation RH seule laisse la demande en attente.
- **Le référentiel affiche sa propre couverture** : combien de paramètres remontent à 2019, combien
  restent à charger, et quels écarts existent entre une valeur publiée et sa dérivation.
