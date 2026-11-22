# Cahier des Charges Technique
## BotGold AI — Plateforme SaaS de Trading Automatisé XAUUSD

**Version** : 1.0  
**Date** : 21 novembre 2026  
**Statut** : Spécification fonctionnelle & technique  
**Objectif** : Reproduire fidèlement la logique anti-martingale contextuelle décrite dans la vidéo BotGold, sous forme de plateforme SaaS professionnelle.

---

## 1. Vision Produit

Créer une plateforme SaaS simple, moderne et transparente qui permet à un trader de :
- Visualiser en temps réel les décisions d’un bot anti-martingale
- Comprendre **pourquoi** le bot trade ou ne trade pas (explicabilité)
- Configurer son risque de manière claire et contrôlée
- Exécuter la stratégie sur MetaTrader 5 (via EA local) tout en ayant un dashboard cloud de monitoring

**Positionnement différenciant** :  
Contrairement aux robots martingale qui « doublent pour récupérer », ce produit vend explicitement le **droit de ne rien faire** et l’absence totale de logique de recovery.

---

## 2. Les 5 Règles Inviolables (Cœur Produit)

Ces règles doivent être **codées en dur** et impossibles à désactiver par l’utilisateur.

| Code | Règle | Description technique |
|------|-------|-----------------------|
| **R-01** | Aucun Martingale | La taille de position est calculée uniquement à partir de l’ATR live + risque % défini par l’utilisateur. Jamais en fonction de la perte précédente. |
| **R-02** | Aucun Grid / Averaging | Une seule position à la fois. Interdiction formelle de renforcer une position perdante ou de placer des ordres empilés. |
| **R-03** | Stop jamais élargi | Le stop-loss initial est placé à l’entrée. Il ne peut se déplacer que vers le break-even puis en trailing (sens protecteur uniquement). |
| **R-04** | Droit de ne rien faire | Si le score de contexte < seuil, aucun ordre n’est envoyé. Des journées à 0 trade sont un comportement normal et attendu. |
| **R-05** | Exécution locale | L’EA tourne exclusivement dans le MetaTrader 5 de l’utilisateur (PC ou VPS). Aucun identifiant de trading n’est jamais transmis au cloud. |

---

## 3. Architecture Globale

```
┌─────────────────────────────────────────────────────────────────┐
│                        FRONTEND (SaaS)                          │
│  Dashboard React / Next.js  •  Auth  •  Monitoring  •  Settings │
└────────────────────────────┬────────────────────────────────────┘
                             │ HTTPS / WebSocket
┌────────────────────────────▼────────────────────────────────────┐
│                     BACKEND API (Node.js / NestJS)              │
│  • Gestion utilisateurs & abonnements                           │
│  • Stockage décisions & métriques (lecture seule depuis EA)     │
│  • Notifications (email / push)                                 │
│  • Billing (Stripe + crypto)                                    │
└────────────────────────────┬────────────────────────────────────┘
                             │ (optionnel) Heartbeat / logs
┌────────────────────────────▼────────────────────────────────────┐
│                 META TRADER 5 (Chez l’utilisateur)              │
│  Expert Advisor BotGold.ex5                                     │
│  • Lecture multi-timeframe                                      │
│  • Calcul contexte + décision                                   │
│  • Exécution ordres                                             │
│  • Envoi logs anonymisés vers le cloud (si activé)              │
└─────────────────────────────────────────────────────────────────┘
```

**Principe de sécurité** : Le cloud ne peut **jamais** envoyer d’ordre. Il ne fait que recevoir des logs et afficher des données.

---

## 4. Fonctionnalités Détaillées

### 4.1 Dashboard Principal
- Capital, Equity, P&L jour / semaine / mois
- Nombre de trades vs nombre de skips (métrique clé)
- Prix XAUUSD live (via broker ou provider)
- Graphique de prix + marqueurs des décisions
- Journal des décisions avec raison textuelle

### 4.2 Moteur de Décision (côté EA)
1. Lecture simultanée : Prix + ATR + RSI + MACD + Bollinger + EMA + Fibonacci + 15 autres indicateurs
2. Timeframes : M5, M15, H1, H4 (le bot est attaché au M30)
3. Calcul d’un **score de contexte** (0-100)
4. Alignement multi-timeframe
5. Si score < seuil configurable → SKIP (R-04)
6. Sinon → calcul taille de lot (ATR-based) + placement ordre avec SL immédiat

### 4.3 Gestion du Risque
- Risque par trade configurable (0.25 % → 2 %)
- Calcul automatique du lot :  
  `Lot = (Capital × Risque%) / (Distance_SL_en_$ × Valeur_point)`
- Capital minimum recommandé : 1 000 $ (compte standard) ou 100 $ (cent)
- Affichage clair du risque monétaire max par trade

### 4.4 Journal & Explicabilité
Chaque décision (trade ou skip) doit contenir :
- Timestamp
- Action (BUY / SELL / SKIP)
- Raison textuelle lisible
- Valeurs des indicateurs clés
- Score de contexte
- Taille de lot et distance de stop (si trade)

### 4.5 Paramètres Utilisateur
- Risque % par trade
- Mode (Conservateur / Normal / Agressif) → ajuste uniquement les seuils de contexte
- Notifications (trade ouvert, trade fermé, skip important)
- Activation / désactivation de l’envoi de logs vers le cloud

---

## 5. Stack Technique Recommandée

| Couche | Technologie | Justification |
|--------|-------------|---------------|
| Frontend | Next.js 14 + TypeScript + Tailwind + shadcn/ui | Performance, SEO, composants modernes |
| Charts | TradingView Lightweight Charts ou Chart.js | Graphiques pro |
| Backend | NestJS (Node.js) | Structure solide, WebSocket natif |
| Base de données | PostgreSQL + Redis | Données relationnelles + cache |
| Auth | Clerk ou NextAuth + JWT | Sécurité rapide |
| Paiement | Stripe + Crypto (USDT ERC-20) | Comme dans la vidéo originale |
| EA | MQL5 | Standard industrie MT5 |
| Hébergement | Vercel (front) + Railway/Render (API) | Simple et scalable |
| Monitoring | Sentry + LogRocket | Qualité |

---

## 6. Améliorations Professionnelles Ajoutées

Par rapport à la vidéo originale, les améliorations suivantes sont intégrées :

1. **Score de contexte explicite** (0-100) visible dans le dashboard
2. **Ratio Skip / Trade** comme KPI principal (et non le rendement)
3. **Simulation complète** avant passage en réel
4. **Journal d’audit** de toutes les décisions (transparence totale)
5. **Mode « Paper Trading »** intégré dans le dashboard
6. **Alertes intelligentes** : « 5 skips consécutifs – marché difficile »
7. **Comparateur de risque** : visualisation de ce que donnerait un martingale vs cette stratégie
8. **Export CSV** des décisions pour analyse personnelle
9. **Multi-comptes** (futur) : un utilisateur peut monitorer plusieurs MT5
10. **Version mobile responsive** dès le premier jour

---

## 7. Modèle Économique (aligné vidéo)

| Offre | Prix | Caractéristiques |
|-------|------|------------------|
| Lifetime | 39 $ (lancement) | Accès à vie, mises à jour incluses |
| Mensuel | 12 $ | Annulable à tout moment |
| Trimestriel | 22 $ | ≈ 7,33 $/mois |

Garantie 30 jours satisfait ou remboursé (sous conditions d’utilisation correcte).

---

## 8. Roadmap de Développement

### Phase 1 — MVP (4-6 semaines)
- [x] Dashboard simulation (livré)
- [ ] EA MQL5 basique avec les 5 règles
- [ ] Authentification + abonnement Stripe
- [ ] Envoi des décisions EA → API

### Phase 2 — Production (6-8 semaines)
- [ ] Backtest intégré dans le dashboard
- [ ] Notifications push / email
- [ ] Mode paper trading complet
- [ ] Documentation utilisateur + vidéos

### Phase 3 — Scale
- [ ] Multi-stratégies (autres paires)
- [ ] API publique pour power users
- [ ] Version Prop Firm friendly (limites de drawdown)

---

## 9. Risques & Conformité

- **Disclaimer obligatoire** sur toutes les pages : le trading à effet de levier peut entraîner la perte totale du capital.
- Aucune promesse de rendement (comme dans la vidéo).
- L’EA ne demande jamais les mots de passe (R-05).
- Logs anonymisés uniquement (pas de données personnelles de trading).
- Respect RGPD / CCPA pour les données utilisateurs.

---

## 10. Livrables Actuels

| Fichier | Description |
|---------|-------------|
| `dashboard/index.html` | Prototype interactif complet du dashboard SaaS |
| `docs/CAHIER_DES_CHARGES.md` | Ce document |

---

**Prochaines étapes recommandées** :
1. Tester le dashboard de simulation
2. Valider les règles métier
3. Développer l’EA MQL5 correspondant
4. Mettre en place l’infrastructure cloud

---

*Document rédigé pour servir de base solide à un développement professionnel de la plateforme.*
