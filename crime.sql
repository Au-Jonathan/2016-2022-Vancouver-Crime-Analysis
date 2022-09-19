#Create new table and Combine crimedata from 2016-2022
CREATE TABLE crime_all AS
SELECT * FROM crime2016
UNION
SELECT * FROM crime2017
UNION
SELECT * FROM crime2018
UNION
SELECT * FROM crime2019
UNION
SELECT * FROM crime2020
UNION
SELECT * FROM crime2021
UNION
SELECT * FROM crime2022

#Inspect if the categorical variables are consistent
SELECT DISTINCT(TYPE)
FROM crime_all

SELECT DISTINCT(NEIGHBOURHOOD)
FROM crime_all

#Create a datecolumn 
CREATE TABLE crime_all_2 AS
SELECT CAST(CONCAT(YEAR,'-',MONTH,'-',DAY)AS DATE)AS DATE, crime_all.* 
FROM crime_all 
ORDER BY DATE

#Join with Neibourhood Depression Data and define one to many relationship
#https://vancouverdivision.com/communities/
SELECT * FROM crimedata.depression 

CREATE TABLE crime_all_3 AS
WITH tempt AS 
(SELECT *,
	 CASE WHEN NEIGHBOURHOOD = 'West End' THEN 'City Centre'
     WHEN NEIGHBOURHOOD = 'Central Business District' THEN 'City Centre'
     WHEN NEIGHBOURHOOD = 'Fairview' THEN 'City Centre'
     WHEN NEIGHBOURHOOD = 'Stanley Park' THEN 'City Centre'
     WHEN NEIGHBOURHOOD = 'Strathcona' THEN 'Downtown Eastside'
     WHEN NEIGHBOURHOOD = 'Grandview-Woodland' THEN 'Downtown Eastside'
     WHEN NEIGHBOURHOOD = 'Hastings-Sunrise' THEN 'Downtown Eastside'
     WHEN NEIGHBOURHOOD = 'Mount Pleasant' THEN 'Midtown'
     WHEN NEIGHBOURHOOD = 'Kensington-Cedar Cottage' THEN 'Midtown'
     WHEN NEIGHBOURHOOD = 'Riley Park' THEN 'Midtown'
     WHEN NEIGHBOURHOOD = 'South Cambie' THEN 'Midtown'
     WHEN NEIGHBOURHOOD = 'Renfrew-Collingwood' THEN 'North East'
     WHEN NEIGHBOURHOOD = 'Sunset' THEN 'South'
     WHEN NEIGHBOURHOOD = 'Marpole' THEN 'South'
     WHEN NEIGHBOURHOOD = 'Victoria-Fraserview' THEN 'South'
     WHEN NEIGHBOURHOOD = 'Killarney' THEN 'South'
     WHEN NEIGHBOURHOOD = 'Oakridge' THEN 'South'
     WHEN NEIGHBOURHOOD = 'Shaughnessy' THEN 'Westside' 
     WHEN NEIGHBOURHOOD = 'Kitsilano' THEN 'Westside'
     WHEN NEIGHBOURHOOD = 'West Point Grey' THEN 'Westside'
     WHEN NEIGHBOURHOOD = 'Kerrisdale' THEN 'Westside'
     WHEN NEIGHBOURHOOD = 'Arbutus Ridge' THEN 'Westside'
     WHEN NEIGHBOURHOOD = 'Dunbar-Southlands' THEN 'Westside'
     WHEN NEIGHBOURHOOD = 'Musqueam' THEN 'Westside'
	 END AS JURISDICTION
	 FROM crime_all_2)
SELECT tempt.*, Average_Depression_Index AS AVG_DEPRESSION_INDEX
FROM tempt
INNER JOIN depression
ON tempt.JURISDICTION = depression.JURISDICTION

# Aggregate homeless shelter data set and Join with crime data
WITH temp AS 
	(SELECT GeoArea, COUNT(FACILITY) AS SHELTER
	 FROM shelter
	 GROUP BY GeoArea)
SELECT crime_all_3.*, temp.SHELTER
FROM crime_all_3
LEFT JOIN temp
ON crime_all_3.NEIGHBOURHOOD = temp.GeoArea

## The code above will return nulls for zero shelter, code below will return zero for nulls 
## Learn to use CASE WHEN when some data point is null after joining 

CREATE TABLE crime_all_4 AS
WITH temp AS 
	(SELECT GeoArea, COUNT(FACILITY) AS SHELTER
	 FROM shelter
	 GROUP BY GeoArea)
SELECT crime_all_3.*, CASE WHEN temp.SHELTER IS NULL THEN 0 ELSE temp.SHELTER END AS SHELTER 
FROM crime_all_3
LEFT JOIN temp
ON crime_all_3.NEIGHBOURHOOD = temp.GeoArea 

# Join with monthly unemployment rate, need to extract YEAR and MONTH and exclude DAYs for successful joins 
# Learn to use two CTEs to transform data then apply Join
CREATE TABLE crime_all_5 AS
WITH temp AS
	(SELECT DATE_FORMAT(DATE, '%Y-%m') AS YEARMONTH, crime_all_4.*
	 FROM crime_all_4),
	 temp2 AS 
	(SELECT DATE_FORMAT(DATE, '%Y-%m') AS YEARMONTH, unemployment.*
     FROM unemployment)
SELECT temp.*, temp2.unemployment_rate AS UNEMPLOYMENT_RATE
FROM temp
INNER JOIN temp2 
ON temp.YEARMONTH = temp2.YEARMONTH 

# Join with daily weather information 
CREATE TABLE crime_all_6 AS
SELECT crime_all_5.*, weather.sunrise AS SUNRISE, weather.sunset AS SUNSET, weather.avg_hourly_temperature AS TEMP, weather.avg_hourly_wind_speed AS WIND, weather.avg_hourly_visibility AS VISIBILITY, weather.avg_hourly_health_index AS AIR_QUALITY, weather.precipitation AS PRECIPITATION, weather.rain AS RAIN, weather.snow AS SNOW, weather.daylight AS DAYLIGHT_HOURS, weather.avg_hourly_cloud_cover_8 AS CLOUD_COVER
FROM crime_all_5
LEFT JOIN weather
ON crime_all_5.DATE = weather.date

# Join with household income information 
CREATE TABLE crime_all_7 AS
SELECT crime_all_6.*, income.Average_Household_Income AS AVG_HOUSEHOLD_INCOME, income.Median_Household_Income AS MEDIAN_HOUSEHOLD_INCOME
FROM crime_all_6
LEFT JOIN income
ON crime_all_6.NEIGHBOURHOOD = income.Neighbourghood

# Removed nulls and interpolated in python
# crime_all had 250232 rows, crime_all_6 has 250209, retained 99.9% rows after joins




