-- Active: 1712073882487@@127.0.0.1@5433@data_centric@public

-- Suppression des FK suite à un oubli de ma part concernant le SERIAL
ALTER TABLE "Transactions" DROP COLUMN id_bien;

-- Pour la table Biens
ALTER TABLE "Biens"
ADD COLUMN id_bien SERIAL PRIMARY KEY

-- Pour la table Departement
ALTER TABLE "Département"
ADD COLUMN id_departement SERIAL PRIMARY KEY,
ADD COLUMN id_localisation INT,
ADD FOREIGN KEY (id_localisation) REFERENCES "Localisation"(id_localisation);


ALTER TABLE "Département"
ADD COLUMN id_localisation SERIAL,
ADD FOREIGN KEY (id_localisation) REFERENCES "Localisation"(id_localisation);

-- Pour la table Localisation
ALTER TABLE "Localisation"
ADD COLUMN id_localisation SERIAL PRIMARY KEY,
ADD COLUMN id_bien INT,
ADD FOREIGN KEY (id_bien) REFERENCES "Biens"(id_bien);

ALTER TABLE "Localisation"
ADD COLUMN id_bien SERIAL,
ADD FOREIGN KEY (id_bien) REFERENCES "Biens"(id_bien);

-- Pour la table Lot
ALTER TABLE "Lot"
ADD COLUMN id_lot SERIAL PRIMARY KEY,
ADD COLUMN id_bien INT,
ADD FOREIGN KEY (id_bien) REFERENCES "Biens"(id_bien);

ALTER TABLE "Lot"
ADD COLUMN id_bien SERIAL,
ADD FOREIGN KEY (id_bien) REFERENCES "Biens"(id_bien);

-- Pour la table Transactions
ALTER TABLE "Transactions"
ADD COLUMN id_transactions SERIAL PRIMARY KEY,
ADD COLUMN id_bien INT,
ADD FOREIGN KEY (id_bien) REFERENCES "Biens"(id_bien);

ALTER TABLE "Transactions"
ADD COLUMN id_bien SERIAL,
ADD FOREIGN KEY (id_bien) REFERENCES "Biens"(id_bien);


-- 1/ Nombre d’appartements et Maisons vendus en 2020
SELECT "Biens"."Type local", COUNT(*) AS "Nombre de ventes"
FROM "Transactions"
JOIN "Biens" ON "Transactions"."id_bien" = "Biens"."id_bien"
WHERE "Biens"."Type local" IN ('Appartement', 'Maison') AND EXTRACT(YEAR FROM "Transactions"."Date mutation") = 2022
GROUP BY "Biens"."Type local";


-- 2/ Nombre de biens vendus par trimestre
SELECT EXTRACT(QUARTER FROM "Transactions"."Date mutation") AS "Trimestre", COUNT(*) AS "Nombre de biens vendus"
FROM "Transactions" JOIN "Biens" ON "Transactions"."id_bien" = "Biens"."id_bien"
GROUP BY "Trimestre"
ORDER BY "Trimestre";

-- 3/ Proportion des ventes de biens par trimestre
WITH "ventes_par_trimestre" AS (
  SELECT EXTRACT(QUARTER FROM "Transactions"."Date mutation") AS "trimestre", COUNT(*) AS "nb_ventes"
  FROM "Transactions"
  JOIN "Biens"  ON "Transactions"."id_bien" = "Biens"."id_bien"
  WHERE EXTRACT(YEAR FROM "Transactions"."Date mutation") = 2022
  GROUP BY "trimestre"
),
"total_ventes_par_trimestre" AS (
  SELECT SUM("nb_ventes") AS "total_ventes"
  FROM "ventes_par_trimestre"
)
SELECT "ventes_par_trimestre"."trimestre", "ventes_par_trimestre"."nb_ventes", ROUND(("ventes_par_trimestre"."nb_ventes"::NUMERIC / "total_ventes_par_trimestre"."total_ventes"), 2) AS "proportion"
FROM "ventes_par_trimestre", "total_ventes_par_trimestre"
ORDER BY "ventes_par_trimestre"."trimestre"

-- 4/ Proportion d’appartements vendus par nombre de pièces
WITH "appartements_vendus" AS (
  SELECT "Biens"."Nombre pieces principales", COUNT(*) AS "nb_appartements"
  FROM "Transactions"
  JOIN "Biens" ON "Transactions"."id_bien" = "Biens"."id_bien"
  WHERE "Biens"."Type local" = 'Appartement'
  GROUP BY "Biens"."Nombre pieces principales"
),
"total_appartements_vendus" AS (
  SELECT SUM("nb_appartements") AS "total"
  FROM "appartements_vendus"
)
SELECT "appartements_vendus"."Nombre pieces principales", "nb_appartements", "appartements_vendus"."nb_appartements"::NUMERIC / "total_appartements_vendus"."total" AS "proportion"
FROM "appartements_vendus", "total_appartements_vendus"
ORDER BY "appartements_vendus"."Nombre pieces principales";

-- 5/ Les 10 départements où il y a eu le plus de ventes immobilières
SELECT "Département"."Code departement", COUNT("Transactions"."id_transactions") AS "nombre_ventes"
FROM "Transactions"
JOIN "Biens" ON "Transactions"."id_bien" = "Biens"."id_bien"
  JOIN "Localisation" ON "Biens"."id_bien" = "Localisation"."id_bien"
    JOIN "Département" ON "Localisation"."id_localisation" = "Département"."id_localisation"
GROUP BY "Département"."Code departement"
ORDER BY "nombre_ventes" DESC
LIMIT 10;

-- 6/ Les 10 départements où il y en a eu le moins
SELECT "Département"."Code departement", COUNT("Transactions"."id_transactions") AS "nombre_ventes"
FROM "Transactions"
JOIN "Biens" ON "Transactions"."id_bien" = "Biens"."id_bien"
  JOIN "Localisation" ON "Biens"."id_bien" = "Localisation"."id_bien"
    JOIN "Département" ON "Localisation"."id_localisation" = "Département"."id_localisation"
GROUP BY "Département"."Code departement"
ORDER BY "nombre_ventes" ASC
LIMIT 10;

-- 7/ Prix moyen du mètre carré en IDF
SELECT AVG(CAST(REPLACE("Transactions"."Valeur fonciere", ',', '.') AS NUMERIC) / "Biens"."Surface reelle bati") AS "prix moyen"
FROM "Transactions"
JOIN "Biens" ON "Transactions"."id_bien" = "Biens"."id_bien"
  JOIN "Localisation" ON "Biens"."id_bien" = "Localisation"."id_bien"
    JOIN "Département" ON "Localisation"."id_localisation" = "Département"."id_localisation"
WHERE "Département"."Code departement" IN ('75', '92', '93', '94', '77', '78', '91', '95')
AND "Biens"."Surface reelle bati" > 0;

--8/ Liste des 10 appartements les plus chers avec le département et le nombre de mètres carrés
SELECT "Biens"."id_bien", "Département"."Code departement", "Biens"."Surface reelle bati" AS "m2", "Transactions"."Valeur fonciere" AS "prix"
FROM "Transactions"
JOIN "Biens" ON "Transactions"."id_bien" = "Biens"."id_bien"
  JOIN "Localisation" ON "Biens"."id_bien" = "Localisation"."id_bien"
    JOIN "Département" ON "Localisation"."id_localisation" = "Département"."id_localisation"
WHERE "Biens"."Type local" = 'Appartement'
AND "Transactions"."Valeur fonciere" IS NOT NULL
ORDER BY "Transactions"."Valeur fonciere" DESC
LIMIT 10;

-- 9/ Taux d’évolution du nombre de ventes entre le premier et le second trimestre de 2020
WITH ventes_par_trimestre AS (SELECT EXTRACT(QUARTER FROM "Transactions"."Date mutation") AS "trimestre", COUNT(*) AS "nb_ventes"
FROM "Transactions"
WHERE EXTRACT(YEAR FROM "Transactions"."Date mutation") = 2022
GROUP BY "trimestre"
)
SELECT (CAST(second_trimestre.nb_ventes AS NUMERIC) - CAST(first_trimestre.nb_ventes AS NUMERIC)) / NULLIF(CAST(first_trimestre.nb_ventes AS NUMERIC), 0) * 100 AS taux_evolution
FROM (SELECT nb_ventes FROM ventes_par_trimestre WHERE "trimestre" = 1) AS first_trimestre, (SELECT nb_ventes FROM ventes_par_trimestre WHERE "trimestre" = 2) AS second_trimestre;

-- 10/ Liste des communes où le nombre de ventes a augmenté d'au moins 20% entre le premier et le second trimestre de 2020
WITH ventes_par_trimestre_commune AS (
  SELECT
    EXTRACT(QUARTER FROM "Transactions"."Date mutation") AS trimestre,
    EXTRACT(YEAR FROM "Transactions"."Date mutation") AS annee,
    "Département"."Commune",
    COUNT(*) AS nb_ventes
  FROM
    "Transactions"
  JOIN "Biens" ON "Transactions"."id_bien" = "Biens"."id_bien"
    JOIN "Localisation" ON "Biens"."id_bien" = "Localisation"."id_bien"
      JOIN "Département" ON "Localisation"."id_localisation" = "Département"."id_localisation"
  WHERE
    EXTRACT(YEAR FROM "Transactions"."Date mutation") = 2022
  GROUP BY
    trimestre, annee, "Département"."Commune"
),
augmentation AS (
  SELECT
    t1."Commune",
    (t2.nb_ventes - t1.nb_ventes) / NULLIF(t1.nb_ventes, 0)::float * 100 AS pourcentage_augmentation
  FROM
    ventes_par_trimestre_commune t1
  JOIN ventes_par_trimestre_commune t2 ON t1."Commune" = t2."Commune" AND t1.annee = t2.annee
  WHERE
    t1.trimestre = 1
    AND t2.trimestre = 2
)
SELECT
  "Commune",
  pourcentage_augmentation
FROM
  augmentation
WHERE
  pourcentage_augmentation >= 20
ORDER BY
  pourcentage_augmentation DESC;
