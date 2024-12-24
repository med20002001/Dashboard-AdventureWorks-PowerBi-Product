-- 1. Supprimer les doublons
WITH CTE AS (
    SELECT ProductID, 
           ROW_NUMBER() OVER (PARTITION BY ProductID ORDER BY ProductID) AS RowNum
    FROM Production.Product
)
DELETE FROM CTE
WHERE RowNum > 1;

-- 2. Supprimer la colonne 'Class' si elle existe
IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Product' AND COLUMN_NAME = 'Class')
BEGIN
    ALTER TABLE Production.Product
    DROP COLUMN Class;
END

-- 3. Supprimer la colonne 'Style' si elle existe
IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Product' AND COLUMN_NAME = 'Style')
BEGIN
    ALTER TABLE Production.Product
    DROP COLUMN Style;
END

-- 4. Supprimer la colonne 'ProductLine' si elle existe
IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Product' AND COLUMN_NAME = 'ProductLine')
BEGIN
    ALTER TABLE Production.Product
    DROP COLUMN ProductLine;
END

-- 5. Calculer la moyenne de la colonne 'Weight' en excluant les valeurs NULL,
-- en convertissant tout en KG (KG, LB, G)
DECLARE @AverageWeight DECIMAL(18, 2);  -- Déclaration de la variable @AverageWeight

SELECT @AverageWeight = AVG(
    CASE 
        WHEN WeightUnitMeasureCode = 'KG' THEN Weight
        WHEN WeightUnitMeasureCode = 'LB' THEN Weight * 0.453592  -- Conversion LB -> KG
        WHEN WeightUnitMeasureCode = 'G' THEN Weight / 1000  -- Conversion G -> KG
        ELSE NULL
    END)
FROM Production.Product
WHERE Weight IS NOT NULL;

-- Afficher la moyenne pour vérification (optionnel)
SELECT @AverageWeight AS AverageWeight;

-- 6. Mettre à jour les lignes où 'Weight' est NULL en remplaçant par la moyenne calculée
UPDATE Production.Product
SET Weight = @AverageWeight
WHERE Weight IS NULL;

-- 7. Remplacer les valeurs NULL dans d'autres colonnes par des valeurs par défaut (par exemple 'UNKNOWN' ou 0)
UPDATE Production.Product
SET 
    ProductNumber = ISNULL(ProductNumber, 'UNKNOWN'),
    Color = ISNULL(Color, 'UNKNOWN'),
    SafetyStockLevel = ISNULL(SafetyStockLevel, 0),
    ReorderPoint = ISNULL(ReorderPoint, 0),
    StandardCost = ISNULL(StandardCost, 0),
    ListPrice = ISNULL(ListPrice, 0),
    Size = ISNULL(Size, 'UNKNOWN'),
    SizeUnitMeasureCode = ISNULL(SizeUnitMeasureCode, 'UNKNOWN'),
    WeightUnitMeasureCode = ISNULL(WeightUnitMeasureCode, 'UNKNOWN'),
    Weight = ISNULL(Weight, @AverageWeight),
    DaysToManufacture = ISNULL(DaysToManufacture, 0),
    ProductSubcategoryID = ISNULL(ProductSubcategoryID, 1),  -- ID valide par défaut
    ProductModelID = ISNULL(ProductModelID, 1),  -- ID valide par défaut
    SellStartDate = ISNULL(SellStartDate, GETDATE()),
    SellEndDate = ISNULL(SellEndDate, '9999-12-31'),
    DiscontinuedDate = ISNULL(DiscontinuedDate, '9999-12-31'),
    rowguid = ISNULL(rowguid, NEWID()),
    ModifiedDate = ISNULL(ModifiedDate, GETDATE());

-- 8. Corriger les valeurs incorrectes et garantir la conformité avec les contraintes CHECK
UPDATE Production.Product
SET Weight = CASE 
                WHEN Weight < 0 THEN 0.1 
                ELSE Weight
             END
WHERE Weight < 0;

-- 9. Vérification des relations avec les clés étrangères
UPDATE Production.Product
SET ProductSubcategoryID = 1
WHERE ProductSubcategoryID NOT IN (SELECT ProductSubcategoryID FROM Production.ProductSubcategory);

UPDATE Production.Product
SET ProductModelID = 1
WHERE ProductModelID NOT IN (SELECT ProductModelID FROM Production.ProductModel);

-- 10. Vérification des clés étrangères invalides
SELECT p.ProductID, p.ProductSubcategoryID
FROM Production.Product p
WHERE p.ProductSubcategoryID NOT IN (SELECT ps.ProductSubcategoryID FROM Production.ProductSubcategory ps);

SELECT p.ProductID, p.ProductModelID
FROM Production.Product p
WHERE p.ProductModelID NOT IN (SELECT pm.ProductModelID FROM Production.ProductModel pm);

-- 11. Afficher toutes les colonnes de la table Product après traitement
SELECT * 
FROM Production.Product;

-- 12. Afficher un échantillon des 10 premières lignes de la table Product après traitement
SELECT TOP 10 * 
FROM Production.Product;
---suprimer class ProductLine et Style 
