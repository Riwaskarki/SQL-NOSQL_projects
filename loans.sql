DROP TABLE if EXISTS main_data
CREATE TABLE main_data (
    customer_id FLOAT,
    customer_age INT,
    home_ownership VARCHAR(50),
    employment_duration FLOAT,
    loan_intent VARCHAR(50),
    loan_grade CHAR(1),
    loan_int_rate FLOAT,
    term_years INT,
    historical_default VARCHAR(50),
    cred_hist_length INT,
    Current_loan_status VARCHAR(50)
);
SELECT *
FROM main_data
LIMIT 5

CREATE TABLE financial_data (
    customer_id FLOAT ,
    customer_income FLOAT,
    loan_amnt FLOAT
);

CREATE TABLE living_status (
    living_id VARCHAR PRIMARY KEY,
    living_status VARCHAR(50)
);

SELECT *
FROM living_status
LIMIT 5

SELECT
    md.customer_id,
    md.customer_age,
    md.home_ownership,
    fd.customer_income,
    fd.loan_amnt,
    md.loan_int_rate,
    md.term_years,
    md.current_loan_status
FROM 
    main_data md
INNER JOIN 
    financial_data fd ON md.customer_id = fd.customer_id
WHERE 
    md.customer_age >= 25;
-- Average loan according to the house owner ship.
SELECT 
    md.home_ownership,
    COUNT(md.customer_id) AS num_customers,
    AVG(fd.loan_amnt) AS avg_loan_amount
FROM 
    main_data md
LEFT JOIN 
    financial_data fd ON md.customer_id = fd.customer_id
GROUP BY 
    md.home_ownership
ORDER BY 
	num_customers DESC;

-- Case satement creating bins according to the customer income.
SELECT 
    CASE 
        WHEN fd.customer_income < 20000 THEN 'Low Income'
        WHEN fd.customer_income BETWEEN 20000 AND 50000 THEN 'Middle Income'
        ELSE 'High Income'
    END AS income_group,
    md.customer_id,
    md.customer_age,
    md.home_ownership,
    fd.customer_income,
    fd.loan_amnt,
    md.loan_int_rate,
    md.term_years,
    md.current_loan_status
FROM 
    main_data md
INNER JOIN 
    financial_data fd ON md.customer_id = fd.customer_id;

-- Counting how many people are in those income group.
SELECT 
    CASE 
        WHEN customer_income < 20000 THEN 'Low Income'
        WHEN customer_income BETWEEN 20000 AND 50000 THEN 'Middle Income'
        ELSE 'High Income'
    END AS income_group,
    COUNT(customer_id) AS num_people
FROM 
    financial_data
GROUP BY 
    income_group;

--Finding the default rate for different intent
SELECT 
    md.loan_intent,
    COUNT(md.customer_id) AS total_customers,
    SUM(CASE WHEN md.current_loan_status = 'DEFAULT' THEN 1 ELSE 0 END) AS total_defaults,
    ROUND((SUM(CASE WHEN md.current_loan_status = 'DEFAULT' THEN 1 ELSE 0 END) * 100.0) / COUNT(md.customer_id), 2) AS default_rate
FROM 
    main_data md
GROUP BY 
    md.loan_intent;

--- Average interest rate for different term years.
SELECT 
    CASE 
        WHEN md.employment_duration <= 1 THEN 'Less than 1 year'
        WHEN md.employment_duration BETWEEN 1 AND 5 THEN '1-5 years'
        WHEN md.employment_duration BETWEEN 5 AND 10 THEN '5-10 years'
        ELSE 'More than 10 years'
    END AS employment_group,
    AVG(md.loan_int_rate) AS avg_loan_interest_rate
FROM 
    main_data md
GROUP BY 
    employment_group
ORDER BY
	avg_loan_interest_rate;

---
SELECT 
    md.customer_id,
    md.customer_age,
    ls.living_status,
    fd.loan_amnt,
    md.current_loan_status
FROM 
    main_data md
INNER JOIN 
    financial_data fd ON md.customer_id = fd.customer_id
INNER JOIN 
    living_status ls ON md.home_ownership = ls.living_status
WHERE 
    md.current_loan_status = 'DEFAULT'
ORDER BY
	md.customer_age ASC
LIMIT 5;
/* It is weird why someone aged 8 has a loan of 16500 must be some mistake.
lets dig deep */

SELECT 
    md.*,
    fd.customer_income,
    fd.loan_amnt,
    ls.living_status
FROM 
    main_data md
INNER JOIN 
    financial_data fd ON md.customer_id = fd.customer_id
LEFT JOIN 
    living_status ls ON md.home_ownership = ls.living_status
WHERE 
    md.customer_age = 8;

/* This kid of age 8 has income of 47000 euros, need to get details
and report this to company for furthur investigation */

--Risk assessmnet

SELECT 
    md.customer_id,
    md.customer_age,
    fd.customer_income,
    fd.loan_amnt,
    md.cred_hist_length,
    md.employment_duration,
    md.current_loan_status,
    CASE
        WHEN fd.loan_amnt > fd.customer_income * 0.5 THEN 'High Loan-to-Income Ratio'
        WHEN md.cred_hist_length < 3 THEN 'Short Credit History'
        WHEN md.employment_duration < 2 THEN 'Low Employment Duration'
        WHEN md.current_loan_status = 'DEFAULT' THEN 'Already in Default'
        ELSE 'Low Risk'
    END AS risk_factor,
    CASE
        WHEN fd.loan_amnt > fd.customer_income * 0.5 OR md.cred_hist_length < 3 OR md.employment_duration < 2 OR md.current_loan_status = 'DEFAULT'
        THEN 'High Risk'
        ELSE 'Low Risk'
    END AS overall_risk
FROM 
    main_data md
INNER JOIN 
    financial_data fd ON md.customer_id = fd.customer_id;


