-- 1. Vérifier et supprimer les doublons potentiels
WITH DuplicateCheck AS (
    SELECT 
        ScrapReasonID,
        Name,
        ROW_NUMBER() OVER (PARTITION BY Name ORDER BY ScrapReasonID) as RowNum
    FROM Production.ScrapReason
)
DELETE FROM DuplicateCheck WHERE RowNum > 1;

-- 2. Nettoyer les valeurs nulles et les espaces inutiles
UPDATE Production.ScrapReason
SET 
    Name = TRIM(REPLACE(REPLACE(Name, CHAR(9), ' '), CHAR(160), ' '))
WHERE 
    ScrapReasonID IN (
        SELECT ScrapReasonID 
        FROM Production.ScrapReason 
        WHERE Name IS NOT NULL
    );

-- 3. Normaliser la casse des raisons de mise au rebut
UPDATE Production.ScrapReason
SET 
    Name = UPPER(LEFT(Name, 1)) + LOWER(SUBSTRING(Name, 2, LEN(Name)))
WHERE 
    Name IS NOT NULL;

-- 4. Créer une table nettoyée avec les informations essentielles
SELECT 
    ScrapReasonID,
    Name AS ScrapReasonName
INTO Production.ScrapReason_Clean
FROM 
    Production.ScrapReason
WHERE 
    Name IS NOT NULL;

-- 5. Ajouter des contraintes à la nouvelle table
ALTER TABLE Production.ScrapReason_Clean
ADD CONSTRAINT PK_ScrapReason_Clean PRIMARY KEY (ScrapReasonID);

ALTER TABLE Production.ScrapReason_Clean
ADD CONSTRAINT CHK_ScrapReasonName CHECK (LEN(ScrapReasonName) > 0);

-- 6. Ajouter un index pour améliorer les performances des recherches
CREATE INDEX IX_ScrapReason_Clean_Name 
ON Production.ScrapReason_Clean(ScrapReasonName);