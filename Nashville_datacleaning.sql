SELECT *
FROM
	nashville_housing
ORDER BY
	uniqueid ASC
limit 10;

ALTER TABLE nashville_housing
ALTER COLUMN uniqueid SET DATA TYPE INTEGER USING Uniqueid ::INTEGER;

ALTER TABLE nashville_housing
ALTER COLUMN Saledate SET DATA TYPE DATE USING SaleDate::DATE;

ALTER TABLE nashville_housing
ALTER COLUMN Parcelid SET DATA TYPE VARCHAR(255);

ALTER TABLE nashville_housing
ALTER COLUMN landvalue SET DATA TYPE FLOAT USING landvalue::FLOAT;

ALTER TABLE nashville_housing
ALTER COLUMN totalvalue SET DATA TYPE FLOAT USING totalvalue::FLOAT,
ALTER COLUMN buildingvalue SET DATA TYPE FLOAT USING buildingvalue::FLOAT;


ALTER TABLE nashville_housing
ALTER COLUMN bedrooms SET DATA TYPE FLOAT USING bedrooms ::FLOAT,
ALTER COLUMN fullbath SET DATA TYPE FLOAT USING fullbath ::FLOAT,
ALTER COLUMN halfbath SET DATA TYPE FLOAT USING halfbath ::FLOAT;

---Filling up the property address where it is null by finding the address using parcelid.
SELECT a.parcelid,a.propertyaddress,b.propertyaddress
FROM nashville_housing a
JOIN nashville_housing b
	ON a.parcelid = b.parcelid
	AND a.uniqueid <> b.uniqueid
WHERE a.propertyaddress IS NULL;


----Updating the table with addresses.
UPDATE nashville_housing
SET propertyaddress = b.propertyaddress
FROM nashville_housing a
JOIN nashville_housing b
	ON a.parcelid = b.parcelid
	AND a.uniqueid <> b.uniqueid
WHERE a.propertyaddress IS NULL;

---Checking if everything is updated.
SELECT *
FROM
	nashville_housing
WHERE
	propertyaddress IS NULL;

----Seperating the address.


ALTER TABLE nashville_housing
ALTER COLUMN propertyaddress SET DATA TYPE VARCHAR(255);

ALTER TABLE nashville_housing
ADD COLUMN StreetAddress VARCHAR(255),
ADD COLUMN Suburb VARCHAR(255);

UPDATE nashville_housing
SET 
    StreetAddress = split_part(propertyaddress, ',', 1),
    Suburb = trim(split_part(propertyaddress, ',', 2));

ALTER TABLE nashville_housing
DROP COLUMN propertyaddress;
	
----splitting owners address
ALTER TABLE nashville_housing
ALTER COLUMN owneraddress SET DATA TYPE VARCHAR(255);

ALTER TABLE nashville_housing
ADD COLUMN O_StreetAddress VARCHAR(255),
ADD COLUMN O_Suburb VARCHAR(255),
ADD COLUMN O_State VARCHAR(255);

UPDATE nashville_housing
SET 
    O_StreetAddress = split_part(owneraddress, ',', 1),
    O_Suburb = split_part(owneraddress, ',', 2),
	O_State = trim(split_part(owneraddress, ',', 3));

ALTER TABLE nashville_housing
DROP COLUMN owneraddress;


----Changing Y to yes and N to no for soldasvacant column.
SELECT DISTINCT soldasvacant,
	COUNT(soldasvacant)
FROM nashville_housing
GROUP BY
	soldasvacant
ORDER BY 2;

SELECT
	CASE
		WHEN soldasvacant = 'Y' THEN 'Yes'
		WHEN soldasvacant = 'N' THEN 'No'
		ELSE soldasvacant
	END
FROM nashville_housing;

UPDATE nashville_housing
SET soldasvacant = CASE
		WHEN soldasvacant = 'Y' THEN 'Yes'
		WHEN soldasvacant = 'N' THEN 'No'
		ELSE soldasvacant
	END






