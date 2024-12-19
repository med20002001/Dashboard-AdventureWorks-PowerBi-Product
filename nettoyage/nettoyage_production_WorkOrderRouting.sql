 /*** nettoyage de WorkOrderRouting ***/

-- Vérifier la structure de la table
-- Vérification des contraintes associées aux colonnes avant suppression

SELECT name
FROM sys.default_constraints
WHERE parent_object_id = OBJECT_ID('Production.WorkOrderRouting')
AND parent_column_id = (
    SELECT column_id
    FROM sys.columns
    WHERE name = 'ModifiedDate'
    AND object_id = OBJECT_ID('Production.WorkOrderRouting')
);
ALTER TABLE Production.WorkOrderRouting
DROP CONSTRAINT DF_WorkOrderRouting_ModifiedDate;

-- Suppression des colonnes inutiles
ALTER TABLE Production.WorkOrderRouting
DROP COLUMN ModifiedDate;

-- Vérification des données manquantes ou incorrectes
-- Vérification des NULL ou des données invalides dans les colonnes clés
SELECT *
FROM Production.WorkOrderRouting
WHERE WorkOrderID IS NULL
   OR ProductID IS NULL
   OR OperationSequence IS NULL
   OR ActualResourceHrs IS NULL OR ActualResourceHrs <= 0  -- Vérifie que les heures réelles ne sont pas négatives ou nulles
   OR LocationID IS NULL;

-- Vérification des doublons
-- Rechercher les doublons potentiels basés sur les colonnes clés
SELECT WorkOrderID, ProductID, LocationID, COUNT(*) AS DuplicateCount
FROM Production.WorkOrderRouting
GROUP BY WorkOrderID, ProductID, LocationID
HAVING COUNT(*) > 1;

-- Suppression des doublons (en conservant une seule occurrence)
WITH CTE AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY WorkOrderID, ProductID, LocationID ORDER BY ActualStartDate) AS RowNum
    FROM Production.WorkOrderRouting
)
DELETE FROM CTE
WHERE RowNum > 1;

-- Vérifier l'intégrité des relations
SELECT wr.WorkOrderID
FROM Production.WorkOrderRouting wr
LEFT JOIN Production.WorkOrder wo
    ON wr.WorkOrderID = wo.WorkOrderID
WHERE wo.WorkOrderID IS NULL;

-- Supprimer les enregistrements sans correspondance dans la table `Production.WorkOrder`
DELETE FROM Production.WorkOrderRouting
WHERE WorkOrderID NOT IN (SELECT WorkOrderID FROM Production.WorkOrder);

-- Revalidation finale
SELECT * 
FROM Production.WorkOrderRouting;
