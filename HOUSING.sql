/*
Cleaning Data project

*/

Select *
From PortfolioProject.dbo.housing


-- Standardize Data Format
Select SaleDate, CONVERT(Date,SaleDate)
From PortfolioProject.dbo.housing

ALTER TABLE PortfolioProject.dbo.housing
ADD SaleDateConverted Date;

UPDATE PortfolioProject.dbo.housing
SET SaleDateConverted = CONVERT(Date, SaleDate)

Select SaleDateConverted
From PortfolioProject.dbo.housing



-- (Populate Property Address Data) Check for null values 
Select PropertyAddress
From PortfolioProject.dbo.housing
Where PropertyAddress is null
-- result of 29 null values


-- (Populate Property Address Data) There are 35 cases of ParcelID with PropertyAddress null values. 
-- For each ParcelID with PropertyAddress null, we have another ParcelID with same ID and PropertyAddress filled
-- So we can fill the null values with PropertyAddress wich have the same ParcelID. Note that UniqueID is different, so it's not a duplicate.
-- Use JOIN to test it
Select a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
From PortfolioProject.dbo.housing a
JOIN PortfolioProject.dbo.housing b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID] <> b.[UniqueID]
Where a.PropertyAddress is null

-- Now we can UPADATE the table and fill null values
Update a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
From PortfolioProject.dbo.housing a
JOIN PortfolioProject.dbo.housing b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID] <> b.[UniqueID]
Where a.PropertyAddress is null


-- Breaking out Address into Individual Columns (Address, City, State)
Select PropertyAddress
From PortfolioProject.dbo.housing

-- Splitting test
Select SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1 ) as Address
, SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress)) as Address
From PortfolioProject.dbo.housing


-- ALTER TABLE and create 2 new columns with splitted address
ALTER TABLE PortfolioProject.dbo.housing
ADD PropertySplitAddress Nvarchar(255);

UPDATE PortfolioProject.dbo.housing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1 )

ALTER TABLE PortfolioProject.dbo.housing
ADD PropertySplitCity Nvarchar(255);

UPDATE PortfolioProject.dbo.housing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress))

-- Check new columns
Select *
From PortfolioProject.dbo.housing
-- Now we have PropertyAddress splitted in PropertySplitAddress, and PropertySplitCity



-- Let's do the same process for OwnerAddress
Select OwnerAddress
From PortfolioProject.dbo.housing

-- We used SUBSTRING before. This time we're gonna use PARSENAME.
-- PARSENAME works only with '.' so first we have to replace comma with period, and then it works perfectly.
Select
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)
,PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)
,PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)
From PortfolioProject.dbo.housing

-- Now we're gonna ALTER TABLE using this parameters
ALTER TABLE PortfolioProject.dbo.housing
ADD OwnerSplitAddress Nvarchar(255);

UPDATE PortfolioProject.dbo.housing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)

ALTER TABLE PortfolioProject.dbo.housing
ADD OwnerSplitCity Nvarchar(255);

UPDATE PortfolioProject.dbo.housing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)

ALTER TABLE PortfolioProject.dbo.housing
ADD OwnerSplitState Nvarchar(255);

UPDATE PortfolioProject.dbo.housing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)

-- Check new columns
Select *
From PortfolioProject.dbo.housing


-- Change Y and N to Yes and No in SoldAsVacant field because we have N, No, Y, Yes values.
-- Test changing values
Select SoldAsVacant
, CASE WHEN SoldAsVacant = 'Y' THEN 'YES'
	   WHEN SoldAsVacant = 'N' THEN 'NO'
	   ELSE SoldAsVacant
	   END
FROM PortfolioProject.dbo.housing

-- UPDATE VALUES
UPDATE PortfolioProject.dbo.housing
SET SoldAsVacant 
= CASE WHEN SoldAsVacant = 'Y' THEN 'YES'
	   WHEN SoldAsVacant = 'N' THEN 'NO'
	   ELSE SoldAsVacant
	   END

-- Check for changes
Select Distinct(SoldAsVacant), Count(SoldAsVacant)
From PortfolioProject.dbo.housing
Group By SoldAsVacant
Order By 2


--Check for Duplicates
WITH RowNumCTE AS(
Select *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
	             PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY
					UniqueID
					) row_num
From PortfolioProject.dbo.housing
)
Select*
From RowNumCTE
Where row_num > 1
Order By PropertyAddress


-- Delete Duplicates
WITH RowNumCTE AS(
Select *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
	             PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY
					UniqueID
					) row_num
From PortfolioProject.dbo.housing
)
DELETE
From RowNumCTE
Where row_num > 1
-- 104 duplicates removed 

-- Delete Unused Columns (since we splitted address in more separated columns, we can delete original columns and some other unused columns)
-- NOTE: this process is not necessary. This is not the original database so we can alter it without causing any problem. 

ALTER TABLE PortfolioProject.dbo.housing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress, SaleDate

Select *
FROM PortfolioProject.dbo.housing
