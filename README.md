# BotGold AI — SaaS Trading Platform (Prototype)

Plateforme SaaS professionnelle reproduisant la stratégie anti-martingale contextuelle présentée dans la vidéo BotGold (XAUUSD / MT5).

## Contenu du projet

```
botgold-saas/
├── dashboard/
│   └── index.html          ← Dashboard interactif complet (ouvrir dans un navigateur)
├── docs/
│   └── CAHIER_DES_CHARGES.md  ← Spécifications techniques détaillées
└── README.md
```

## Comment tester le Dashboard

1. Ouvrez le fichier `dashboard/index.html` dans un navigateur moderne (Chrome, Firefox, Edge, Safari).
2. Cliquez sur **« Lancer Analyse »** pour simuler une décision du bot.
3. Ajustez le risque avec le slider.
4. Observez le journal des décisions (trades vs skips).

Le dashboard est entièrement autonome (pas besoin de serveur).

## Fonctionnalités du prototype

- Interface dark moderne type plateforme de trading
- Affichage des 5 règles inviolables
- Moteur de décision simulé (multi-timeframe + contexte)
- Calcul de taille de lot basé sur la volatilité (ATR)
- Journal des décisions avec raisons
- Graphique de prix animé
- Paramètres de risque configurables
- KPI : ratio Skip / Trade

## Prochaines étapes

Voir le cahier des charges pour la roadmap complète (EA MQL5, backend, billing, etc.).

---

**Disclaimer** : Ceci est un prototype éducatif et de démonstration. Aucun ordre réel n’est exécuté. Le trading comporte un risque de perte en capital.
