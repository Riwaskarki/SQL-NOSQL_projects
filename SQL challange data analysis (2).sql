--Data analysis
CREATE TABLE "departments" (
    "dept_no" VARCHAR NOT NULL,
    "dept_name" VARCHAR,
    CONSTRAINT "pk_departments" PRIMARY KEY (
        "dept_no"
     )
);

CREATE TABLE "dept_emp" (
    "emp_no" VARCHAR   NOT NULL,
    "dept_no" VARCHAR NOT NULL
);

CREATE TABLE "dept_manager" (
    "dept_no" VARCHAR NOT NULL,
    "emp_no" VARCHAR   NOT NULL
);

DROP TABLE dept_manager;

CREATE TABLE "employees" (
    "emp_no" VARCHAR   NOT NULL,
    "emp_title_id" VARCHAR(255)   NOT NULL,
    "birth_date" VARCHAR(255)   NOT NULL,
    "first_name" VARCHAR(255)   NOT NULL,
    "last_name" VARCHAR(255)   NOT NULL,
    "sex" VARCHAR   NOT NULL,
    "hire_date" VARCHAR   NOT NULL,
    CONSTRAINT "pk_employees" PRIMARY KEY (
        "emp_no"
     )
);

CREATE TABLE "salaries" (
    "emp_no" VARCHAR   NOT NULL,
    "salary" VARCHAR   NOT NULL
);
DROP TABLE salaries;

CREATE TABLE "titles" (
    "title_id" VARCHAR(50)   NOT NULL,
    "title" VARCHAR(50)   NOT NULL,
    CONSTRAINT "pk_titles" PRIMARY KEY (
        "title_id"
     )
);

SELECT *
FROM titles;
--Joining the salaries and employees table to get necessary data.
SELECT 
    employees.emp_no,
    employees.last_name,
    employees.first_name,
    employees.sex,
    salaries.salary
FROM 
    employees
JOIN 
    salaries
ON 
    employees.emp_no = salaries.emp_no;

-- employees hired in 1986
SELECT 
    first_name, 
    last_name, 
    hire_date
FROM 
    employees
WHERE 
    hire_date LIKE '%1986';

--Finding the manager's details
SELECT 
    d.dept_no,
    d.dept_name,
    dm.emp_no,
    e.last_name,
    e.first_name
FROM 
    dept_manager AS dm
JOIN 
    departments AS d ON dm.dept_no = d.dept_no
JOIN 
    employees AS e ON dm.emp_no = e.emp_no;

-- department number of each employee with employee number and other details
SELECT 
    de.dept_no,
    e.emp_no,
    e.last_name,
    e.first_name,
    d.dept_name
FROM 
    dept_emp AS de
JOIN 
    departments AS d ON de.dept_no = d.dept_no
JOIN 
    employees AS e ON de.emp_no = e.emp_no;

-- Details of the employee where the first name is Hercules and last name with B

SELECT 
    first_name,
    last_name,
    sex
FROM 
    employees
WHERE 
    first_name = 'Hercules'
    AND last_name LIKE 'B%';

-- Employee in the sales department with their details
SELECT 
    e.emp_no,
    e.last_name,
    e.first_name
FROM 
    employees AS e
JOIN 
    dept_emp AS de ON e.emp_no = de.emp_no
JOIN 
    departments AS d ON de.dept_no = d.dept_no
WHERE 
    d.dept_name = 'Sales';

--employee in the Sales and Development departments, including their employee number, 
--last name, first name, and department name
SELECT 
    e.emp_no,
    e.last_name,
    e.first_name,
    d.dept_name
FROM 
    employees e
JOIN 
    dept_emp de ON e.emp_no = de.emp_no
JOIN 
    departments d ON de.dept_no = d.dept_no
WHERE 
    d.dept_name IN ('Sales', 'Development');

--Frequency count of the last name
SELECT 
    last_name,
    COUNT(*) AS count
FROM 
    employees
GROUP BY 
    last_name
ORDER BY 
    count DESC;



