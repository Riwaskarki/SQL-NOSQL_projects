CREATE TABLE contacts (
    contact_id INT PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    email VARCHAR(100)
);

CREATE TABLE category (
    category_id VARCHAR(10) PRIMARY KEY,
    category VARCHAR(50)
);

CREATE TABLE subcategory (
    subcategory_id VARCHAR(10) PRIMARY KEY,
    subcategory VARCHAR(50)
);

DROP TABLE if EXISTS campaign;

CREATE TABLE campaign (
    cf_id INT PRIMARY KEY,
    contact_id INT REFERENCES contacts(contact_id),
    company_name VARCHAR(100),
    description TEXT,
    goal NUMERIC,
    pledged NUMERIC,
    outcome VARCHAR(20),
    backers_count INT,
    country VARCHAR(10),
    currency VARCHAR(10),
    launched_date DATE,
    end_date DATE,
    category_id VARCHAR(10) REFERENCES category(category_id),
    subcategory_id VARCHAR(10) REFERENCES subcategory(subcategory_id)
);

--Checking the first few rows if the data is sucessfully loaded.
Select *
FROM campaign
LIMIT 5

Select *
FROM contacts
LIMIT 5;

Select *
FROM category
LIMIT 5;

Select *
FROM subcategory
LIMIT 5;

SELECT * 
FROM
    campaign
WHERE
    outcome = 'failed'
GROUP BY
	cf_id
HAVING
    goal <= 10000

-- Creating a new table with the cleaned data
CREATE TABLE cleaned_campaign AS
WITH goal_stats AS (
    SELECT
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY goal) AS q1,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY goal) AS q3
    FROM campaign
),
pledged_stats AS (
    SELECT
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY pledged) AS q1,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY pledged) AS q3
    FROM campaign
),
backers_count_stats AS (
    SELECT
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY backers_count) AS q1,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY backers_count) AS q3
    FROM campaign
),
goal_outliers AS (
    SELECT cf_id
    FROM campaign, goal_stats
    WHERE goal < (q1 - 1.5 * (q3 - q1)) OR goal > (q3 + 1.5 * (q3 - q1))
),
pledged_outliers AS (
    SELECT cf_id
    FROM campaign, pledged_stats
    WHERE pledged < (q1 - 1.5 * (q3 - q1)) OR pledged > (q3 + 1.5 * (q3 - q1))
),
backers_count_outliers AS (
    SELECT cf_id
    FROM campaign, backers_count_stats
    WHERE backers_count < (q1 - 1.5 * (q3 - q1)) OR backers_count > (q3 + 1.5 * (q3 - q1))
)
SELECT *
FROM campaign
WHERE cf_id NOT IN (
    SELECT cf_id FROM goal_outliers
    UNION
    SELECT cf_id FROM pledged_outliers
    UNION
    SELECT cf_id FROM backers_count_outliers
);

SELECT * 
FROM
	cleaned_campaign;
--Looking for any null values
--As we have cleaned the data using python there are no nulls.
SELECT *
FROM cleaned_campaign
WHERE company_name IS NULL;

--- Replacing the null with unknown on outcome.
UPDATE cleaned_campaign
SET outcome = 'unknown'
WHERE outcome IS NULL;

SELECT *
FROM cleaned_campaign
WHERE outcome = 'unknown';

---- Converting numeric data type to INT.
ALTER TABLE cleaned_campaign
ALTER COLUMN goal TYPE INTEGER USING goal::integer;

---Creatin a CTE with high backers.
CREATE TABLE high_backers AS
WITH high_backers AS (
    SELECT *
    FROM campaign
    WHERE backers_count > 100
)
SELECT *
FROM high_backers;

DROP TABLE high_backers;

---Creating a temp table for failed campaigns.
CREATE TEMP TABLE temp_failed_campaigns AS
SELECT *
FROM cleaned_campaign
WHERE outcome = 'failed';

---- looking for the campaign who made less than the goal.
SELECT *
FROM temp_failed_campaigns
WHERE
	pledged <= goal*0.5 AND
	pledged <> 0
ORDER BY 
	pledged
LIMIT 10

--- Looking for a campaign that made nothing
SELECT *
FROM temp_failed_campaigns
WHERE
	pledged = 0
ORDER BY
	cf_id ASC
LIMIT 10;

---counting the campaign done in each country
SELECT country, COUNT(*) AS campaign_count
FROM 
	cleaned_campaign
GROUP BY
	country
ORDER BY 
	campaign_count ASC;
----average of the pledged amount for each category_ID
SELECT category_id, AVG(pledged) AS avg_pledged
FROM 
	cleaned_campaign
GROUP BY 
	category_id;

---Looking at the goal and the amount pledged by the campaign in each cat.
WITH great_campcat AS(
SELECT 
	category_id,
	SUM(goal) AS total_goal,
	SUM(pledged) AS total_pledged
FROM 
	cleaned_campaign
GROUP BY 
	category_id
ORDER BY
	category_id ASC)

---Looking for the category that made more than 120% of the goal
SELECT *
FROM
	great_campcat
WHERE 
	total_pledged > total_goal * 1.2;

----Classifying the campaign according to the goal.
SELECT *, 
       CASE 
           WHEN goal < 1000 THEN 'Small'
           WHEN goal BETWEEN 1000 AND 10000 THEN 'Medium'
           ELSE 'Large'
       END AS goal_classification
FROM cleaned_campaign;

--Looking for the campaign started after 2020
SELECT *
FROM 
	cleaned_campaign
WHERE 
	launched_date > '2021-01-01';

---Joining the 2 different tables.
SELECT c.contact_id, c.first_name, c.last_name, cmp.company_name
FROM contacts c
RIGHT JOIN cleaned_campaign cmp ON c.contact_id = cmp.contact_id
	WHERE 
		cmp.company_name = 'Harris Group' or 
		c.contact_id in (3535, 2522);

----Inserting value in to the contacts.
SELECT * 
FROM 
	contacts;
--------
INSERT INTO contacts (contact_id, first_name, last_name,email)
	VALUES(4940, 'Riwas', 'Karki', 'fsgsg@');
------
SELECT *
FROM
	contacts
WHERE
	first_name LIKE 'Riw%';

---- Finding the name of all the categories and sub categories.
SELECT category AS name FROM category
UNION
SELECT subcategory AS name FROM subcategory;

-----Calculating the average amount pledges by each category
SELECT sub.subcategory, 
       AVG(cd.pledged) AS average_pledge
FROM 
	cleaned_campaign AS cd
JOIN 
	subcategory AS sub ON cd.subcategory_id = sub.subcategory_id
GROUP BY 
	sub.subcategory
ORDER BY 
	average_pledge DESC;

----Counting sucessful campaign for each person and average amount pledged.
SELECT con.first_name,
		COUNT(*) AS successful_campaigns, 
        AVG(cd.pledged) AS average_contribution
FROM 
	cleaned_campaign AS cd
JOIN 
	contacts AS con ON cd.contact_id = con.contact_id
WHERE 
	cd.outcome = 'successful'
GROUP BY 
	con.first_name
ORDER BY 
	successful_campaigns DESC;

---- correlation between backers count and pledged amount for each cat.
SELECT cd.category_id, 
       CORR(cd.backers_count, cd.pledged) AS correlation
FROM 
	cleaned_campaign AS cd
GROUP BY 
	cd.category_id
ORDER BY 
	correlation DESC;

----Looking if the time of the year has anything to do with the success rate.
SELECT 
    TO_CHAR(launched_date, 'MM') AS launch_month,
    COUNT(*) AS total_campaigns,
    SUM(CASE WHEN outcome = 'successful' THEN 1 ELSE 0 END) AS successful_campaigns,
    ROUND(SUM(CASE WHEN outcome = 'successful' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS success_rate
FROM 
    cleaned_campaign
GROUP BY 
    launch_month
ORDER BY 
    launch_month;

----Why campaigns are failing
----Campaigns with high goals are more likely to fail.
SELECT 
    CASE 
        WHEN goal <= 1000 THEN 'Low Goal'
        WHEN goal > 1000 AND goal <= 10000 THEN 'Medium Goal'
        ELSE 'High Goal'
    END AS goal_range,
    COUNT(*) AS total_campaigns,
    SUM(CASE WHEN outcome = 'failed' THEN 1 ELSE 0 END) AS failed_campaigns,
    ROUND(SUM(CASE WHEN outcome = 'failed' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS failure_rate
FROM 
    cleaned_campaign
GROUP BY 
    goal_range
ORDER BY 
    failure_rate DESC;

---Failure rate by currency.
SELECT 
    currency, 
    COUNT(*) AS total_campaigns,
    SUM(CASE WHEN outcome = 'failed' THEN 1 ELSE 0 END) AS failed_campaigns,
    ROUND(SUM(CASE WHEN outcome = 'failed' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS failure_rate
FROM 
    cleaned_campaign
GROUP BY 
    currency
ORDER BY 
    failure_rate DESC;


----Creating a temp table for the goal range
CREATE TEMP TABLE goal_range_temp AS
SELECT 
    cf_id,
    CASE 
        WHEN goal <= 1000 THEN 'Low Goal'
        WHEN goal > 1000 AND goal <= 10000 THEN 'Medium Goal'
        ELSE 'High Goal'
    END AS goal_range
FROM 
    cleaned_campaign;

-- Use the temporary table to analyze failure rates
WITH goal_analysis AS (
    SELECT 
        gr.goal_range,
        COUNT(cd.cf_id) AS total_campaigns,
        SUM(CASE WHEN cd.outcome = 'failed' THEN 1 ELSE 0 END) AS failed_campaigns,
        ROUND(SUM(CASE WHEN cd.outcome = 'failed' THEN 1 ELSE 0 END) * 100.0 / COUNT(cd.cf_id), 2) AS failure_rate
    FROM 
        cleaned_campaign cd
    JOIN 
        goal_range_temp gr ON cd.cf_id = gr.cf_id
    GROUP BY 
        gr.goal_range
)
SELECT * FROM goal_analysis
ORDER BY failure_rate DESC;
