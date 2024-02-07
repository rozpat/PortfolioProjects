/*

Cleaning Data in SQL Queries

*/

SELECT *
FROM PortfolioProject.dbo.Housing

------------------------------------------------------------------------------------------------------------
-- Standardise date format

SELECT SaleDate, CONVERT(DATE, SaleDate) AS SaleDateFormatted
FROM PortfolioProject.dbo.Housing

UPDATE PortfolioProject.dbo.Housing
SET SaleDate = CONVERT(DATE, SaleDate)

-- It did not update, thus:

-- add new column
ALTER TABLE PortfolioProject.dbo.Housing 
ADD SaleDateConverted DATE

UPDATE PortfolioProject.dbo.Housing
SET SaleDateConverted = CONVERT(DATE, SaleDate)

SELECT SaleDateConverted
FROM PortfolioProject.dbo.Housing

--------------------------------------------------------------------------------------------------------------------------
-- Populate Property Address data

SELECT *
FROM PortfolioProject.dbo.Housing
-- WHERE PropertyAddress IS NULL
ORDER BY ParcelID

-- There are cases where two ParcelID are same, but one of PropertyAddress values is null 
-- JOIN same tables together to then UPDATE the missing address

SELECT a.ParcelID AS ParcelID_1, a.PropertyAddress AS PropertyAddress_1
, b.ParcelID AS ParcelID_2, b.PropertyAddress AS PropertyAddress_2
, ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM PortfolioProject.dbo.Housing a
JOIN PortfolioProject.dbo.Housing b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ] -- not equal
WHERE a.PropertyAddress IS NULL 

UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM PortfolioProject.dbo.Housing a
JOIN PortfolioProject.dbo.Housing b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ] 
WHERE a.PropertyAddress IS NULL 


--------------------------------------------------------------------------------------------------------------------------

-- Breaking out Address into Individual Columns (Address, City, State)

SELECT PropertyAddress
FROM PortfolioProject.dbo.Housing
WHERE PropertyAddress LIKE '%.%'

SELECT PropertyAddress
FROM PortfolioProject.dbo.Housing
WHERE PropertyAddress LIKE '%,%'

SELECT PropertyAddress
FROM PortfolioProject.dbo.Housing
WHERE PropertyAddress LIKE '%  %' -- double spaces

SELECT 
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)) AS Address 
, CHARINDEX(',', PropertyAddress) 
FROM PortfolioProject.dbo.Housing

SELECT 
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1) AS Address 
, SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress)) AS Address_City 
FROM PortfolioProject.dbo.Housing

-- Add columns
ALTER TABLE PortfolioProject.dbo.Housing
ADD PropertySplitAddress NVARCHAR(255);

UPDATE PortfolioProject.dbo.Housing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1 )


ALTER TABLE PortfolioProject.dbo.Housing
ADD PropertySplitCity NVARCHAR(255);

UPDATE PortfolioProject.dbo.Housing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1 , LEN(PropertyAddress))


-- Another way of doing it (PARSENAME method)
-- PARSNAME does things backbards

SELECT 
PARSENAME(REPLACE(OwnerAddress, ',', '.') , 3) AS Address
, PARSENAME(REPLACE(OwnerAddress, ',', '.') , 2) AS City
, PARSENAME(REPLACE(OwnerAddress, ',', '.') , 1) AS State
FROM PortfolioProject.dbo.Housing

-- Add columns

-- OwnerSplitAddress
ALTER TABLE PortfolioProject.dbo.Housing
ADD OwnerSplitAddress NVARCHAR(255);
-- OwnerSplitCity
ALTER TABLE PortfolioProject.dbo.Housing
ADD OwnerSplitCity NVARCHAR(255);
-- OwnerSplitState
ALTER TABLE PortfolioProject.dbo.Housing
ADD OwnerSplitState NVARCHAR(255);

UPDATE PortfolioProject.dbo.Housing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 3)
UPDATE PortfolioProject.dbo.Housing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 2)
UPDATE PortfolioProject.dbo.Housing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 1)


SELECT *
FROM PortfolioProject.dbo.Housing


--------------------------------------------------------------------------------------------------------------------------
-- Change Y and N to Yes and No in "Sold as Vacant" field

-- Check possible values for SoldAsVacant column and count how many times they occur
SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM PortfolioProject.dbo.Housing
GROUP BY SoldAsVacant
ORDER BY 2 DESC


SELECT SoldAsVacant
, CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
		WHEN SoldAsVacant = 'N' THEN 'No'
		ELSE SoldAsVacant
		END
FROM PortfolioProject.dbo.Housing


UPDATE PortfolioProject.dbo.Housing
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
		WHEN SoldAsVacant = 'N' THEN 'No'
		ELSE SoldAsVacant
		END

-----------------------------------------------------------------------------------------------------------------------------------------------------------
-- Remove Duplicates (Not standard practice)

WITH RowNumCTE AS(
SELECT *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				PropertyAddress,
				SalePrice,
				SaleDate,
				LegalReference 
				ORDER BY 
					UniqueID
					) row_num

FROM PortfolioProject.dbo.Housing
)

-- SELECT *
DELETE
FROM RowNumCTE
WHERE row_num > 1
-- ORDER BY PropertyAddress


---------------------------------------------------------------------------------------------------------
-- Delete Unused Columns

SELECT *
FROM PortfolioProject.dbo.Housing


ALTER TABLE PortfolioProject.dbo.Housing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress, SaleDate